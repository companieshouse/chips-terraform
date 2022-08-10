# ------------------------------------------------------------------------------
# CHIPS Security Group and rules
# ------------------------------------------------------------------------------
module "asg_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.3"

  name        = "sgr-${var.application}-asg-001"
  description = "Security group for the ${var.application} asg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_cidr_blocks = local.admin_cidrs
  ingress_rules       = ["ssh-tcp"]

  egress_rules = ["all-all"]
}

# ASG Module
module "asg" {
  source = "git@github.com:companieshouse/terraform-modules//aws/terraform-aws-autoscaling?ref=tags/1.0.36"

  count = var.asg_count

  name = format("%s%s", var.application, count.index)

  # Launch configuration
  lc_name       = format("%s%s-launchconfig", var.application, count.index)
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_size
  security_groups = [
    module.asg_security_group.security_group_id,
  ]
  root_block_device = [
    {
      volume_size = var.instance_root_volume_size
      volume_type = "gp2"
      encrypted   = true
      iops        = 0
    },
  ]
  # Auto scaling group
  asg_name                       = format("%s%s-asg", var.application, count.index)
  vpc_zone_identifier            = data.aws_subnet_ids.application.ids
  health_check_type              = "EC2"
  min_size                       = var.asg_min_size
  max_size                       = var.asg_max_size
  desired_capacity               = var.asg_desired_capacity
  health_check_grace_period      = 300
  wait_for_capacity_timeout      = 0
  force_delete                   = true
  enable_instance_refresh        = var.enable_instance_refresh
  refresh_min_healthy_percentage = 50
  refresh_triggers               = ["launch_configuration"]
  key_name                       = aws_key_pair.keypair.key_name
  termination_policies           = ["OldestLaunchConfiguration"]
  
  iam_instance_profile = module.instance_profile.aws_iam_instance_profile.name
  user_data_base64     = data.template_cloudinit_config.userdata_config.rendered

  tags_as_map = merge(
    local.default_tags,
    tomap({
      app-instance-name = format("%s%s", var.application, count.index)
      config-base-path  = format("s3://%s/%s-configs/%s", var.config_bucket_name, var.application, var.environment)
    })
  )
}

resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = local.cloudwatch_logs

  name              = each.value["log_group_name"]
  retention_in_days = lookup(each.value, "log_group_retention", var.default_log_group_retention_in_days)
  kms_key_id        = lookup(each.value, "kms_key_id", local.logs_kms_key_id)
}

#--------------------------------------------
# ASG CloudWatch Alarms
#--------------------------------------------
module "asg_alarms" {
  source = "git@github.com:companieshouse/terraform-modules//aws/asg-cloudwatch-alarms?ref=tags/1.0.116"

  count = var.asg_count

  autoscaling_group_name = module.asg[count.index].this_autoscaling_group_name
  prefix                 = "${var.aws_account}-${var.application}-${count.index}-asg-alarms"

  in_service_evaluation_periods      = "1"
  in_service_statistic_period        = "60"
  expected_instances_in_service      = 1
  in_pending_evaluation_periods      = "3"
  in_pending_statistic_period        = "120"
  in_standby_evaluation_periods      = "3"
  in_standby_statistic_period        = "120"
  in_terminating_evaluation_periods  = "3"
  in_terminating_statistic_period    = "120"
  total_instances_evaluation_periods = "1"
  total_instances_statistic_period   = "120"
  total_instances_in_service         = 1

  actions_alarm = var.enable_sns_topic ? [module.cloudwatch_sns_email[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []
  actions_ok    = var.enable_sns_topic ? [module.cloudwatch_sns_email[0].sns_topic_arn, module.cloudwatch_sns_ooh[0].sns_topic_arn] : []


  depends_on = [
    module.cloudwatch_sns_email,
    module.asg
  ]
}
