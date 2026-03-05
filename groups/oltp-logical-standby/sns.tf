resource "aws_sns_topic" "oltp-logstb_topic" {
  name = "oltp-logstb_topic"
}

resource "aws_sns_topic_subscription" "oltp-logstb_Subscription" {
  topic_arn = aws_sns_topic.oltp-logstb_topic.arn
  for_each  = toset(["linuxsupport@companieshouse.gov.uk"])
  protocol  = "email"
  endpoint  = each.value

  depends_on = [
    aws_sns_topic.oltp-logstb_topic
  ]
}

resource "aws_sns_topic_subscription" "oltp-logstb_Subscriptionhttps" {
  topic_arn = aws_sns_topic.oltp-logstb_topic.arn
  protocol  = "https"
  endpoint  = data.vault_generic_secret.sns_url.data["url"]

  depends_on = [
    aws_sns_topic.oltp-logstb_topic
  ]
}