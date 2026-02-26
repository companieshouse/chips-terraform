data "aws_iam_policy_document" "rds_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "s3_integration" {
  name = "ipol-rds-${var.identifier}-policy"
  role = aws_iam_role.s3_integration.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Effect": "Allow",
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

resource "aws_db_instance_role_association" "s3_integration" {
  db_instance_identifier = module.chips_rds.db_instance_identifier
  feature_name           = "S3_INTEGRATION"
  role_arn               = aws_iam_role.s3_integration.arn
}
