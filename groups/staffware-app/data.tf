data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  tags = {
    Name = "vpc-${var.aws_account}"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-public-*"]
  }
}

data "aws_subnet_ids" "data" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-data-*"]
  }
}

data "aws_subnet_ids" "application" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-application-*"]
  }
}

data "aws_security_group" "nagios_shared" {
  filter {
    name   = "group-name"
    values = ["sgr-nagios-inbound-shared-*"]
  }
}

# data "aws_security_group" "tuxedo" {
#   filter {
#     name   = "tag:Name"
#     values = ["ewf-frontend-tuxedo-${var.environment}"]
#   }
# }

# This is a non-production lookup, Forgerock ID Gateway access in Dev and Staging
# When Forgerock goes into Live then the condition can be removed.
data "aws_security_group" "identity_gateway" {
  count = var.environment == "live" ? 0 : 1
  name  = "identity-gateway-instance"
}

data "aws_route53_zone" "private_zone" {
  name         = local.internal_fqdn
  private_zone = true
}

data "vault_generic_secret" "account_ids" {
  path = "aws-accounts/account-ids"
}

data "vault_generic_secret" "s3_releases" {
  path = "aws-accounts/shared-services/s3"
}

data "vault_generic_secret" "internal_cidrs" {
  path = "aws-accounts/network/internal_cidr_ranges"
}

data "vault_generic_secret" "kms_keys" {
  path = "aws-accounts/${var.aws_account}/kms"
}

data "vault_generic_secret" "security_kms_keys" {
  path = "aws-accounts/security/kms"
}

data "vault_generic_secret" "security_s3_buckets" {
  path = "aws-accounts/security/s3"
}

data "vault_generic_secret" "chs_vpc_subnets" {
  path = "aws-accounts/${var.environment}/vpc/subnets"
}

data "vault_generic_secret" "staffware_app_ec2_data" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/app/ec2"
}

data "vault_generic_secret" "staffware_app_config_data" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/app/config"
}

data "aws_acm_certificate" "acm_cert" {
  domain = var.domain_name
}

# ------------------------------------------------------------------------------
# iProcess App data
# ------------------------------------------------------------------------------
data "aws_ami" "iprocess_app" {
  owners      = [data.vault_generic_secret.account_ids.data["development"]]
  most_recent = var.ami_name == "iprocess-app-*" ? true : false

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

data "template_file" "userdata" {
  template = file("${path.module}/templates/fe_user_data.tpl")

  vars = {
    REGION               = var.aws_region
    HERITAGE_ENVIRONMENT = title(var.environment)
    IPROCESS_APP_INPUTS  = local.iprocess_app_data
    ANSIBLE_INPUTS       = jsonencode(local.iprocess_app_ansible_inputs)
  }
}

data "template_cloudinit_config" "userdata_config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.userdata.rendered
  }

}