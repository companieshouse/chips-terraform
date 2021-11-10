# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  admin_cidrs  = values(data.vault_generic_secret.internal_cidrs.data)
  s3_releases  = data.vault_generic_secret.s3_releases.data
  iprocess_app_ec2_data = data.vault_generic_secret.iprocess_app_ec2_data.data

  kms_keys_data          = data.vault_generic_secret.kms_keys.data
  security_kms_keys_data = data.vault_generic_secret.security_kms_keys.data
  logs_kms_key_id        = local.kms_keys_data["logs"]
  ssm_kms_key_id         = local.security_kms_keys_data["session-manager-kms-key-arn"]

  security_s3_data            = data.vault_generic_secret.security_s3_buckets.data
  session_manager_bucket_name = local.security_s3_data["session-manager-bucket-name"]

  elb_access_logs_bucket_name = local.security_s3_data["elb-access-logs-bucket-name"]
  elb_access_logs_prefix      = "elb-access-logs"

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  chs_app_subnets = values(jsondecode(data.vault_generic_secret.chs_vpc_subnets.data["applications"]))

  #For each log map passed, add an extra kv for the log group name
  cw_logs     = { for log, map in var.cw_logs : log => merge(map, { "log_group_name" = "${var.application}-fe-${log}" }) }
  log_groups  = compact([for log, map in local.cw_logs : lookup(map, "log_group_name", "")])

  iprocess_app_ansible_inputs = {
    s3_bucket_releases         = local.s3_releases["release_bucket_name"]
    s3_bucket_configs          = local.s3_releases["config_bucket_name"]
    heritage_environment       = var.environment
    version                    = var.app_release_version
    default_nfs_server_address = var.nfs_server
    mounts_parent_dir          = var.nfs_mount_destination_parent_dir
    mounts                     = var.nfs_mounts
    region                     = var.aws_region
    cw_log_files               = local.cw_logs
    cw_agent_user              = "root"
  }

  default_tags = {
    Terraform   = "true"
    Application = upper(var.application)
    Region      = var.aws_region
    Account     = var.aws_account
  }
}
