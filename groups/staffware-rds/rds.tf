# ------------------------------------------------------------------------------
# RDS Security Group and rules
# ------------------------------------------------------------------------------
module "rds_security_group" {

  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${var.identifier}-${var.environment}-rds-001"
  description = "Security group for the ${var.identifier}-${var.environment} RDS database"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_rules            = ["oracle-db-tcp"]
  ingress_prefix_list_ids  = [data.aws_ec2_managed_prefix_list.administration.id]

  ingress_with_cidr_blocks = []
  ingress_with_source_security_group_id = []

  egress_rules = ["all-all"]
}

resource "aws_security_group_rule" "oem_rule" {
  description       = "Oracle Enterprise Manager"
  from_port         = 5500
  to_port           = 5500
  protocol          = "tcp"
  type              = "ingress"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.administration.id]
  security_group_id = module.rds_security_group.this_security_group_id
}

resource "aws_security_group_rule" "application_access" {
  count = length(var.rds_application_access_cidrs) > 0 ? 1 : 0

  description       = "Application access to RDS"
  from_port         = 1521
  to_port           = 1521
  protocol          = "tcp"
  type              = "ingress"
  cidr_blocks       = var.rds_application_access_cidrs
  security_group_id = module.rds_security_group.this_security_group_id
}

resource "aws_security_group_rule" "source_sg_access" {
  for_each = tomap(local.rds_access_source_groups)

  description              = "Access from ${each.key}"
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  type                     = "ingress"
  source_security_group_id = each.value
  security_group_id        = module.rds_security_group.this_security_group_id
}

# ------------------------------------------------------------------------------
# RDS Instance
# ------------------------------------------------------------------------------
module "staffware_rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.13.1"

  create_db_parameter_group = true
  create_db_subnet_group    = true

  identifier                 = "rds-${var.identifier}-${var.environment}-001"
  engine                     = "oracle-se2"
  major_engine_version       = var.major_engine_version
  engine_version             = var.engine_version
  ca_cert_identifier         = var.ca_cert_identifier
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  license_model              = var.license_model
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  storage_type               = var.storage_type
  iops                       = var.iops
  multi_az                   = var.multi_az
  storage_encrypted          = true
  kms_key_id                 = data.aws_kms_key.rds.arn

  db_name  = upper(var.name)
  username = local.staffware_rds_data["admin-username"]
  password = local.staffware_rds_data["admin-password"]
  port     = "1521"

  deletion_protection             = true
  maintenance_window              = var.rds_maintenance_window
  backup_window                   = var.rds_backup_window
  backup_retention_period         = var.backup_retention_period
  skip_final_snapshot             = false
  final_snapshot_identifier_prefix = var.identifier

  # Enhanced Monitoring
  monitoring_interval             = "30"
  monitoring_role_arn             = data.aws_iam_role.rds_enhanced_monitoring.arn
  enabled_cloudwatch_logs_exports = var.rds_log_exports

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = data.aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  # RDS Security Group
  vpc_security_group_ids = [
    module.rds_security_group.this_security_group_id,
    data.aws_security_group.rds_shared.id
  ]

  # DB subnet group
  subnet_ids = data.aws_subnets.data.ids

  # DB Parameter group
  family = "oracle-se2-${var.major_engine_version}"

  parameters = var.parameter_group_settings

  options = [
    {
      option_name                    = "OEM"
      port                           = "5500"
      vpc_security_group_memberships = [module.rds_security_group.this_security_group_id]
    },
    {
      option_name = "SQLT"
      version     = "2018-07-25.v1"
      option_settings = [
        {
          name  = "LICENSE_PACK"
          value = "N"
        },
      ]
    },
    {
      option_name = "Timezone"
      option_settings = [
        {
          name  = "TIME_ZONE"
          value = "Europe/London"
        },
      ]
    }
  ]

  timeouts = {
    "create" : "80m",
    "delete" : "80m",
    "update" : "80m"
  }

  tags = merge(
    local.default_tags,
    {
      "ServiceTeam" = "${upper(var.identifier)}-DBA-Support"
    }
  )
}

module "rds_cloudwatch_alarms" {
  source = "git@github.com:companieshouse/terraform-modules//aws/oracledb_cloudwatch_alarms?ref=tags/1.0.365"

  db_instance_id         = module.staffware_rds.db_instance_identifier
  db_instance_shortname  = upper(var.name)
  alarm_actions_enabled  = var.alarm_actions_enabled
  alarm_name_prefix      = "Oracle RDS"
  alarm_topic_name       = var.alarm_topic_name
  alarm_topic_name_ooh   = var.alarm_topic_name_ooh
}
