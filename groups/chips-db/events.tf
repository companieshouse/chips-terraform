resource "aws_cloudwatch_event_rule" "failover_alarm_rule" {
  name          = "${var.application}_db_failure"
  description   = "Rule for triggering failover actions based on ${var.application} db alarms."
  event_pattern = <<EOF
{
  "source": ["aws.cloudwatch"],
  "detail-type": ["CloudWatch Alarm State Change"],
  "detail": {
    "alarmName": [
      "${module.cloudwatch-alarms[0].ec2_composite_status.alarm_name}",
      "${module.cloudwatch-alarms[1].ec2_composite_status.alarm_name}"
    ]
  }
}
EOF
}
resource "aws_cloudwatch_event_target" "failover_event_target" {
  target_id = "${var.application}DBSSMFailoverDocument"
  arn       = aws_ssm_document.failover_db.arn
  rule      = aws_cloudwatch_event_rule.failover_alarm_rule.name
  role_arn  = aws_iam_role.ssm_runbook_execution_perms.arn
}
