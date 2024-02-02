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
# Environment Variables
# ------------------------------------------------------------------------------

variable "application" {
  type        = string
  description = "The name of the application"
}

variable "component" {
  type        = string
  description = "The name of the component within the application stack"
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

variable "public_allow_cidr_blocks" {
  type        = list(any)
  default     = ["0.0.0.0/0"]
  description = "cidr block for allowing inbound users from internet"
}

variable "enable_sns_topic" {
  type        = bool
  description = "A boolean value to alter deployment of an SNS topic for CloudWatch actions"
  default     = false
}

# ------------------------------------------------------------------------------
# iProcess App Variables 
# ------------------------------------------------------------------------------

variable "default_log_group_retention_in_days" {
  type        = number
  default     = 14
  description = "Total days to retain logs in CloudWatch log group if not specified for specific logs"
}

variable "ami_name" {
  type        = string
  default     = "iprocess-app-*"
  description = "Name of the AMI to use in the Auto Scaling configuration for frontend server(s)"
}

variable "instance_size" {
  type        = string
  description = "The size of the ec2 instances to build"
}

variable "min_size" {
  type        = number
  description = "The min size of the ASG"
}

variable "max_size" {
  type        = number
  description = "The max size of the ASG"
}

variable "desired_capacity" {
  type        = number
  description = "The desired capacity of ASG"
}

variable "cw_logs" {
  type        = map(any)
  description = "Map of log file information; used to create log groups, IAM permissions and passed to the application to configure remote logging"
  default     = {}
}

variable "cloudwatch_namespace" {
  type        = string
  default     = "CHIPS/STFWARE"
  description = "A custom namespace to define for CloudWatch custom metrics such as memory and disk"
}

variable "instance_swap_volume_size" {
  type        = number
  default     = 5
  description = "Size of swap volume attached to instances"
}

variable "instance_root_volume_size" {
  type        = number
  default     = 100
  description = "Size of root volume attached to instances"
}

variable "enforce_imdsv2" {
  description = "Whether to enforce use of IMDSv2 by setting http_tokens to required on the aws_launch_configuration"
  type        = bool
  default     = true
}