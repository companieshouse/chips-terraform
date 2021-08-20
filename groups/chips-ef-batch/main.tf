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
  source = "git@github.com:companieshouse/terraform-modules//aws/chips-app?ref=feature/chips-module"

  application                      = var.application
  aws_region                       = var.aws_region
  aws_account                      = var.aws_account
  account                          = var.account
  region                           = var.region
  environment                      = var.environment
  asg_count                        = var.asg_count
  instance_size                    = var.instance_size
  nfs_server                       = var.nfs_server
  nfs_mount_destination_parent_dir = var.nfs_mount_destination_parent_dir
  nfs_mounts                       = var.nfs_mounts
  cloudwatch_logs                  = var.cloudwatch_logs
  config_bucket_name               = "shared-services.eu-west-2.configs.ch.gov.uk"
}
