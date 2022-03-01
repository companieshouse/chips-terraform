################################################################################
## Scheduled task to run provided ansible playbook in check mode to provide
## regular visibility into configuration drift
################################################################################
resource "aws_ssm_association" "ansible_check" {
  association_name = "${var.application}-db-ansible-check"

  targets {
    key    = "InstanceIds"
    values = aws_instance.db_ec2.*.instance_id
  }

  name = "ch-ssm-run-ansible"
  parameters = {
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
    # SourceType = "S3"
    # SourceInfo { 
    #   path = "https://s3.amazonaws.com/DOC-EXAMPLE-BUCKET/path/"
    # }
  }
  apply_only_at_cron_interval = var.ansible_ssm_apply_only_at_cron_interval
  schedule_expression         = var.ansible_ssm_check_schedule_expression
}

################################################################################
## Scheduled task to run provided ansible playbook in apply mode
################################################################################
resource "aws_ssm_association" "ansible_apply" {
  association_name = "${var.application}-db-ansible-apply"

  targets {
    key    = "InstanceIds"
    values = aws_instance.db_ec2.*.instance_id
  }

  name = "ch-ssm-run-ansible"
  parameters = {
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
    Check              = "False"
    Verbose            = var.ansible_ssm_verbose_level
    TimeoutSeconds     = "3600"
  }
  apply_only_at_cron_interval = var.ansible_ssm_apply_only_at_cron_interval
  schedule_expression         = var.ansible_ssm_apply_schedule_expression
}


################################################################################
## Maintenance window, sets up a time period where operations can be ran
################################################################################
resource "aws_ssm_maintenance_window" "maintenance_window" {
  name     = "${var.application}-db-maintenance-window"
  schedule = var.maintenance_window_schedule_expression
  duration = var.maintenance_window_duration
  cutoff   = var.maintenance_window_cutoff
}


resource "aws_ssm_maintenance_window_target" "target" {
  window_id     = aws_ssm_maintenance_window.maintenance_window.id
  name          = "${var.application}-db-maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = aws_instance.db_ec2.*.instance_id
  }
  # owner_information - (Optional) User-provided value that will be included in any CloudWatch events raised while running tasks for these targets in this Maintenance Window.
}
