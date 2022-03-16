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
  description = "Set this to null to use the latest AMI, set the default to an AMI Id to hardcode and always use that AMI"
  default     = null
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

# ------------------------------------------------------------------------------
# Ansible SSM variables
# ------------------------------------------------------------------------------

variable "ansible_ssm_git_repo_name" {
  type        = string
  description = "Name of the repository containing Ansible code to be downloaded."
}

variable "ansible_ssm_git_repo_owner" {
  type        = string
  description = "Name of the repository owner containing Ansible code to be downloaded."
}

variable "ansible_ssm_git_repo_path" {
  type        = string
  description = "Directory prefix of code to be downloaded"
  default     = "ansible/"
}

variable "ansible_ssm_git_repo_options" {
  type        = string
  description = "Options for git code pull, e.g. 'branch:master'"
  default     = "branch:master"
}

variable "ansible_ssm_git_repo_token" {
  type        = string
  description = "Github token to authenticate Git operations if required."
  default     = null
}

variable "ansible_ssm_apply_only_at_cron_interval" {
  type        = string
  description = "If false, applies on terraform apply, then on provided schedule expression. If true first apply will be at the next occurance of the schedule expression."
  default     = true
}

variable "ansible_ssm_check_schedule_expression" {
  type        = string
  description = "SSM schedule expression for running playbook in check mode, see https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html for syntax."
  default     = null
}

variable "ansible_ssm_apply_schedule_expression" {
  type        = string
  description = "SSM schedule expression for running playbook in apply mode, see https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html for syntax."
  default     = null
}

variable "ansible_ssm_verbose_level" {
  type        = string
  description = "Verbosity flag to passs to ansible command, e.g. '-v', '-vvv'"
  default     = "-v"
}

variable "maintenance_window_schedule_expression" {
  type        = string
  description = "The schedule of the Maintenance Window in the form of a cron or rate expression"
  default     = null
}
variable "maintenance_window_duration" {
  type        = number
  description = "The duration of the Maintenance Window in hours"
  default     = 2
}
variable "maintenance_window_cutoff" {
  type        = number
  description = "The number of hours before the end of the Maintenance Window that Systems Manager stops scheduling new tasks for execution"
  default     = 1
}

variable "ssm_playbook_file_name" {
  type        = string
  description = "Name of the playbook file to run"
  default     = "playbook.yml"
}

variable "ssm_requirements_file_name" {
  type        = string
  description = "Name of the requirements file to download Ansible dependancies"
  default     = "requirements.yml"
}

variable "oracle_unqname" {
  type        = string
  description = "Value to be inserted into oracle users ORACLE_UNQNAME env variable"
  default     = ""
}

variable "oracle_sid" {
  type        = string
  description = "Value to be inserted into oracle users ORACLE_SID env variable"
  default     = ""
}
