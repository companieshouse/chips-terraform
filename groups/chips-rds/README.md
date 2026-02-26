# chips-rds

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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0.0, < 6.0.0 |
| <a name="provider_vault"></a> [vault](#provider\_vault) | >= 3.0.0, < 5.0.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_chips_rds"></a> [chips\_rds](#module\_chips\_rds) | terraform-aws-modules/rds/aws | ~> 6.0.0 |
| <a name="module_rds_cloudwatch_alarms"></a> [rds\_cloudwatch\_alarms](#module\_rds\_cloudwatch\_alarms) | git@github.com:companieshouse/terraform-modules//aws/oracledb_cloudwatch_alarms | tags/1.0.195 |
| <a name="module_rds_security_group"></a> [rds\_security\_group](#module\_rds\_security\_group) | terraform-aws-modules/security-group/aws | ~> 5.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_db_instance_role_association.s3_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance_role_association) | resource |
| [aws_iam_role.s3_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.s3_integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_route53_record.chips_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group_rule.egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_oem_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_oracle_prefix_list](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_oracle_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.staging_dba_dev_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ec2_managed_prefix_list.admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_ec2_managed_prefix_list.concourse](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_managed_prefix_list) | data source |
| [aws_iam_policy_document.rds_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.rds_enhanced_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_kms_key.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_route53_zone.private_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_security_group.rds_shared](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_group) | data source |
| [aws_security_groups.oracle_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/security_groups) | data source |
| [aws_subnets.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [vault_generic_secret.chips_rds](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |
| [vault_generic_secret.staging_dba_dev](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/data-sources/generic_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account"></a> [account](#input\_account) | Short version of the name of the AWS Account in which resources will be administered | `string` | n/a | yes |
| <a name="input_alarm_actions_enabled"></a> [alarm\_actions\_enabled](#input\_alarm\_actions\_enabled) | Defines whether SNS-based alarm actions should be enabled (true) or not (false) for alarms | `bool` | n/a | yes |
| <a name="input_alarm_topic_name"></a> [alarm\_topic\_name](#input\_alarm\_topic\_name) | The name of the SNS topic to use for in-hours alarm notifications and clear notifications | `string` | n/a | yes |
| <a name="input_alarm_topic_name_ooh"></a> [alarm\_topic\_name\_ooh](#input\_alarm\_topic\_name\_ooh) | The name of the SNS topic to use for OOH alarm notifications | `string` | n/a | yes |
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The amount of storage in GB to launch RDS with | `number` | n/a | yes |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | True/False value to allow AWS to apply minor version updates to RDS without approval from owner | `bool` | `true` | no |
| <a name="input_aws_account"></a> [aws\_account](#input\_aws\_account) | The name of the AWS Account in which resources will be administered | `string` | n/a | yes |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | The AWS profile to use | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region in which resources will be administered | `string` | n/a | yes |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The number of days to retain backups for - 0 to 35 | `number` | `7` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The engine version provided by AWS RDS e.g. 12.1.0.2.v21 | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The name of the environment | `string` | n/a | yes |
| <a name="input_hashicorp_vault_password"></a> [hashicorp\_vault\_password](#input\_hashicorp\_vault\_password) | The password used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_hashicorp_vault_username"></a> [hashicorp\_vault\_username](#input\_hashicorp\_vault\_username) | The username used when retrieving configuration from Hashicorp Vault | `string` | n/a | yes |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | Name to give to the instances and other components created for it, will be added to naming structure e.g. mydb will become rds-mydb-<env>-001 | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The type of instance for the RDS | `string` | `"db.t3.medium"` | no |
| <a name="input_iops"></a> [iops](#input\_iops) | Total number of IOPS to provision, requires storage type to be set to io1, there is a minimum of 1000 IOPS and 100GB storage required for Provisioned IOPS | `number` | `null` | no |
| <a name="input_license_model"></a> [license\_model](#input\_license\_model) | The license model for the engine, byol or license-include: https://aws.amazon.com/rds/oracle/faqs/ | `string` | n/a | yes |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | The major version of the database engine type e.g. 12.1 | `string` | n/a | yes |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | (Optional) Boolean to enable multi-az feature of RDS, subnets supplied must span multiple zones | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to give to the database created on the RDS Instance | `string` | n/a | yes |
| <a name="input_oracle_ingress_sg_patterns"></a> [oracle\_ingress\_sg\_patterns](#input\_oracle\_ingress\_sg\_patterns) | A list of security group name patterns that will be permitted to connect to the Oracle service | `list(string)` | `[]` | no |
| <a name="input_parameter_group_settings"></a> [parameter\_group\_settings](#input\_parameter\_group\_settings) | A list of parameters that will be set in the RDS instance parameter group | `list(any)` | n/a | yes |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Whether performance insights are required (true) or not (false). Typically enabled for Live resources. | `bool` | n/a | yes |
| <a name="input_rds_backup_window"></a> [rds\_backup\_window](#input\_rds\_backup\_window) | A backup window that allows AWS to backup your RDS instance e.g. `03:00-06:00` | `string` | `"03:00-06:00"` | no |
| <a name="input_rds_log_exports"></a> [rds\_log\_exports](#input\_rds\_log\_exports) | A list log types to export from RDS to Cloudwatch | `list(string)` | `[]` | no |
| <a name="input_rds_maintenance_window"></a> [rds\_maintenance\_window](#input\_rds\_maintenance\_window) | A maintenance window that will allow AWS to run maintenance on underlying hosts e.g. `Mon:00:00-Mon:03:00` | `string` | `"Sat:00:00-Sat:03:00"` | no |
| <a name="input_rds_onpremise_access"></a> [rds\_onpremise\_access](#input\_rds\_onpremise\_access) | A list of CIDR ranges or IPs to allow access from | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Short version of the name of the AWS region in which resources will be administered | `string` | n/a | yes |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_rds_address"></a> [rds\_address](#output\_rds\_address) | n/a |
<!-- END_TF_DOCS -->
