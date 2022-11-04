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
      concat(local.log_groups, var.cloudwatch_oracle_log_groups)
    ),
    formatlist("arn:aws:logs:%s:%s:log-group:%s:*",
      var.aws_region,
      data.aws_caller_identity.current.account_id,
      concat(local.log_groups, var.cloudwatch_oracle_log_groups)
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
      sid       = "AllowS3HighLevel",
      effect    = "Allow",
      resources = ["*"],
      actions = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation",
        "s3:ListBucket"
      ]
    },
    {
      sid    = "S3BackupPolicy",
      effect = "Allow",
      resources = [
        "arn:aws:s3:::${local.backup_bucket_name}",
        "arn:aws:s3:::${local.backup_bucket_name}/*"
      ],
      actions = [
        "s3:Get*",
        "s3:Put*",
        "s3:DeleteObject",
        "s3:DeleteObjects",
        "s3:ListObjects",
        "s3:UploadPart",
        "s3:ListBucket",
        "s3:CreateMultipartUpload",
        "s3:CompleteMultipartUpload",
        "s3:AbortMultipartUpload",
        "s3:ListBucketMultipartUploads",
        "s3:ListMultipartUploadParts"
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