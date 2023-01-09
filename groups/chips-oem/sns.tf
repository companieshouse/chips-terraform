resource "aws_sns_topic" "chips-oem_topic" {
  name = "chips-oem_topic"
}

resource "aws_sns_topic_subscription" "chips-oem_Subscription" {
  topic_arn = aws_sns_topic.chips-oem_topic.arn
  for_each  = toset(["charris1@companieshouse.gov.uk", "ccullinane@companieshouse.gov.uk","noconnor@companieshouse.gov.uk","sharrison1@companieshouse.gov.uk"])
  protocol  = "email"
  endpoint  = each.value

  depends_on = [
    aws_sns_topic.chips-oem_topic
  ]
}

resource "aws_sns_topic_subscription" "chips-oem_Subscriptionhttps" {
  topic_arn = aws_sns_topic.chips-oem_topic.arn
  protocol  = "https"
  endpoint  = "https://companieshouse.xmatters.com/api/integration/1/functions/663f6327-04ae-46ab-8e8d-f5[…]Key=850133a0-4cae-477e-9b69-c0cbc8154d8c&recipients=unix"

  depends_on = [
    aws_sns_topic.chips-oem_topic
  ]
}
