# ------------------------------------------------------------------------------
# Data
# ------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

data "vault_generic_secret" "account_ids" {
  path = "aws-accounts/account-ids"
}


data "aws_subnet_ids" "data" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-data-*"]
  }
}

data "aws_subnet" "data_subnets" {
  for_each = data.aws_subnet_ids.data.ids

  id = each.value
}

data "aws_vpc" "vpc" {
  tags = {
    Name = "vpc-${var.aws_account}"
  }
}

data "aws_ami" "oracle_12" {
  owners = [data.vault_generic_secret.account_ids.data["development"]]

  most_recent = true

  filter {
    name = "name"
    values = [
      var.ami_name,
    ]
  }

  filter {
    name = "state"
    values = [
      "available",
    ]
  }
}

data "vault_generic_secret" "internal_cidrs" {
  path = "aws-accounts/network/internal_cidr_ranges"
}

data "vault_generic_secret" "onprem_app_cidrs" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/onprem_app_cidrs"
}

data "vault_generic_secret" "deployment_cidrs" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/deployment_cidrs"
}

data "vault_generic_secret" "ec2_data" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/db/ec2"
}

data "vault_generic_secret" "kms_keys" {
  path = "aws-accounts/${var.aws_account}/kms"
}

data "vault_generic_secret" "security_kms_keys" {
  path = "aws-accounts/security/kms"
}

data "aws_kms_key" "ebs" {
  key_id = "alias/${var.account}/${var.region}/ebs"
}

data "vault_generic_secret" "shared_services_s3" {
  path = "aws-accounts/shared-services/s3"
}

data "vault_generic_secret" "security_s3_buckets" {
  path = "aws-accounts/security/s3"
}

data "vault_generic_secret" "ssm" {
  path = "aws-accounts/${var.aws_account}/ssm"
}

data "aws_route53_zone" "private_zone" {
  name         = local.internal_fqdn
  private_zone = true
}

data "template_file" "userdata" {
  template = file("${path.module}/templates/user_data.tpl")

  count = var.db_instance_count

  vars = {
    ENVIRONMENT          = title(var.environment)
    APPLICATION_NAME     = var.application
    ANSIBLE_INPUTS       = jsonencode(merge(local.ansible_inputs, { hostname = format("%s-db-%02d", var.application, count.index + 1) }))
    ISCSI_INITIATOR_NAME = local.iscsi_initiator_names[count.index]
  }
}

data "template_cloudinit_config" "userdata_config" {
  count = var.db_instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.userdata[count.index].rendered
  }
}

data "aws_security_group" "chips_sg" {
  for_each = toset(var.chips_db_sg)
  filter {
    name   = "group-name"
    values = [each.value]
  }
}

data "vault_generic_secret" "chs_subnet" {
  path = "aws-accounts/network/${var.aws_account}/chs/application-subnets"
}
