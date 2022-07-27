data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "s3_integration" {
  name        = "ipol-rds-${var.identifier}-policy"
  description = "Policy to enable S3 integration for rds-${var.identifier}-${var.environment}-001"

  policy = <<EOF
{
  "Version": "2021-10-17",
  "Statement": [
    {
      "Sid": "RDSS3Integration",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:Get*"
      ],
      "Resource": [
        "arn:aws:s3:::dbdev-s3-bucket",
        "arn:aws:s3:::dbdev-s3-bucket/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "s3_integration" {
  name        = "irol-rds-${var.identifier}-role"
  description = "IAM role for rds-${var.identifier}-${var.environment}-001"

  assume_role_policy = data.aws_iam_policy_document.rds_assume_role.json
}

resource "aws_iam_role_policy_attachment" "s3_integration" {
  role       = aws_iam_role.s3_integration.name
  policy_arn = aws_iam_policy.s3_integration.arn
}
