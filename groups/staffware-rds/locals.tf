# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  staffware_rds_data = data.vault_generic_secret.staffware_rds.data

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  default_tags = {
    Terraform = "true"
    Region    = var.aws_region
    Account   = var.aws_account
  }
}
