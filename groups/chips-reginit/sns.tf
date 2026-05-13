resource "aws_sns_topic" "chips-reginit_topic" {
  name = "chips-reginit_topic"
}

resource "aws_sns_topic_subscription" "chips-reginit_Subscription" {
  topic_arn = aws_sns_topic.chips-reginit_topic.arn
  for_each  = local.subscribed_email_addresses
  protocol  = "email"
  endpoint  = each.value

  depends_on = [
    aws_sns_topic.chips-reginit_topic
  ]
}

resource "aws_sns_topic_subscription" "chips_reginit_subscription_https" {
  topic_arn = aws_sns_topic.chips-reginit_topic.arn
  protocol  = "https"
  endpoint  = data.vault_generic_secret.sns_url.data["url"]

  depends_on = [
    aws_sns_topic.chips-reginit_topic
  ]
}
