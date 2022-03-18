module "cloudwatch_sns_notifications" {

  source  = "terraform-aws-modules/sns/aws"
  version = "3.3.0"

  name              = "${var.application}-cloudwatch-emails"
  display_name      = "${var.application}-cloudwatch-alarms-emails-only"
  kms_master_key_id = local.sns_kms_key_id

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", "DBA"
    )
  )
}

module "cloudwatch_sns_notifications_ooh" {

  source  = "terraform-aws-modules/sns/aws"
  version = "3.3.0"

  name              = "${var.application}-cloudwatch-ooh"
  display_name      = "${var.application}-cloudwatch-alarms-ooh-only"
  kms_master_key_id = local.sns_kms_key_id

  tags = merge(
    local.default_tags,
    map(
      "ServiceTeam", "DBA"
    )
  )
}