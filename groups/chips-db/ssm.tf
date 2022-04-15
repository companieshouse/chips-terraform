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


################################################################################
## DB Failover Runbook Doc
################################################################################

resource "aws_ssm_document" "failover_db" {
  name            = "ch-ssm-failover-${var.application}-db"
  document_type   = "Automation"
  document_format = "YAML"
  content = templatefile("templates/db-failover-ssm-document.yaml",
    {
      execution_role              = module.ssm_runbook_execution_role.iam_role_arn
      region_name                 = var.aws_region
      db_instance_name            = "${var.application}-db-*"
      command_document_name       = "ch-ssm-run-ansible"
      command_document_parameters = indent(8, yamlencode(merge(local.ansible_ssm_parameters, { Check = "False" })))
      dns_name                    = aws_route53_record.dns_cname.name
      route53_zone                = data.aws_route53_zone.private_zone.zone_id
    }
  )
  tags = merge(
    local.default_tags,
    map(
      "Account", var.aws_account,
      "ServiceTeam", "Platforms"
    )
  )
}