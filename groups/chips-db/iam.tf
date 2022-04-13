module "db_instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.88"

  name       = format("%s-db", var.application)
  enable_SSM = true
  kms_key_refs = [
    "alias/${var.account}/${var.region}/ebs",
    local.ssm_kms_key_id,
    local.ssm_logs_key_id,
    local.chipsbackup_kms_key_id
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

module "ssm_runbook_execution_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "4.17.1"

  role_name               = "ch-ssm-failover-${var.application}-db"
  create_role             = true
  role_requires_mfa       = false
  trusted_role_services   = ["ssm.amazonaws.com"]
  custom_role_policy_arns = [aws_iam_policy.ssm_runbook_execution_perms.arn]
}

resource "aws_iam_policy" "ssm_runbook_execution_perms" {
  name   = "ch-ssm-failover-${var.application}-db-policy"
  policy = data.aws_iam_policy_document.ssm_runbook_execution_perms.json
}

data "aws_iam_policy_document" "ssm_runbook_execution_perms" {
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
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/ch-ssm-run-ansible",
      "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:managed-instance/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = [
      data.aws_kms_key.ebs.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:CreateGrant"
    ]
    resources = [
      data.aws_kms_key.ebs.arn
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values = [
        "true"
      ]
    }
  }
}


################################################################################
## SSM Failover Role for Eventbridge SSM triggers
################################################################################
resource "aws_iam_role" "eventbridge_ssm_execution_role" {
  name               = "ch-ssm-failover-${var.application}-db-eventbridge-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":
  [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      }
    }
  ]
}
EOF
  tags = merge(
    local.default_tags,
    map(
      "Account", var.aws_account,
      "ServiceTeam", "Platform"
    )
  )
}

resource "aws_iam_role_policy_attachment" "eventbridge_ssm_execution_role_policy_attach" {
  role       = aws_iam_role.eventbridge_ssm_execution_role.name
  policy_arn = aws_iam_policy.eventbridge_ssm_execution_policy.arn
}

resource "aws_iam_policy" "eventbridge_ssm_execution_policy" {
  name   = "ch-ssm-failover-${var.application}-db-eventbridge-policy"
  policy = data.aws_iam_policy_document.eventbridge_ssm_execution_policy_document.json
}

data "aws_iam_policy_document" "eventbridge_ssm_execution_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:StartAutomationExecution"
    ]
    resources = [
      "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.current.account_id}:automation-definition/${aws_ssm_document.failover_db.name}:$DEFAULT"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      module.ssm_runbook_execution_role.iam_role_arn
    ]
    condition {
      test     = "StringLikeIfExists"
      variable = "iam:PassedToService"
      values = [
        "ssm.amazonaws.com"
      ]
    }
  }
}
