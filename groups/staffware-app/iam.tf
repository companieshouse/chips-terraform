module "iprocess_app_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.365"

  name              = "${var.component}-profile"
  enable_ssm        = true
  s3_buckets_write  = [local.session_manager_bucket_name]
  instance_asg_arns = [module.iprocess_app_asg.this_autoscaling_group_arn]
  cw_log_group_arns = length(local.log_groups) > 0 ? flatten([
    formatlist(
      "arn:aws:logs:%s:%s:log-group:%s:*:*",
      var.aws_region,
      data.aws_caller_identity.current.account_id,
      local.log_groups
    ),
    formatlist("arn:aws:logs:%s:%s:log-group:%s:*",
      var.aws_region,
      data.aws_caller_identity.current.account_id,
      local.log_groups
    ),
  ]) : null
  kms_key_refs = [
    "alias/${var.account}/${var.region}/ebs",
    local.ssm_kms_key_id,
    local.account_ssm_key_arn
  ]
  custom_statements = [
    {
      sid    = "AllowAccessToReleaseBucket",
      effect = "Allow",
      resources = [
        "arn:aws:s3:::shared-services.eu-west-2.releases.ch.gov.uk/*",
        "arn:aws:s3:::shared-services.eu-west-2.releases.ch.gov.uk",
        "arn:aws:s3:::shared-services.eu-west-2.configs.ch.gov.uk/*",
        "arn:aws:s3:::shared-services.eu-west-2.configs.ch.gov.uk"
      ],
      actions = [
        "s3:Get*",
        "s3:List*",
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
      sid       = "CloudwatchMetrics"
      effect    = "Allow"
      resources = ["*"]
      actions = [
        "cloudwatch:PutMetricData"
      ]
    },
    {
      sid       = "AllowEC2Describe"
      effect    = "Allow"
      resources = ["*"]
      actions = [
        "ec2:Describe*"
      ]
    },
    {
      sid       = "AllowReadOfParameterStore",
      effect    = "Allow",
      resources = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.application}/${var.environment}/*"],
      actions = [
        "ssm:GetParameter*"
      ]
    }
  ]
}

resource "aws_iam_role_policy_attachment" "inspector_cis_scanning_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
  role       = module.iprocess_app_profile.aws_iam_role.name
}
