locals {

  admin_cidrs              = values(data.vault_generic_secret.internal_cidrs.data)
  application_subnet_cidrs = [for s in data.aws_subnet.application : s.cidr_block]
  ec2_data                 = data.vault_generic_secret.ec2_data.data

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  security_kms_keys_data = data.vault_generic_secret.security_kms_keys.data
  kms_keys_data          = data.vault_generic_secret.kms_keys.data
  logs_kms_key_id        = local.kms_keys_data["logs"]
  ssm_kms_key_id         = local.security_kms_keys_data["session-manager-kms-key-arn"]
  sns_kms_key_id         = local.kms_keys_data["sns"]
  bulk_gateway_s3_data   = data.vault_generic_secret.bulk_gateway_s3.data
  bus_perf_dashboard_s3_data = data.vault_generic_secret.bus_perf_dashboard_s3.data

  security_s3_data            = data.vault_generic_secret.security_s3_buckets.data
  session_manager_bucket_name = local.security_s3_data["session-manager-bucket-name"]
  secure_bucket_name          = local.bulk_gateway_s3_data["secure_bucket_name"]
  search_bucket_name          = local.bulk_gateway_s3_data["search_bucket_name"]
  free_bucket_name            = local.bulk_gateway_s3_data["free_bucket_name"]
  archive_bucket_name         = local.bulk_gateway_s3_data["archive_bucket_name"]
  adhoc_bucket_name           = local.bulk_gateway_s3_data["adhoc_bucket_name"]
  resource_bucket_name        = local.bus_perf_dashboard_s3_data["resource_bucket_name"]
  nfs_mounts = jsondecode(data.vault_generic_secret.nfs_mounts.data["${var.application}-mounts"])

  #For each log map passed, add an extra kv for the log group name and append the NFS directory into the filepath where required
  log_directory_prefix = format("%s/%s", var.nfs_mount_destination_parent_dir, lookup(local.nfs_mounts["application_root"], "local_mount_point", ""))
  cloudwatch_logs = {
    for log, map in var.cloudwatch_logs :
    log => merge(map, {
      "log_group_name" = "${var.application}-${log}",
      "file_path"      = replace(map["file_path"], "NFSPATH", "${local.log_directory_prefix}/APPINSTANCENAME")
      }
    )
  }
  # Extract the log group names for easier iteration
  log_groups = compact([for log, map in local.cloudwatch_logs : lookup(map, "log_group_name", "")])

  default_tags = {
    Terraform       = "true"
    Application     = upper(var.application)
    ApplicationType = upper(var.application_type)
    Region          = var.aws_region
    Account         = var.aws_account
  }

  userdata_ansible_inputs = {
    mounts_parent_dir          = var.nfs_mount_destination_parent_dir
    mounts                     = local.nfs_mounts
    install_watcher_service    = false
    cw_log_files               = local.cloudwatch_logs
    cw_agent_user              = "root"
  }
}
