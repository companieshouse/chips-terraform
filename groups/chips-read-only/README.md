<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0, < 6.0.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | >= 3.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_vault"></a> [vault](#provider\_vault) | >= 3.0.0, < 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_chips-read-only"></a> [chips-read-only](#module\_chips-read-only) | git@github.com:companieshouse/terraform-modules//aws/chips-app | 1.0.363 |

## Resources

| Name | Type |
|------|------|
| [vault_generic_secret.nfs_mounts](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.shared_s3](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | Name of the AMI to use in the Auto Scaling configuration | `string` | `"docker-ami-*"` | no |
| <a name="input_application"></a> [application](#input\_application) | The component name of the application | `string` | n/a | yes |
| <a name="input_application_type"></a> [application\_type](#input\_application\_type) | The parent name of the application | `string` | `"chips"` | no |
| <a name="input_asg_count"></a> [asg\_count](#input\_asg\_count) | The number of ASGs - typically 1 for dev and 2 for staging/live | `number` | n/a | yes |
| <a name="input_aws_account"></a> [aws\_account](#input\_aws\_account) | The name of the AWS Account in which resources will be administered | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region in which resources will be administered | `string` | n/a | yes |
| <a name="input_cloudwatch_logs"></a> [cloudwatch\_logs](#input\_cloudwatch\_logs) | Map of log file information; used to create log groups, IAM permissions and passed to the application to configure remote logging | `map(any)` | `{}` | no |
| <a name="input_enable_instance_refresh"></a> [enable\_instance\_refresh](#input\_enable\_instance\_refresh) | Enable or disable instance refresh when the ASG is updated | `bool` | `false` | no |
| <a name="input_enable_sns_topic"></a> [enable\_sns\_topic](#input\_enable\_sns\_topic) | A boolean value to indicate whether to deploy SNS topic configuration for CloudWatch actions | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_hashicorp_vault_password"></a> [hashicorp\_vault\_password](#input\_hashicorp\_vault\_password) | The password used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_hashicorp_vault_username"></a> [hashicorp\_vault\_username](#input\_hashicorp\_vault\_username) | The username used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_instance_size"></a> [instance\_size](#input\_instance\_size) | The size of the ec2 instances to build | `string` | n/a | yes |
| <a name="input_nfs_mount_destination_parent_dir"></a> [nfs\_mount\_destination\_parent\_dir](#input\_nfs\_mount\_destination\_parent\_dir) | The parent folder that all NFS shares should be mounted inside on the EC2 instance | `string` | `"/mnt"` | no |
| <a name="input_short_account"></a> [short\_account](#input\_short\_account) | Short version of the name of the AWS Account in which resources will be administered | `string` | `"hdev"` | no |
| <a name="input_short_region"></a> [short\_region](#input\_short\_region) | Short version of the name of the AWS region in which resources will be administered | `string` | `"euw2"` | no |
| <a name="input_ssh_access_security_group_patterns"></a> [ssh\_access\_security\_group\_patterns](#input\_ssh\_access\_security\_group\_patterns) | List of source security group name patterns that will have SSH access | `list(string)` | <pre>[<br/>  "sgr-chips-control-asg-001-*"<br/>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->