data "vault_generic_secret" "nfs_mounts" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application_type}/app/nfs_mounts"
}

data "vault_generic_secret" "shared_s3" {
  path = "aws-accounts/shared-services/s3"
}
