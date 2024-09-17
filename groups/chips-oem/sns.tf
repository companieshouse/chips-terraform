resource "aws_sns_topic" "chips-oem_topic" {
  name = "chips-oem_topic"
}

resource "aws_sns_topic_subscription" "chips-oem_Subscription" {
  topic_arn = aws_sns_topic.chips-oem_topic.arn
  for_each  = toset(["linuxsupport@companieshouse.gov.uk"])
  protocol  = "email"
  endpoint  = each.value

  depends_on = [
    aws_sns_topic.chips-oem_topic
  ]
}

resource "aws_sns_topic_subscription" "chips-oem_Subscriptionhttps" {
  topic_arn = aws_sns_topic.chips-oem_topic.arn
  protocol  = "https"
  endpoint  = data.vault_generic_secret.sns_url.data["url"]

  depends_on = [
    aws_sns_topic.chips-oem_topic
  ]
}
