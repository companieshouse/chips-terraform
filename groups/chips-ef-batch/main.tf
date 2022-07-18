terraform {
  required_version = ">= 0.13.0, < 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 0.3, < 4.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 2.0.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

provider "vault" {
  auth_login {
    path = "auth/userpass/login/${var.vault_username}"
    parameters = {
      password = var.vault_password
    }
  }
}

module "chips-ef-batch" {
  source = "git@github.com:companieshouse/terraform-modules//aws/chips-app?ref=1.0.169"

  application                      = var.application
  application_type                 = var.application_type
  aws_region                       = var.aws_region
  aws_account                      = var.aws_account
  account                          = var.account
  region                           = var.region
  environment                      = var.environment
  asg_count                        = var.asg_count
  instance_size                    = var.instance_size
  enable_instance_refresh          = var.enable_instance_refresh
  nfs_mount_destination_parent_dir = var.nfs_mount_destination_parent_dir
  nfs_mounts                       = jsondecode(data.vault_generic_secret.nfs_mounts.data["${var.application}-mounts"])
  cloudwatch_logs                  = var.cloudwatch_logs
  config_bucket_name               = "shared-services.eu-west-2.configs.ch.gov.uk"
  alb_idle_timeout                 = 180
  enable_sns_topic                 = var.enable_sns_topic

  additional_ingress_with_cidr_blocks = [
    {
      from_port   = 49075
      to_port     = 49078
      protocol    = "tcp"
      description = "Tuxedo ports"
      cidr_blocks = join(",", [for s in module.chips-ef-batch.application_subnets : s.cidr_block])
    },
    {
      from_port   = 21010
      to_port     = 21014
      protocol    = "tcp"
      description = "WebLogic HTTP ports"
      cidr_blocks = join(",", [for s in module.chips-ef-batch.application_subnets : s.cidr_block])
    },
    {
      from_port   = 21030
      to_port     = 21034
      protocol    = "tcp"
      description = "WebLogic t3s ports"
      cidr_blocks = join(",", [for s in module.chips-ef-batch.application_subnets : s.cidr_block])
    }
  ]

  additional_userdata_suffix = <<-EOT
  su -l ec2-user weblogic-pre-bootstrap.sh
  su -l ec2-user bootstrap
  EOT

}
