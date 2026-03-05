<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0, < 6.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | >= 4.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0, < 6.0 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | >= 4.0, < 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_chips-users-rest"></a> [chips-users-rest](#module\_chips-users-rest) | git@github.com:companieshouse/terraform-modules//aws/chips-app | 1.0.365 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_managed_prefix_list.shared_services_cidrs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [vault_generic_secret.client_cidrs](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.nfs_mounts](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_health_check_path"></a> [admin\_health\_check\_path](#input\_admin\_health\_check\_path) | Target group health check path for administration console | `string` | `"/console"` | no |
| <a name="input_admin_port"></a> [admin\_port](#input\_admin\_port) | Target group backend port for administration | `number` | `21001` | no |
| <a name="input_alb_deletion_protection"></a> [alb\_deletion\_protection](#input\_alb\_deletion\_protection) | Enable or disable deletion protection for instances | `bool` | `false` | no |
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | Name of the AMI to use in the Auto Scaling configuration | `string` | `"docker-ami-*"` | no |
| <a name="input_app_health_check_path"></a> [app\_health\_check\_path](#input\_app\_health\_check\_path) | Target group health check path for application | `string` | `"/"` | no |
| <a name="input_application"></a> [application](#input\_application) | The component name of the application | `string` | n/a | yes |
| <a name="input_application_port"></a> [application\_port](#input\_application\_port) | Target group backend port for application | `number` | `21000` | no |
| <a name="input_application_type"></a> [application\_type](#input\_application\_type) | The parent name of the application | `string` | `"chips"` | no |
| <a name="input_asg_count"></a> [asg\_count](#input\_asg\_count) | The number of ASGs - typically 1 for dev and 2 for staging/live | `number` | n/a | yes |
| <a name="input_asg_desired_capacity"></a> [asg\_desired\_capacity](#input\_asg\_desired\_capacity) | The desired capacity of ASG - always 1 | `number` | `1` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | The max size of the ASG - always 1 | `number` | `1` | no |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | The min size of the ASG - always 1 | `number` | `1` | no |
| <a name="input_aws_account"></a> [aws\_account](#input\_aws\_account) | The name of the AWS Account in which resources will be administered | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region in which resources will be administered | `string` | n/a | yes |
| <a name="input_bootstrap_commands"></a> [bootstrap\_commands](#input\_bootstrap\_commands) | List of bootstrap commands to run during the instance startup | `list(string)` | <pre>[<br/>  "su -l ec2-user weblogic-pre-bootstrap.sh",<br/>  "su -l ec2-user bootstrap"<br/>]</pre> | no |
| <a name="input_cloudwatch_logs"></a> [cloudwatch\_logs](#input\_cloudwatch\_logs) | Map of log file information; used to create log groups, IAM permissions and passed to the application to configure remote logging | `map(any)` | `{}` | no |
| <a name="input_default_log_group_retention_in_days"></a> [default\_log\_group\_retention\_in\_days](#input\_default\_log\_group\_retention\_in\_days) | Total days to retain logs in CloudWatch log group if not specified for specific logs | `number` | `14` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain Name for ACM Certificate | `string` | `"*.companieshouse.gov.uk"` | no |
| <a name="input_enable_instance_refresh"></a> [enable\_instance\_refresh](#input\_enable\_instance\_refresh) | Enable or disable instance refresh when the ASG is updated | `bool` | `false` | no |
| <a name="input_enable_sns_topic"></a> [enable\_sns\_topic](#input\_enable\_sns\_topic) | A boolean value to indicate whether to deploy SNS topic configuration for CloudWatch actions | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_hashicorp_vault_password"></a> [hashicorp\_vault\_password](#input\_hashicorp\_vault\_password) | The password used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_hashicorp_vault_username"></a> [hashicorp\_vault\_username](#input\_hashicorp\_vault\_username) | The username used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_instance_root_volume_size"></a> [instance\_root\_volume\_size](#input\_instance\_root\_volume\_size) | Size of root volume attached to instances | `number` | `40` | no |
| <a name="input_instance_size"></a> [instance\_size](#input\_instance\_size) | The size of the ec2 instances to build | `string` | n/a | yes |
| <a name="input_nfs_mount_destination_parent_dir"></a> [nfs\_mount\_destination\_parent\_dir](#input\_nfs\_mount\_destination\_parent\_dir) | The parent folder that all NFS shares should be mounted inside on the EC2 instance | `string` | `"/mnt"` | no |
| <a name="input_post_bootstrap_commands"></a> [post\_bootstrap\_commands](#input\_post\_bootstrap\_commands) | List of commands to run after the bootstrap commands on instance startup | `list(string)` | `[]` | no |
| <a name="input_short_account"></a> [short\_account](#input\_short\_account) | Short version of the name of the AWS Account in which resources will be administered | `string` | `"hdev"` | no |
| <a name="input_short_region"></a> [short\_region](#input\_short\_region) | Short version of the name of the AWS region in which resources will be administered | `string` | `"euw2"` | no |
| <a name="input_ssh_access_security_group_patterns"></a> [ssh\_access\_security\_group\_patterns](#input\_ssh\_access\_security\_group\_patterns) | List of source security group name patterns that will have SSH access | `list(string)` | <pre>[<br/>  "sgr-chips-control-asg-001-*"<br/>]</pre> | no |
| <a name="input_test_access_enable"></a> [test\_access\_enable](#input\_test\_access\_enable) | Controls whether access from the Test subnets is required (true) or not (false) | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->