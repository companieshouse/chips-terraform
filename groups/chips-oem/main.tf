# ------------------------------------------------------------------------------
# Providers
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0, < 6.0.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.0.0, < 5.0.0"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}
