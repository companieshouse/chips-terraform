<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.10, < 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0.0, < 6.0.0 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | >= 4.0, < 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0, < 6.0.0 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_vault"></a> [vault](#provider\_vault) | >= 4.0, < 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_asg"></a> [asg](#module\_asg) | git@github.com:companieshouse/terraform-modules//aws/autoscaling-with-launch-template | tags/1.0.365 |
| <a name="module_asg_security_group"></a> [asg\_security\_group](#module\_asg\_security\_group) | terraform-aws-modules/security-group/aws | 5.3.1 |
| <a name="module_instance_profile"></a> [instance\_profile](#module\_instance\_profile) | git@github.com:companieshouse/terraform-modules//aws/instance_profile | tags/1.0.365 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log_groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role_policy_attachment.inspector_cis_scanning_policy_attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_key_pair.keypair](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_ami.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_managed_prefix_list.administration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_route53_zone.private_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_subnets.application](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_cloudinit_config.userdata_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |
| [vault_generic_secret.account_ids](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.ec2_data](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.kms_keys](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.nfs_mounts](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.security_kms_keys](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.security_s3_buckets](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | Short version of the name of the AWS Account in which resources will be administered | `string` | n/a | yes |
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | Name of the AMI to use in the Auto Scaling configuration | `string` | `"docker-ami-*"` | no |
| <a name="input_application"></a> [application](#input\_application) | The component name of the application | `string` | n/a | yes |
| <a name="input_application_type"></a> [application\_type](#input\_application\_type) | The parent name of the application | `string` | `"chips"` | no |
| <a name="input_asg_count"></a> [asg\_count](#input\_asg\_count) | The number of ASGs - typically 1 for dev and 2 for staging/live | `number` | n/a | yes |
| <a name="input_asg_desired_capacity"></a> [asg\_desired\_capacity](#input\_asg\_desired\_capacity) | The desired capacity of ASG - always 1 | `number` | `1` | no |
| <a name="input_asg_max_size"></a> [asg\_max\_size](#input\_asg\_max\_size) | The max size of the ASG - always 1 | `number` | `1` | no |
| <a name="input_asg_min_size"></a> [asg\_min\_size](#input\_asg\_min\_size) | The min size of the ASG - always 1 | `number` | `1` | no |
| <a name="input_aws_account"></a> [aws\_account](#input\_aws\_account) | The name of the AWS Account in which resources will be administered | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region in which resources will be administered | `string` | n/a | yes |
| <a name="input_cloudwatch_logs"></a> [cloudwatch\_logs](#input\_cloudwatch\_logs) | Map of log file information; used to create log groups, IAM permissions and passed to the application to configure remote logging | `map(any)` | `{}` | no |
| <a name="input_config_bucket_name"></a> [config\_bucket\_name](#input\_config\_bucket\_name) | Bucket name the application will use to retrieve configuration files | `string` | `"shared-services.eu-west-2.configs.ch.gov.uk"` | no |
| <a name="input_default_log_group_retention_in_days"></a> [default\_log\_group\_retention\_in\_days](#input\_default\_log\_group\_retention\_in\_days) | Total days to retain logs in CloudWatch log group if not specified for specific logs | `number` | `14` | no |
| <a name="input_enable_instance_refresh"></a> [enable\_instance\_refresh](#input\_enable\_instance\_refresh) | Enable or disable instance refresh when the ASG is updated | `bool` | `true` | no |
| <a name="input_enforce_imdsv2"></a> [enforce\_imdsv2](#input\_enforce\_imdsv2) | Whether to enforce use of IMDSv2 by setting http\_tokens to required on the aws\_launch\_configuration | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_hashicorp_vault_password"></a> [hashicorp\_vault\_password](#input\_hashicorp\_vault\_password) | The password used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_hashicorp_vault_username"></a> [hashicorp\_vault\_username](#input\_hashicorp\_vault\_username) | The username used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_instance_root_volume_size"></a> [instance\_root\_volume\_size](#input\_instance\_root\_volume\_size) | Size of root volume attached to instances | `number` | `40` | no |
| <a name="input_instance_size"></a> [instance\_size](#input\_instance\_size) | The size of the ec2 instances to build | `string` | n/a | yes |
| <a name="input_instance_swap_volume_size"></a> [instance\_swap\_volume\_size](#input\_instance\_swap\_volume\_size) | Size of swap volume attached to instances | `number` | `5` | no |
| <a name="input_nfs_mount_destination_parent_dir"></a> [nfs\_mount\_destination\_parent\_dir](#input\_nfs\_mount\_destination\_parent\_dir) | The parent folder that all NFS shares should be mounted inside on the EC2 instance | `string` | `"/mnt"` | no |
| <a name="input_region"></a> [region](#input\_region) | Short version of the name of the AWS region in which resources will be administered | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->