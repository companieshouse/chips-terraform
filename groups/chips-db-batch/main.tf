terraform {
  required_version = ">= 0.13.0, < 2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 0.3, < 6.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 2.0.0, < 5.0"
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