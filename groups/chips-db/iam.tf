module "db_instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.88"

  name       = format("%s-db", var.application)
  enable_SSM = true
  kms_key_refs = [
    "alias/${var.account}/${var.region}/ebs",
    local.ssm_kms_key_id,
    local.ssm_logs_key_id,
    local.backup_kms_key_id
  ]
  s3_buckets_read = [
    local.resources_bucket_name,
  ]
  s3_buckets_write = [
    local.session_manager_bucket_name,
    local.ssm_data.ssm_logs_bucket_name
  ]
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

  custom_statements = [
    {
      sid       = "AllowDescribeTags",
      effect    = "Allow",
      resources = ["*"],
      actions = [
        "ec2:DescribeTags"
      ]
    },
    {
      sid    = "TempBackupPolicy",
      effect = "Allow",
      resources = [
        "arn:aws:s3:::${local.backup_bucket_name}",
        "arn:aws:s3:::${local.backup_bucket_name}/*"
      ],
      actions = [
        "s3:*"
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


################################################################################
## SSM Failover Execution Role
################################################################################

module "ssm-runbook-execution-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "4.17.1"

  role_name               = "ch-ssm-failover-chips-db"
  create_role             = true
  role_requires_mfa       = false
  trusted_role_services   = ["ssm.amazonaws.com"]
  custom_role_policy_arns = [aws_iam_policy.ssm-runbook-execution-perms.arn]
}

resource "aws_iam_policy" "ssm-runbook-execution-perms" {
  name   = "ch-ssm-failover-chips-db-policy"
  policy = data.aws_iam_policy_document.ssm-runbook-execution-perms.json
}

data "aws_iam_policy_document" "ssm-runbook-execution-perms" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:StartInstances",
      "ec2:DescribeInstanceStatus"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeInstanceInformation",
      "ssm:ListCommands",
      "ssm:ListCommandInvocations"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:SendCommand"
    ]
    resources = [
      "arn:aws:ssm:*:903815704705:document/ch-ssm-run-ansible",
      "arn:aws:ec2:*:903815704705:instance/*",
      "arn:aws:ssm:*:903815704705:managed-instance/*"
    ]
  }
}