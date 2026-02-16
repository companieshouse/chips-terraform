# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  staffware_rds_data = data.vault_generic_secret.staffware_rds.data

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  rds_access_source_sg_ids = flatten([for sg in data.aws_security_groups.db_access_group_ids : sg.ids])
  rds_access_source_groups = { for group in data.aws_security_group.db_access_groups : group.tags.Name => group.id }

  default_tags = {
    Terraform = "true"
    Region    = var.aws_region
    Account   = var.aws_account
  }
}
