# ------------------------------------------------------------------------------
# iProcess App Frontend Security Group and rules
# ------------------------------------------------------------------------------
module "iprocess_app_asg_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"

  name        = "sgr-${var.component}-asg-001"
  description = "Security group for the ${var.component} asg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_with_cidr_blocks = [
    {
      from_port   = 30001
      to_port     = 30100
      protocol    = "tcp"
      description = "Oracle DB inbound port range"
      cidr_blocks = join(",", [for subnet in data.aws_subnet.data : subnet.cidr_block])
    },
    {
      from_port   = 111
      to_port     = 111
      protocol    = "tcp"
      description = "Client inbound rpc port"
      cidr_blocks = join(",", local.admin_cidrs)
    },
    {
      from_port   = 30201
      to_port     = 30220
      protocol    = "tcp"
      description = "Client inbound connection port range"
      cidr_blocks = join(",", local.admin_cidrs)
    }
  ]

  computed_ingress_with_source_security_group_id = [
    {
      from_port                = 35311
      to_port                  = 35314
      protocol                 = "tcp"
      description              = "WebLogic inbound port range"
      source_security_group_id = data.aws_security_group.chips_weblogic.id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", "${upper(var.component)}-Support"
    )
  )
}

resource "aws_cloudwatch_log_group" "iprocess_app" {
  for_each = local.cw_logs

  name              = each.value["log_group_name"]
  retention_in_days = lookup(each.value, "log_group_retention", var.default_log_group_retention_in_days)
  kms_key_id        = lookup(each.value, "kms_key_id", local.logs_kms_key_id)

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", "${upper(var.component)}-Support"
    )
  )
}

# ASG Module
module "iprocess_app_asg" {
  source = "git@github.com:companieshouse/terraform-modules//aws/terraform-aws-autoscaling?ref=tags/1.0.36"

  name = format("%s-001", var.component)
  # Launch configuration
  lc_name       = "${var.component}-launchconfig"
  image_id      = data.aws_ami.iprocess_app.id
  instance_type = var.instance_size
  security_groups = [
    module.iprocess_app_asg_security_group.this_security_group_id,
    data.aws_security_group.nagios_shared.id
  ]
  root_block_device = [
    {
      volume_size = "100"
      volume_type = "gp2"
      encrypted   = true
      iops        = 0
    },
  ]
  # Auto scaling group
  asg_name                       = "${var.component}-asg"
  vpc_zone_identifier            = data.aws_subnet_ids.application.ids
  health_check_type              = "EC2"
  min_size                       = var.min_size
  max_size                       = var.max_size
  desired_capacity               = var.desired_capacity
  health_check_grace_period      = 300
  wait_for_capacity_timeout      = 0
  force_delete                   = true
  enable_instance_refresh        = true
  refresh_min_healthy_percentage = 50
  refresh_triggers               = ["launch_configuration"]
  key_name                       = aws_key_pair.iprocess_app_keypair.key_name
  termination_policies           = ["OldestLaunchConfiguration"]
  iam_instance_profile           = module.iprocess_app_profile.aws_iam_instance_profile.name
  user_data_base64               = data.template_cloudinit_config.userdata_config.rendered

  tags_as_map = merge(
    local.default_tags,
    map(
      "ServiceTeam", "${upper(var.component)}-Support"
    )
  )
}