# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  admin_cidrs              = values(data.vault_generic_secret.internal_cidrs.data)
  s3_releases              = data.vault_generic_secret.s3_releases.data
  iprocess_app_ec2_data    = data.vault_generic_secret.iprocess_app_ec2_data.data
  iprocess_app_config_data = data.vault_generic_secret.iprocess_app_config_data.data

  kms_keys_data          = data.vault_generic_secret.kms_keys.data
  security_kms_keys_data = data.vault_generic_secret.security_kms_keys.data
  logs_kms_key_id        = local.kms_keys_data["logs"]
  ssm_kms_key_id         = local.security_kms_keys_data["session-manager-kms-key-arn"]

  security_s3_data            = data.vault_generic_secret.security_s3_buckets.data
  session_manager_bucket_name = local.security_s3_data["session-manager-bucket-name"]

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  #For each log map passed, add an extra kv for the log group name
  cw_logs    = { for log, map in var.cw_logs : log => merge(map, { "log_group_name" = "${var.application}-fe-${log}" }) }
  log_groups = compact([for log, map in local.cw_logs : lookup(map, "log_group_name", "")])

  iprocess_app_deployment_ansible_inputs = {
    HOSTNAME           = format("%s-001", var.component)
    DOMAIN             = local.internal_fqdn
    APP_TCP_PORT       = local.iprocess_app_config_data["app_tcp_port"]
    EAI_DB_PASS        = local.iprocess_app_config_data["eai_db_password"]
    EAI_DB_SCHEMAOWNER = local.iprocess_app_config_data["eai_db_schemaowner"]
    EAI_DB_USER        = local.iprocess_app_config_data["eai_db_user"]
    ORACLE_SID_VALUE   = local.iprocess_app_config_data["oracle_std_sid"]
    DB_ADDRESS         = local.iprocess_app_config_data["db_address"]
    DB_PORT            = local.iprocess_app_config_data["db_port"]
    SWPRO_PASSWORD     = local.iprocess_app_config_data["swpro_password"]
    region             = var.aws_region
    cw_log_files       = local.cw_logs
    cw_agent_user      = "root"
  }

  iprocess_tnsnames_inputs = {
    db_address     = local.iprocess_app_config_data["db_address"]
    db_port        = local.iprocess_app_config_data["db_port"]
    oracle_std_sid = local.iprocess_app_config_data["oracle_std_sid"]
    oracle_taf_sid = local.iprocess_app_config_data["oracle_taf_sid"]
    service_name   = local.iprocess_app_config_data["service_name"]
  }

  iprocess_staff_dat_inputs = {
    staff_dat = local.iprocess_app_config_data["staff_dat"]
  }

  default_tags = {
    Terraform   = "true"
    Application = upper(var.application)
    Region      = var.aws_region
    Account     = var.aws_account
  }
}
