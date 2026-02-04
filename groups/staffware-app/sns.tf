module "cloudwatch_sns_notifications" {
  count = var.enable_sns_topic ? 1 : 0

  source  = "terraform-aws-modules/sns/aws"
  version = "3.3.0"

  name              = "${var.component}-cloudwatch-emails"
  display_name      = "${var.component}-cloudwatch-alarms-for-emails"
  kms_master_key_id = local.sns_kms_key_id

  tags = merge(
  local.default_tags,
  {
    ServiceTeam = "CSI"
  }
)
}

module "cloudwatch_sns_ooh" {
  count = var.enable_sns_topic ? 1 : 0

  source  = "terraform-aws-modules/sns/aws"
  version = "3.3.0"

  name              = "${var.component}-cloudwatch-ooh-only"
  display_name      = "${var.component}-cloudwatch-alarms-for-ooh"
  kms_master_key_id = local.sns_kms_key_id

  tags = merge(
  local.default_tags,
  {
    ServiceTeam = "CSI"
  }
)
}
