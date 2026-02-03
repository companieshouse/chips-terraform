data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  tags = {
    Name = "vpc-${var.aws_account}"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["sub-public-*"]
  }
}

data "aws_subnets" "data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["sub-data-*"]
  }
}

data "aws_subnets" "application" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["sub-application-*"]
  }
}

data "aws_subnet" "data" {
  for_each = data.aws_subnets.data.ids

  id = each.value
}

data "aws_security_group" "nagios_shared" {
  filter {
    name   = "group-name"
    values = ["sgr-nagios-inbound-shared-*"]
  }
}

data "aws_security_group" "chips_users_rest_app" {
  filter {
    name   = "group-name"
    values = ["sgr-chips-users-rest-asg-*"]
  }
}

data "aws_security_group" "chips_ef_batch_app" {
  filter {
    name   = "group-name"
    values = ["sgr-chips-ef-batch-asg-*"]
  }
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

data "aws_ec2_managed_prefix_list" "admin" {
  name = "administration-cidr-ranges"
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

data "vault_generic_secret" "iprocess_app_ec2_data" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/app/ec2"
}

data "vault_generic_secret" "iprocess_app_config_data" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application}/app/iprocess"
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
  template = file("${path.module}/templates/user_data.tpl")

  vars = {
    APPLICATION                    = var.component
    HERITAGE_ENVIRONMENT           = title(var.environment)
    REGION                         = var.aws_region
    R53_ZONEID                     = data.aws_route53_zone.private_zone.zone_id
    DEPLOYMENT_ANSIBLE_INPUTS_PATH = "${local.parameter_store_path_prefix}/deployment_ansible_inputs"
    TNSNAMES_INPUTS_PATH           = "${local.parameter_store_path_prefix}/tnsnames_inputs"
    STAFF_DAT_INPUTS_PATH          = "${local.parameter_store_path_prefix}/staff_dat_inputs"
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
