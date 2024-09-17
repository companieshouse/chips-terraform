data "aws_caller_identity" "current" {}

data "aws_vpc" "vpc" {
  tags = {
    Name = "vpc-${var.aws_account}"
  }
}

data "aws_subnet_ids" "application" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["sub-application-*"]
  }
}

data "aws_subnet" "application" {
  for_each = data.aws_subnet_ids.application.ids
  id       = each.value
}

data "aws_security_group" "chips_control" {
  filter {
    name   = "group-name"
    values = ["sgr-chips-control-asg-001-*"]
  }
}

data "aws_route53_zone" "private_zone" {
  name         = local.internal_fqdn
  private_zone = true
}

data "vault_generic_secret" "account_ids" {
  path = "aws-accounts/account-ids"
}

data "vault_generic_secret" "internal_cidrs" {
  path = "aws-accounts/network/internal_cidr_ranges"
}

data "vault_generic_secret" "ec2_data" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application_type}/app/ec2"
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

data "vault_generic_secret" "nfs_mounts" {
  path = "applications/${var.aws_account}-${var.aws_region}/${var.application_type}/app/nfs_mounts"
}

data "vault_generic_secret" "bus_perf_dashboard_s3" {
  path = "applications/${var.aws_account}-${var.aws_region}/performance-analytics/app/s3" 
}

data "vault_generic_secret" "bulk_gateway_s3" {
  path = "applications/${var.aws_account}-${var.aws_region}/bulk-gateway/app/s3" 
}

data "aws_ami" "ami" {
  owners      = [data.vault_generic_secret.account_ids.data["development"]]
  most_recent = var.ami_name == "docker-ami-*" ? true : false

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
    ANSIBLE_INPUTS             = jsonencode(local.userdata_ansible_inputs)
    DNS_DOMAIN                 = local.internal_fqdn
    DNS_ZONE_ID                = data.aws_route53_zone.private_zone.zone_id
    HERITAGE_ENVIRONMENT       = title(var.environment)
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
