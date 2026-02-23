resource "aws_sns_topic" "chips-reginit_topic" {
  name = "chips-reginit_topic"
}

resource "aws_sns_topic_subscription" "chips-reginit_Subscription" {
  topic_arn = aws_sns_topic.chips-reginit_topic.arn
  for_each  = toset(["charris1@companieshouse.gov.uk", "ccullinane@companieshouse.gov.uk", "sharrison1@companieshouse.gov.uk"])
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
