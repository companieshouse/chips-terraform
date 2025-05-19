locals {

    client_cidrs = values(data.vault_generic_secret.client_cidrs.data)

    shared_services_management_cidrs = var.test_access_enable ? flatten([
        for entry in data.aws_ec2_managed_prefix_list.shared_services_cidrs.entries : [
         entry.cidr
        ]
    ]) : []

    allowed_ranges = concat(local.client_cidrs,local.shared_services_management_cidrs)

}
