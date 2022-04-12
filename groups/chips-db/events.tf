resource "aws_cloudwatch_event_rule" "failover_alarm_rule" {
  name          = "${var.application}_db_failure"
  description   = "Rule for triggering failover actions based on ${var.application} db alarms."
  event_pattern = <<EOF
{
  "source": [
    "aws.cloudwatch"
  ],
  "detail-type": [
    "CloudWatch Alarm State Change"
  ],
  "resources": [
    "${module.cloudwatch-alarms[0].ec2_composite_status.arn}",
    "${module.cloudwatch-alarms[1].ec2_composite_status.arn}"
  ],
  "detail": {
    "state":{
      "value": ["ALARM"] 
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "failover_event_target" {
  target_id = "${var.application}DBSSMFailoverDocument"
  arn       = replace(aws_ssm_document.failover_db.arn, "document/", "automation-definition/")
  rule      = aws_cloudwatch_event_rule.failover_alarm_rule.name
  role_arn  = aws_iam_role.eventbridge_ssm_execution_role.arn

  input_transformer {
    input_paths = {
      AlarmName = "$.detail.alarmName",
    }
    input_template = "{\"AlarmName\":[<AlarmName>]}"
  }
}
