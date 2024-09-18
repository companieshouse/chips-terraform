data "aws_vpc" "vpc" {
  tags = {
    Name = "vpc-${var.aws_account}"
  }
}

data "aws_subnet_ids" "data" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-data-*"]
  }
}

data "aws_security_group" "rds_shared" {
  filter {
    name   = "group-name"
    values = ["sgr-rds-shared-001*"]
  }
}

data "aws_security_group" "iprocess_app" {
  filter {
    name   = "group-name"
    values = ["sgr-iprocess-app-${var.environment}-asg-001-*"]
  }
}

data "aws_route53_zone" "private_zone" {
  name         = local.internal_fqdn
  private_zone = true
}

data "aws_iam_role" "rds_enhanced_monitoring" {
  name = "irol-rds-enhanced-monitoring"
}

data "aws_kms_key" "rds" {
  key_id = "alias/kms-rds"
}

data "vault_generic_secret" "staffware_rds" {
  path = "applications/${var.aws_profile}/staffware/rds"
}

data "aws_ec2_managed_prefix_list" "administration" {
  name = "administration-cidr-ranges"
}

data "aws_security_groups" "db_access_group_ids" {
  for_each = toset(var.rds_additional_sg_patterns)
  filter {
    name   = "group-name"
    values = [each.key]
  }
}

data "aws_security_group" "db_access_groups" {
  for_each = toset(local.additional_source_sg_ids)
  id       = each.key
}
