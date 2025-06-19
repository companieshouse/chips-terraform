data "vault_generic_secret" "nfs_mounts" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application_type}/app/nfs_mounts"
}

data "vault_generic_secret" "client_cidrs" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/client_cidrs"
}

data "aws_ec2_managed_prefix_list" "shared_services_cidrs" {
  name = "shared-services-management-cidrs"
}
