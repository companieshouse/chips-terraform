# ------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------
locals {
  internal_cidrs = values(data.vault_generic_secret.internal_cidrs.data)

  data_subnet_az_map = { for id, map in data.aws_subnet.data_subnets : map["availability_zone"] => map }

  deployment_zones = var.availability_zones == null ? [for _, map in data.aws_subnet.data_subnets : map["availability_zone"]] : var.availability_zones

  shared_services_s3_data = data.vault_generic_secret.shared_services_s3.data
  security_s3_data        = data.vault_generic_secret.security_s3_buckets.data
  ec2_data                = data.vault_generic_secret.ec2_data.data
  kms_keys_data           = data.vault_generic_secret.kms_keys.data
  security_kms_keys_data  = data.vault_generic_secret.security_kms_keys.data
  backup_kms_keys_data    = data.vault_generic_secret.backup_kms_keys.data

  ssm_data = data.vault_generic_secret.ssm.data

  logs_kms_key_id   = local.kms_keys_data["logs"]
  ssm_logs_key_id   = local.kms_keys_data["ssm"]
  sns_kms_key_id    = local.kms_keys_data["sns"]
  ssm_kms_key_id    = local.security_kms_keys_data["session-manager-kms-key-arn"]
  backup_kms_key_id = local.backup_kms_keys_data["${var.account}-chipsbackup-kms-key-arn"]

  resources_bucket_name       = local.shared_services_s3_data["resources_bucket_name"]
  session_manager_bucket_name = local.security_s3_data["session-manager-bucket-name"]
  backup_bucket_name          = "${var.aws_account}-chips-backup-chips-backup-${var.aws_region}"

  internal_fqdn = format("%s.%s.aws.internal", split("-", var.aws_account)[1], split("-", var.aws_account)[0])

  oracle_allowed_ranges = concat(local.internal_cidrs, var.vpc_sg_cidr_blocks_oracle)
  ssh_allowed_ranges    = concat(local.internal_cidrs, var.vpc_sg_cidr_blocks_ssh)

  iscsi_initiator_names = split(",", local.ec2_data["iscsi-initiator-names"])

  #For each log map passed, add an extra kv for the log group name
  cw_logs = { for log, map in var.cloudwatch_logs : log => merge(map, { "log_group_name" = "${var.application}-db-${log}" }) }

  log_groups = compact([for log, map in local.cw_logs : lookup(map, "log_group_name", "")])

  ansible_inputs = {
    environment   = var.environment
    region        = var.aws_region
    cw_log_files  = local.cw_logs
    cw_agent_user = "root"
    cw_namespace  = var.cloudwatch_namespace
    domain        = local.internal_fqdn
  }

  ansible_ssm_parameters = {
    SourceType = "GitHub"
    SourceInfo = jsonencode({
      owner      = var.ansible_ssm_git_repo_owner
      repository = var.ansible_ssm_git_repo_name
      path       = var.ansible_ssm_git_repo_path
      getOptions = var.ansible_ssm_git_repo_options
      tokenInfo  = var.ansible_ssm_git_repo_token
    })

    InstallDependencies = "False"
    InstallRequirements = "True"
    PlaybookFile        = var.ssm_playbook_file_name
    RequirementsFile    = var.ssm_requirements_file_name

    ExtraVariables     = "SSM=True" #space separated vars
    ExtraVariablesJson = jsonencode(local.ansible_inputs)
    Check              = "True"
    Verbose            = var.ansible_ssm_verbose_level
    TimeoutSeconds     = "3600"
  }

  default_tags = {
    Terraform   = "true"
    Application = upper(var.application)
    Region      = var.aws_region
    Account     = var.aws_account
  }
}
