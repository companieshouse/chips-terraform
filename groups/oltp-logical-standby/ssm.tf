################################################################################
## Scheduled task to run provided ansible playbook in check mode to provide
## regular visibility into configuration drift
################################################################################
resource "aws_ssm_association" "ansible_check" {
  association_name = "${var.application}-db-ansible-check"

  targets {
    key    = "InstanceIds"
    values = aws_instance.db_ec2.*.id
  }

  name                        = "ch-ssm-run-ansible"
  parameters                  = merge(local.ansible_ssm_parameters, { Check = "True" })
  apply_only_at_cron_interval = var.ansible_ssm_check_schedule_expression != null ? var.ansible_ssm_apply_only_at_cron_interval : null
  schedule_expression         = var.ansible_ssm_check_schedule_expression

  output_location {
    s3_bucket_name = local.ssm_data.ssm_logs_bucket_name
    s3_key_prefix  = "${var.application}-db/ansible-check/"
    s3_region      = var.aws_region
  }
}

################################################################################
## Scheduled task to run provided ansible playbook in apply mode
################################################################################
resource "aws_ssm_association" "ansible_apply" {
  count = var.ansible_ssm_apply_schedule_expression != null ? 1 : 0

  association_name = "${var.application}-db-ansible-apply"

  targets {
    key    = "InstanceIds"
    values = aws_instance.db_ec2.*.id
  }

  name                        = "ch-ssm-run-ansible"
  parameters                  = merge(local.ansible_ssm_parameters, { Check = "False" })
  apply_only_at_cron_interval = var.ansible_ssm_apply_schedule_expression != null ? var.ansible_ssm_apply_only_at_cron_interval : null
  schedule_expression         = var.ansible_ssm_apply_schedule_expression

  output_location {
    s3_bucket_name = local.ssm_data.ssm_logs_bucket_name
    s3_key_prefix  = "${var.application}-db/ansible-apply/"
    s3_region      = var.aws_region
  }
}

################################################################################
## Github token secret for SSM Ansible
################################################################################
# Known bug that this changes on every plan/apply: https://github.com/hashicorp/terraform-provider-aws/issues/21095
resource "aws_ssm_parameter" "github" {
  name  = "github-token-${var.application}"
  type  = "SecureString"
  value = local.ssm_data.ssm_github_token
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
    values = aws_instance.db_ec2.*.id
  }
  # owner_information - (Optional) User-provided value that will be included in any CloudWatch events raised while running tasks for these targets in this Maintenance Window.
}
