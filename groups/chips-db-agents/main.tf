# CHIPS Security Group
module "asg_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.1"

  name        = "sgr-${var.application}-asg-001"
  description = "Security group for the ${var.application} asg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress_rules           = ["ssh-tcp"]
  ingress_prefix_list_ids = [data.aws_ec2_managed_prefix_list.administration.id]

  egress_rules = ["all-all"]
}

# ASG Module
module "asg" {
  source = "git@github.com:companieshouse/terraform-modules//aws/autoscaling-with-launch-template?ref=tags/1.0.365"

  count = var.asg_count

  name = format("%s%s", var.application, count.index)

  lt_name       = format("%s%s-launchtemplate", var.application, count.index)
  image_id      = data.aws_ami.ami.id
  instance_type = var.instance_size
  security_groups = [
    module.asg_security_group.security_group_id,
  ]

  root_block_device = [
    {
      volume_size = var.instance_root_volume_size
      encrypted   = true
    }
  ]

  block_device_mappings = [
    {
      device_name = "/dev/xvdb"
      encrypted   = true
      volume_size = var.instance_swap_volume_size
    }
  ]

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
  key_name                       = aws_key_pair.keypair.key_name
  enforce_imdsv2                 = var.enforce_imdsv2

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

# IAM module
module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.365"

  name       = format("%s-profile", var.application)
  enable_SSM = true

  s3_buckets_write = [local.session_manager_bucket_name]

  kms_key_refs = [
    "alias/${var.account}/${var.region}/ebs",
    local.ssm_kms_key_id
  ]

  cw_log_group_arns = length(local.log_groups) > 0 ? [format(
    "arn:aws:logs:%s:%s:log-group:%s-*:*",
    var.aws_region,
    data.aws_caller_identity.current.account_id,
    var.application
  )] : null

  custom_statements = [
    {
      sid    = "AllowAccessToConfigBucket",
      effect = "Allow",
      resources = [
        "arn:aws:s3:::${var.config_bucket_name}/*",
        "arn:aws:s3:::${var.config_bucket_name}"
      ],
      actions = [
        "s3:Get*",
        "s3:List*",
      ]
    },
    {
      sid       = "AllowReadOnlyAccessToECR",
      effect    = "Allow",
      resources = ["*"],
      actions = [
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    },
    {
      sid       = "AllowReadOnlyDescribeAccessToEC2",
      effect    = "Allow",
      resources = ["*"],
      actions = [
        "ec2:Describe*"
      ]
    },
    {
      sid       = "AllowWriteToRoute53",
      effect    = "Allow",
      resources = ["arn:aws:route53:::hostedzone/${data.aws_route53_zone.private_zone.zone_id}"],
      actions = [
        "route53:ChangeResourceRecordSets"
      ]
    },
    {
      sid       = "AllowReadOfParameterStore",
      effect    = "Allow",
      resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/chips/*"],
      actions = [
        "ssm:GetParameter*"
      ]
    },
    {
      sid       = "CloudwatchMetrics"
      effect    = "Allow"
      resources = ["*"]
      actions = [
        "cloudwatch:PutMetricData"
      ]
    }
  ]
}

resource "aws_iam_role_policy_attachment" "inspector_cis_scanning_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
  role       = module.instance_profile.aws_iam_role.name
}

resource "aws_cloudwatch_log_group" "log_groups" {
  for_each = local.cloudwatch_logs

  name              = each.value["log_group_name"]
  retention_in_days = lookup(each.value, "log_group_retention", var.default_log_group_retention_in_days)
  kms_key_id        = lookup(each.value, "kms_key_id", local.logs_kms_key_id)
}

resource "aws_key_pair" "keypair" {
  key_name   = var.application
  public_key = local.ec2_data["public-key"]
}
