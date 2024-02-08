
# ------------------------------------------------------------------------------
# EC2 Sec Group
# ------------------------------------------------------------------------------
module "db_ec2_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${var.application}-db-ec2-001"
  description = "Security group for the DB ec2 instance"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  egress_rules = ["all-all"]
}

# ------------------------------------------------------------------------------
# SSH Access
# ------------------------------------------------------------------------------
resource "aws_security_group_rule" "admin_ssh_access" {
  type              = "ingress"
  description       = "Administrative SSH access"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.admin.id]
  security_group_id = module.db_ec2_security_group.this_security_group_id
}

resource "aws_security_group_rule" "ssh_access" {
  for_each = toset(local.ssh_allowed_ranges)

  type              = "ingress"
  description       = "SSH access from ${each.value}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = module.db_ec2_security_group.this_security_group_id
}

# ------------------------------------------------------------------------------
# Oracle Access
# ------------------------------------------------------------------------------
resource "aws_security_group_rule" "admin_oracle_access" {
  type              = "ingress"
  description       = "Administrative Oracle access"
  from_port         = 1521
  to_port           = 1522
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.admin.id]
  security_group_id = module.db_ec2_security_group.this_security_group_id
}

resource "aws_security_group_rule" "oracle_access" {
  for_each = toset(local.oracle_allowed_ranges)

  type              = "ingress"
  description       = "Oracle access from ${each.value}"
  from_port         = 1521
  to_port           = 1522
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  security_group_id = module.db_ec2_security_group.this_security_group_id
}

resource "aws_security_group_rule" "oracle_access_sgs" {
  for_each = toset(local.source_security_group_id)

  type                     = "ingress"
  description              = "Oracle access from ${each.value}"
  from_port                = 1521
  to_port                  = 1522
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = module.db_ec2_security_group.this_security_group_id
}

# ------------------------------------------------------------------------------
# OEM agent 
# ------------------------------------------------------------------------------

resource "aws_security_group_rule" "Oracle_Management_Agent" {
  type                     = "ingress"
  description              = "Oracle Management Agent"
  from_port                = 3872
  to_port                  = 3872
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = module.db_ec2_security_group.this_security_group_id
}

resource "aws_security_group_rule" "Enterprise_Manager_Upload_Http_SSL" {
  type                     = "ingress"
  description              = "Oracle Management Agent"
  from_port                = 4903
  to_port                  = 4903
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = module.db_ec2_security_group.this_security_group_id
}

resource "aws_security_group_rule" "OEM_SSH" {
  type                     = "ingress"
  description              = "Oracle Management Agent"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = module.db_ec2_security_group.this_security_group_id
}

resource "aws_security_group_rule" "OEM_listener" {
  type                     = "ingress"
  description              = "Oracle listener"
  from_port                = 1521
  to_port                  = 1522
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.oem.id
  security_group_id        = module.db_ec2_security_group.this_security_group_id
}

# ------------------------------------------------------------------------------
# EC2
# ------------------------------------------------------------------------------
resource "aws_instance" "db_ec2" {
  count = var.db_instance_count

  ami = var.ami_id == null ? data.aws_ami.oracle_12.id : var.ami_id

  key_name      = aws_key_pair.ec2_keypair.key_name
  instance_type = var.db_instance_size
  subnet_id     = local.data_subnet_az_map[element(local.deployment_zones, count.index)]["id"]

  iam_instance_profile = module.db_instance_profile.aws_iam_instance_profile.name
  user_data_base64     = data.template_cloudinit_config.userdata_config[count.index].rendered

  vpc_security_group_ids = [
    module.db_ec2_security_group.this_security_group_id
  ]

  root_block_device {
    volume_size = "200"
    volume_type = "gp2"
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs.arn
  }

  tags = merge(
    local.default_tags,
    local.aws_backup_plan_tags,
    tomap({
      "Name"        = format("%s-db-%02d", var.application, count.index + 1),
      "Domain"      = local.internal_fqdn,
      "UNQNAME"     = var.oracle_unqname,
      "SID"         = var.oracle_sid,
      "ServiceTeam" = "Platforms/DBA",
      "Terraform"   = true
    })
  )

  lifecycle {
    ignore_changes = [
      user_data,
      user_data_base64
    ]
  }
}

resource "aws_ebs_volume" "u01" {
  count = var.db_instance_count

  availability_zone = aws_instance.db_ec2[count.index].availability_zone
  encrypted         = true
  kms_key_id        = data.aws_kms_key.ebs.arn
  size              = var.u01_volume_size
  type              = var.u01_volume_type

  tags = {
    "Name" = format("%s-db-%02d-u01", var.application, count.index + 1)
  }
}

resource "aws_volume_attachment" "u01_attachment" {
  count = var.db_instance_count

  device_name = var.u01_volume_device_name
  instance_id = aws_instance.db_ec2[count.index].id
  volume_id   = aws_ebs_volume.u01[count.index].id
}

resource "aws_route53_record" "db_dns" {
  count = var.db_instance_count

  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-db-%02d", var.application, count.index + 1)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.db_ec2[count.index].private_ip]
}

resource "aws_route53_record" "dns_cname" {
  zone_id = data.aws_route53_zone.private_zone.zone_id
  name    = format("%s-db", var.application)
  type    = "CNAME"
  ttl     = "300"
  records = [format("%s-db-01.%s", var.application, local.internal_fqdn)]
  lifecycle {
    #Ignore changes to the record value, this may be changed outside of terraform 
    ignore_changes = [records]
  }
}

module "cloudwatch-alarms" {
  source = "git@github.com:companieshouse/terraform-modules//aws/ec2-cloudwatch-alarms?ref=tags/1.0.123"
  count  = var.db_instance_count

  name_prefix               = "chips-rep"
  namespace                 = var.cloudwatch_namespace
  instance_id               = aws_instance.db_ec2[count.index].id
  status_evaluation_periods = "3"
  status_statistics_period  = "60"

  cpuutilization_evaluation_periods = "2"
  cpuutilization_statistics_period  = "60"
  cpuutilization_threshold          = "75" # Percentage

  enable_disk_alarms = true
  disk_devices = [
    {
      instance_device_mount_path = "/"
      instance_device_location   = "nvme0n1p2"
      instance_device_fstype     = "xfs"
    }
  ]
  disk_evaluation_periods = "3"
  disk_statistics_period  = "120"
  low_disk_threshold      = "75" # Percentage

  enable_memory_alarms       = true
  memory_evaluation_periods  = "2"
  memory_statistics_period   = "120"
  available_memory_threshold = "10" # Percentage
  used_memory_threshold      = "80" # Percentage
  used_swap_memory_threshold = "50" # Percentage

  alarm_actions = [
    data.vault_generic_secret.chips_sns.data["chips-sns-topic-emails"]
  ]

  ok_actions = [
    data.vault_generic_secret.chips_sns.data["chips-sns-topic-emails"]
  ]

  depends_on = [
    aws_instance.db_ec2
  ]

  tags = merge(
    local.default_tags,
    tomap({
      "ServiceTeam" = "Platforms/DBA",
      "Terraform"   = true
    })
  )
}

resource "aws_cloudwatch_log_group" "cloudwatch_log_groups" {
  for_each = local.cw_logs

  name              = each.value["log_group_name"]
  retention_in_days = lookup(each.value, "log_group_retention", var.default_log_group_retention_in_days)
  kms_key_id        = lookup(each.value, "kms_key_id", local.logs_kms_key_id)

  tags = merge(
    local.default_tags,
    tomap({
      "ServiceTeam" = "Platforms/DBA",
      "Terraform"   = true
    })
  )
}

resource "aws_cloudwatch_log_group" "cloudwatch_oracle_log_groups" {
  count = length(var.cloudwatch_oracle_log_groups) > 0 ? length(var.cloudwatch_oracle_log_groups) : 0

  name              = var.cloudwatch_oracle_log_groups[count.index]
  retention_in_days = var.default_log_group_retention_in_days
  kms_key_id        = local.logs_kms_key_id

  tags = merge(
    local.default_tags,
    tomap({
      "ServiceTeam" = "Platforms/DBA",
      "Terraform"   = true
    })
  )
}

module "oracledb_cloudwatch_alarms" {
  source = "git@github.com:companieshouse/terraform-modules//aws/oracledb_cloudwatch_alarms?ref=tags/1.0.177"

  db_instance_id          = "chips-rep-db"
  db_instance_shortname   = var.db_instance_shortname
  alarm_actions_enabled   = var.alarm_actions_enabled
  alert_log_group_name    = "chips-rep-db/oracle/alert"
  alarm_name_prefix       = "Oracle EC2"
  alarm_topic_name        = var.alarm_topic_name
  alarm_topic_name_ooh    = var.alarm_topic_name_ooh
  orastreams_alarm_enable = true
}
