module "cloudwatch_sns_email" {
  count = var.enable_sns_topic ? 1 : 0

  source  = "terraform-aws-modules/sns/aws"
  version = "6.2.1"

  name              = "${var.application}-cloudwatch-emails"
  display_name      = "${var.application}-cloudwatch-alarms-for-emails"
  kms_master_key_id = local.sns_kms_key_id

  tags = merge(
    local.default_tags,
    tomap({
      "ServiceTeam" = "${upper(var.application)}-CSI-Support"
    })
  )
}

module "cloudwatch_sns_ooh" {
  count = var.enable_sns_topic ? 1 : 0

  source  = "terraform-aws-modules/sns/aws"
  version = "6.2.1"

  name              = "${var.application}-cloudwatch-ooh-only"
  display_name      = "${var.application}-cloudwatch-alarms-for-ooh"
  kms_master_key_id = local.sns_kms_key_id

  tags = merge(
    local.default_tags,
    tomap({
      "ServiceTeam" = "${upper(var.application)}-CSI-Support"
    })
  )
}