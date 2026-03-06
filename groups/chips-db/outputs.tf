output "db_dns_names" {
  value = aws_route53_record.db_dns.*.name
}

resource "vault_generic_secret" "chips-db-outputs" {
  path = "applications/${var.aws_profile}/${var.application}/outputs"

  data_json = jsonencode({
    chips-sns-topic-emails = module.cloudwatch_sns_notifications.topic_arn
    chips-sns-topic-ooh    = module.cloudwatch_sns_notifications_ooh.topic_arn
  })
}
