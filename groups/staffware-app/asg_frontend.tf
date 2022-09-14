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
      from_port   = 31000
      to_port     = 31049
      protocol    = "tcp"
      description = "Client inbound connection port range"
      cidr_blocks = join(",", local.admin_cidrs)
    },
    {
      from_port   = 30511
      to_port     = 30514
      protocol    = "tcp"
      description = "On-premise WebLogic inbound port range"
      cidr_blocks = join(",", local.admin_cidrs)
    }
  ]

  ingress_with_source_security_group_id = [
    {
      from_port                = 30511
      to_port                  = 30514
      protocol                 = "tcp"
      description              = "WebLogic chips-users-rest inbound port range"
      source_security_group_id = data.aws_security_group.chips_users_rest_app.id
    },
    {
      from_port                = 30511
      to_port                  = 30514
      protocol                 = "tcp"
      description              = "WebLogic chips-ef-batch inbound port range"
      source_security_group_id = data.aws_security_group.chips_ef_batch_app.id
    }
  ]

  egress_rules = ["all-all"]

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", "CSI"
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
      "ServiceTeam", "CSI"
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
      "ServiceTeam", "CSI"
    )
  )
}

#--------------------------------------------
# iProcess ASG CloudWatch Alarms
#--------------------------------------------
module "asg_alarms" {
  source = "git@github.com:companieshouse/terraform-modules//aws/asg-cloudwatch-alarms?ref=tags/1.0.116"

  autoscaling_group_name = module.iprocess_app_asg.this_autoscaling_group_name
  prefix                 = "${var.aws_account}-${var.application}-fe-asg-alarms"

  in_service_evaluation_periods      = "3"
  in_service_statistic_period        = "120"
  expected_instances_in_service      = var.desired_capacity
  in_pending_evaluation_periods      = "3"
  in_pending_statistic_period        = "120"
  in_standby_evaluation_periods      = "3"
  in_standby_statistic_period        = "120"
  in_terminating_evaluation_periods  = "3"
  in_terminating_statistic_period    = "120"
  total_instances_evaluation_periods = "3"
  total_instances_statistic_period   = "120"
  total_instances_in_service         = var.desired_capacity

  # If actions are used then all alarms will have these applied, do not add any actions which you only want to be used for specific alarms
  # The module has lifecycle hooks to ignore changes via the AWS Console so in this use case the alarm can be modified there.
  actions_alarm = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []
  actions_ok    = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []


  depends_on = [
    module.cloudwatch_sns_notifications,
    module.iprocess_app_asg
  ]
}

#--------------------------------------------
# iProcess EC2 CloudWatch Alarms at ASG level
#--------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2-cpu-utilization-high" {
  alarm_name          = "${var.aws_account}-${var.application}-EC2-CPUUtilization-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Maximum"
  threshold           = "90"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []
  ok_actions          = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = module.iprocess_app_asg.this_autoscaling_group_name
  }

  alarm_description = "${var.aws_account}: CPU use high for ${var.application} EC2 instance in ASG ${module.iprocess_app_asg.this_autoscaling_group_name}"

  lifecycle {
    ignore_changes = [
      alarm_actions,
      ok_actions,
      insufficient_data_actions
    ]
  }
  depends_on = [
    module.cloudwatch_sns_notifications,
    module.iprocess_app_asg
  ]
}

resource "aws_cloudwatch_metric_alarm" "ec2-mem-used-percent-high" {
  alarm_name          = "${var.aws_account}-${var.application}-EC2-MemUsedPercent-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "mem_used_percent"
  namespace           = "CHIPS/STFWARE"
  period              = "120"
  statistic           = "Maximum"
  threshold           = "90"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []
  ok_actions          = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = module.iprocess_app_asg.this_autoscaling_group_name
  }

  alarm_description = "${var.aws_account}: Memory use high for ${var.application} EC2 instance in ASG ${module.iprocess_app_asg.this_autoscaling_group_name}"

  lifecycle {
    ignore_changes = [
      alarm_actions,
      ok_actions,
      insufficient_data_actions
    ]
  }
  depends_on = [
    module.cloudwatch_sns_notifications,
    module.iprocess_app_asg
  ]
}

resource "aws_cloudwatch_metric_alarm" "ec2-disk-used-percent-high" {
  alarm_name          = "${var.aws_account}-${var.application}-EC2-DiskUsedPercent-High"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "disk_used_percent"
  namespace           = "CHIPS/STFWARE"
  period              = "120"
  statistic           = "Maximum"
  threshold           = "90"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []
  ok_actions          = var.enable_sns_topic ? [module.cloudwatch_sns_notifications[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []

  dimensions = {
    AutoScalingGroupName = module.iprocess_app_asg.this_autoscaling_group_name
  }

  alarm_description = "${var.aws_account}: Disk use high for ${var.application} EC2 instance in ASG ${module.iprocess_app_asg.this_autoscaling_group_name}"

  lifecycle {
    ignore_changes = [
      alarm_actions,
      ok_actions,
      insufficient_data_actions
    ]
  }
  depends_on = [
    module.cloudwatch_sns_notifications,
    module.iprocess_app_asg
  ]
}
