# ------------------------------------------------------------------------------
# Vault Variables
# ------------------------------------------------------------------------------
variable "vault_username" {
  type        = string
  description = "Username for connecting to Vault - usually supplied through TF_VARS"
}

variable "vault_password" {
  type        = string
  description = "Password for connecting to Vault - usually supplied through TF_VARS"
}

# ------------------------------------------------------------------------------
# AWS Variables
# ------------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  description = "The AWS region in which resources will be administered"
}

variable "aws_profile" {
  type        = string
  description = "The AWS profile to use"
}

variable "aws_account" {
  type        = string
  description = "The name of the AWS Account in which resources will be administered"
}

# ------------------------------------------------------------------------------
# AWS Variables - Shorthand
# ------------------------------------------------------------------------------

variable "account" {
  type        = string
  description = "Short version of the name of the AWS Account in which resources will be administered"
}

variable "region" {
  type        = string
  description = "Short version of the name of the AWS region in which resources will be administered"
}

# ------------------------------------------------------------------------------
# Application Variables
# ------------------------------------------------------------------------------


variable "application" {
  type        = string
  description = "The name of the application"
}

variable "environment" {
  type        = string
  description = "The name of the environment"
}

variable "domain_name" {
  type        = string
  default     = "*.companieshouse.gov.uk"
  description = "Domain Name for ACM Certificate"
}


# ------------------------------------------------------------------------------
# EC2 Variables
# ------------------------------------------------------------------------------
variable "ami_name" {
  type        = string
  default     = "oracle-12-*"
  description = "Name of the AMI to use in the Auto Scaling configuration for email servers"
}

variable "ami_id" {
  type        = string
  default     = null
  description = "Id of an AMI you want to force the Terraform to use, overrides ami_name"
}

variable "vpc_sg_cidr_blocks_oracle" {
  type        = list(any)
  description = "Security group cidr blocks for Oracle"
  default     = []
}

variable "vpc_sg_cidr_blocks_ssh" {
  type        = list(any)
  description = "Security group cidr blocks for ssh"
  default     = []
}

# ------------------------------------------------------------------------------
# EC2 Variables
# ------------------------------------------------------------------------------
variable "db_instance_size" {
  type        = string
  description = "The size of the ec2 instances"
}

variable "db_instance_count" {
  type        = string
  description = "The number of ec2 instances to create"
}

variable "cloudwatch_logs" {
  type        = map(any)
  default     = null
  description = "Map of log files to be collected by Cloudwatch Logs"
}

variable "availability_zones" {
  type        = list(string)
  default     = null
  description = "List of availability zone names (e.g. [eu-west-2a, eu-west-2b]) to deploy instances into, usually to meet constraints such as remote storage locality. Leaving null will deploy across all matching subnets/zones in the provided VPC"
}
