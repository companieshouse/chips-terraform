# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  internal_cidrs = values(data.vault_generic_secret.internal_cidrs.data)

  shared_services_s3_data = data.vault_generic_secret.shared_services_s3.data
  security_s3_data        = data.vault_generic_secret.security_s3_buckets.data
  ec2_data                = data.vault_generic_secret.ec2_data.data
  kms_keys_data           = data.vault_generic_secret.kms_keys.data
  security_kms_keys_data  = data.vault_generic_secret.security_kms_keys.data

  logs_kms_key_id = local.kms_keys_data["logs"]
  ssm_kms_key_id  = local.security_kms_keys_data["session-manager-kms-key-arn"]

  resources_bucket_name       = local.shared_services_s3_data["resources_bucket_name"]
  session_manager_bucket_name = local.security_s3_data["session-manager-bucket-name"]

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  oracle_allowed_ranges = concat(local.internal_cidrs, var.vpc_sg_cidr_blocks_oracle)

  #For each log map passed, add an extra kv for the log group name
  cw_logs = { for log, map in var.cloudwatch_logs : log => merge(map, { "log_group_name" = "${var.application}-${log}" }) }

  log_groups = compact([for log, map in local.cw_logs : lookup(map, "log_group_name", "")])

  ansible_inputs = {
    environment                = var.environment
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
