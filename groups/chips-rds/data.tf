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

data "vault_generic_secret" "chips_rds" {
  path = "applications/${var.aws_profile}/chips/rds"
}

data "aws_ec2_managed_prefix_list" "admin" {
  name = "administration-cidr-ranges"
}

data "aws_ec2_managed_prefix_list" "concourse" {
  name = "shared-services-management-cidrs"
}

data "aws_security_groups" "oracle_ingress" {
  filter {
    name   = "group-name"
    values = var.oracle_ingress_sg_patterns
  }
}

data "vault_generic_secret" "staging_dba_dev" {
  path = "applications/${var.aws_profile}/chips/dba_dev"
  
}
