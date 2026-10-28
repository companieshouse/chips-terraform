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

variable "short_account" {
  type        = string
  default     = "hdev"
  description = "Short version of the name of the AWS Account in which resources will be administered"
}

variable "short_region" {
  type        = string
  default     = "euw2"
  description = "Short version of the name of the AWS region in which resources will be administered"
}

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

variable "application" {
  type        = string
  description = "The component name of the application"
}

variable "environment" {
  type        = string
  description = "The name of the environment"
}

variable "application_type" {
  type        = string
  default     = "chips"
  description = "The parent name of the application"
}

# ------------------------------------------------------------------------------
# CHIPS ASG Variables
# ------------------------------------------------------------------------------

variable "instance_size" {
  type        = string
  description = "The size of the ec2 instances to build"
}

variable "asg_min_size" {
  type        = number
  default     = 1
  description = "The min size of the ASG - always 1"
}

variable "asg_max_size" {
  type        = number
  default     = 1
  description = "The max size of the ASG - always 1"
}

variable "asg_desired_capacity" {
  type        = number
  default     = 1
  description = "The desired capacity of ASG - always 1"
}

variable "asg_count" {
  type        = number
  description = "The number of ASGs - typically 1 for dev and 2 for staging/live"
}

variable "ami_name" {
  type        = string
  default     = "docker-ami-*"
  description = "Name of the AMI to use in the Auto Scaling configuration"
}

variable "instance_root_volume_size" {
  type        = number
  default     = 40
  description = "Size of root volume attached to instances"
}

variable "alb_deletion_protection" {
  type        = bool
  default     = false
  description = "Enable or disable deletion protection for instances"
}

variable "enable_instance_refresh" {
  type        = bool
  default     = false
  description = "Enable or disable instance refresh when the ASG is updated"
}

variable "ssh_access_security_group_patterns" {
  type        = list(string)
  description = "List of source security group name patterns that will have SSH access"
  default     = ["sgr-chips-control-asg-001-*"]
}

# ------------------------------------------------------------------------------
# CHIPS ALB Variables
# ------------------------------------------------------------------------------

variable "application_port" {
  type        = number
  default     = 21000
  description = "Target group backend port for application"
}

variable "admin_port" {
  type        = number
  default     = 21001
  description = "Target group backend port for administration"
}

variable "app_health_check_path" {
  type        = string
  default     = "/"
  description = "Target group health check path for application"
}

variable "admin_health_check_path" {
  type        = string
  default     = "/console"
  description = "Target group health check path for administration console"
}

variable "domain_name" {
  type        = string
  default     = "*.companieshouse.gov.uk"
  description = "Domain Name for ACM Certificate"
}

# ------------------------------------------------------------------------------
# NFS Mount Variables
# ------------------------------------------------------------------------------
# See Ansible role for full documentation on NFS arguements:
#      https://github.com/companieshouse/ansible-collections/tree/main/ch_collections/heritage_services/roles/nfs/files/nfs_mounts
variable "nfs_mount_destination_parent_dir" {
  type        = string
  description = "The parent folder that all NFS shares should be mounted inside on the EC2 instance"
  default     = "/mnt"
}

variable "default_log_group_retention_in_days" {
  type        = number
  default     = 14
  description = "Total days to retain logs in CloudWatch log group if not specified for specific logs"
}

variable "cloudwatch_logs" {
  type        = map(any)
  description = "Map of log file information; used to create log groups, IAM permissions and passed to the application to configure remote logging"
  default     = {}
}

variable "enable_sns_topic" {
  type        = bool
  description = "A boolean value to indicate whether to deploy SNS topic configuration for CloudWatch actions"
  default     = false
}

variable "bootstrap_commands" {
  type = list(string)
  default = [
    "su -l ec2-user weblogic-pre-bootstrap.sh",
    "su -l ec2-user bootstrap"
  ]
  description = "List of bootstrap commands to run during the instance startup"
}

variable "post_bootstrap_commands" {
  type        = list(string)
  default     = []
  description = "List of commands to run after the bootstrap commands on instance startup"
}
