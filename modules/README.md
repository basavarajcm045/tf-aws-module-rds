# Terraform Module: AWS RDS Instance

## Table of Contents

- [Overview](#overview)
- [Features](#Features)
- [Requirements](#Requirements)
- [Usage](#usage)
  - [Simple Storage Service](#simple-storage-service)
- [Configuration Guide](#configuration-guide)
- [Examples](#examples)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Notes](#notes)

## Overview

Enterprise-grade Terraform module for deploying and managing AWS RDS Oracle databases with comprehensive security, monitoring, backup, and compliance features.

## Features

### Oracle Engine Support
- **Oracle Database Enterprise Edition (oracle-ee)**
- **Oracle Database Standard Edition 2 (oracle-se2)**
- **Container Database (CDB) variants**
- **Supported Versions**: 12.1, 12.2, 19c, 21c
- Future-proof version management

### Licensing & Deployment
- **License Included (LI)** - Default
- **Bring Your Own License (BYOL)**
- **Single-AZ** deployment for dev/test
- **Multi-AZ** deployment for production

### Security (Enterprise-Grade)
- **Encryption at Rest** - KMS encryption (mandatory)
- **Secrets Manager Integration** - Automatic credential rotation
- **Enhanced Monitoring** - OS-level metrics
- **CloudWatch Logs** - Alert, Audit, Trace, Listener logs
- **Network Isolation** - VPC subnet groups
- **Security Groups** - Ingress/egress controls
- **Deletion Protection** - Prevent accidental deletion
- **IAM Database Authentication** - Optional

### Backup & Recovery
- **Automated Backups** - 7-35 days retention
- **Manual Snapshots** - On-demand backups
- **Point-in-Time Recovery** - Up to retention period
- **Copy Tags to Snapshot** - Maintain metadata
- **Final Snapshot** - Before deletion

### Performance Features
- **CloudWatch Alarms** - CPU, Storage, Connections, IOPS
- **Provisioned IOPS** - io1/io2 storage with custom IOPS
- **gp3 Storage** - Configurable IOPS and throughput

### Organization Standards
- ✅ **Required Tags** - CostCenter, Team, Compliance
- ✅ **Tag Validation** - Enforced via preconditions
- ✅ **Lifecycle Management** - Prevent destructive changes

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.14.0 | 
| aws | >= 6.0.0 |

## Module Usage
### Examples Directory Structure 
- see the **`examples/`**` directory for small, focused examples you can copy and adapt.

- [Basic Production Example](#basic production example)
- [High-Performance Production (Provisioned IOPS)](#High-Performance Production (Provisioned IOPS))
- [Development/Test Environment (Standard Edition 2)](#Development/Test Environment (Standard Edition 2))

### Basic Production Example

```hcl
module "oracle_db" {
  source = "../modules/"

  # Naming
  environment = "production"

  # Engine Configuration
  engine               = "oracle-ee"
  engine_version       = "19.0.0"
  license_model        = "license-included"

  # Instance Configuration
  instance_class    = "db.r6i.xlarge"
  allocated_storage = 500
  storage_type      = "gp3"
  storage_encrypted = true

  manage_master_user_password = true

  # Network Configuration
  subnet_ids             = ["subnet-xxx", "subnet-yyy"]
  vpc_security_group_ids = ["sg-xxx"]
  deployment_option      = "multi-az"

  # Backup Configuration
  backup_retention_period = 30

  # Monitoring
  enable_cloudwatch_logs      = true
  enable_enhanced_monitoring  = true
  enable_performance_insights = true

  # CloudWatch Alarms
  create_cloudwatch_alarms = true
  alarm_actions           = ["arn:aws:sns:us-east-1:123456789012:rds-alarms"]

  # Required Tags
  required_tags = {
    CostCenter = "Engineering"
    Team       = "Platform"
    Compliance = "SOC2"
  }
}
```

### High-Performance Production (Provisioned IOPS)

```hcl
module "oracle_high_perf" {
  source = "./modules/"

  environment = "production"

  # Oracle EE 21c
  engine               = "oracle-ee"
  engine_version_major = "21"
  license_model        = "license-included"

  # High-performance instance
  instance_class    = "db.r6i.2xlarge"
  allocated_storage = 1000
  storage_type      = "io2"
  iops              = 10000
  storage_encrypted = true
  max_allocated_storage     = 2000

  # Network
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]
  deployment_option      = "multi-az"

  manage_master_user_password = true

  # Backup
  backup_retention_period = 35

  # Monitoring - Extended retention
  enable_cloudwatch_logs             = true
  cloudwatch_log_types              = ["alert", "audit", "trace", "listener"]
  enable_enhanced_monitoring         = true
  monitoring_interval               = 30
  enable_performance_insights        = true
  performance_insights_retention_period = 731  # 2 years

  # Security
  deletion_protection = true

  # CloudWatch Alarms
  create_cloudwatch_alarms = true
  alarm_actions           = [aws_sns_topic.alarms.arn]

  # Required Tags
  required_tags = {
    CostCenter = "Engineering"
    Team       = "Platform"
    Compliance = "PCI-DSS"
  }
}
```
### Development/Test Environment (Standard Edition 2)

```hcl
module "oracle_dev" {
  source = "./modules/"

  environment = "development"

  # Oracle SE2 19c (lower cost)
  engine               = "oracle-se2"
  engine_version_major = "19"
  license_model        = "license-included"

  # Smaller instance
  instance_class    = "db.t3.medium"
  allocated_storage = 100
  storage_type      = "gp3"
  storage_encrypted = true

  # Network
  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]
  deployment_option      = "single-az"  # Single-AZ for dev

  # Database
  database_name = "DEVDB"
  manage_master_user_password = true

  # Backup - shorter retention for dev
  backup_retention_period = 7
  skip_final_snapshot    = true

  # Monitoring
  # enable_cloudwatch_logs      = true
  #enable_enhanced_monitoring  = true
  #enable_performance_insights = true

  # Security - less strict for dev
  deletion_protection = false
  apply_immediately   = true

  # CloudWatch Alarms
  #create_cloudwatch_alarms = true
  #alarm_actions           = [aws_sns_topic.alarms.arn]

  # Required Tags
  required_tags = {
    CostCenter = "Engineering"
    Team       = "Development"
    Compliance = "Internal"
  }
}
```

## Configuration Guide

### Basic Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `project_name` | string | - | Project name (required) |
| `environment` | string | - | Environment (dev, staging, prod) |
| `bucket_name` | string | "" | Bucket name (auto-generated if empty) |
| `tags` | map | {} | Common tags |

### Versioning



### Object Lock (Compliance)

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this] | resource |
| [aws_db_instance.this] | resource |
| [aws_iam_role_policy_attachment.enhanced_monitoring] | resource |


## Examples

Refer examples folder for complete examples:

1. Development - Minimal setup with basic security
2. Production - Maximum security with compliance
3. Website - Static site hosting
4. Backup - Immutable archive bucket

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gigabytes | `number` | `n/a` | yes |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any database modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | `bool` | `true` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for | `number` | `null` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance\_window | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The number of days to retain CloudWatch logs for the DB instance | `number` | `7` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | Additional tags for the CloudWatch log group(s) | `map(string)` | `{}` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a CloudWatch log group is created for each `enabled_cloudwatch_logs_exports` | `bool` | `false` | no |
| <a name="input_create_monitoring_role"></a> [create\_monitoring\_role](#input\_create\_monitoring\_role) | Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. | `bool` | `false` | no |
| <a name="input_db_instance_tags"></a> [db\_instance\_tags](#input\_db\_instance\_tags) | A map of additional tags for the DB instance | `map(string)` | `{}` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The DB name to create. If omitted, no database is created initially | `string` | `null` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC | `string` | `null` | no |
| <a name="input_dedicated_log_volume"></a> [dedicated\_log\_volume](#input\_dedicated\_log\_volume) | Use a dedicated log volume (DLV) for the DB instance. Requires Provisioned IOPS. | `bool` | `false` | no |
| <a name="input_delete_automated_backups"></a> [delete\_automated\_backups](#input\_delete\_automated\_backups) | Specifies whether to remove automated backups immediately after the DB instance is deleted | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | The database can't be deleted when this value is set to true. | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL). | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine to use | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The engine version to use | `string` | `null` | no |
| <a name="input_final_snapshot_identifier_prefix"></a> [final\_snapshot\_identifier\_prefix](#input\_final\_snapshot\_identifier\_prefix) | The name which is prefixed to the final snapshot on cluster destroy | `string` | `"final"` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | The name of the RDS instance | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance type of the RDS instance | `string` | `null` | no |
| <a name="input_iops"></a> [iops](#input\_iops) | The amount of provisioned IOPS. Setting this implies a storage\_type of 'io1' or `gp3`. See `notes` for limitations regarding this variable for `gp3` | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage\_encrypted is set to true and kms\_key\_id is not specified the default KMS key created in your account will be used | `string` | `null` | no |
| <a name="input_license_model"></a> [license\_model](#input\_license\_model) | License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1 | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00' | `string` | `null` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager. Cannot be set if password is provided | `bool` | `true` | no |
| <a name="input_manage_master_user_password_rotation"></a> [manage\_master\_user\_password\_rotation](#input\_manage\_master\_user\_password\_rotation) | Whether to manage the master user password rotation. By default, false on creation, rotation is managed by RDS. There is not currently a way to disable this on initial creation even when set to false. Setting this value to false after previously having been set to true will disable automatic rotation. | `bool` | `false` | no |
| <a name="input_master_user_password_rotate_immediately"></a> [master\_user\_password\_rotate\_immediately](#input\_master\_user\_password\_rotate\_immediately) | Specifies whether to rotate the secret immediately or wait until the next scheduled rotation window. | `bool` | `null` | no |
| <a name="input_master_user_password_rotation_automatically_after_days"></a> [master\_user\_password\_rotation\_automatically\_after\_days](#input\_master\_user\_password\_rotation\_automatically\_after\_days) | Specifies the number of days between automatic scheduled rotations of the secret. Either automatically\_after\_days or schedule\_expression must be specified. | `number` | `null` | no |
| <a name="input_master_user_password_rotation_duration"></a> [master\_user\_password\_rotation\_duration](#input\_master\_user\_password\_rotation\_duration) | The length of the rotation window in hours. For example, 3h for a three hour window. | `string` | `null` | no |
| <a name="input_master_user_password_rotation_schedule_expression"></a> [master\_user\_password\_rotation\_schedule\_expression](#input\_master\_user\_password\_rotation\_schedule\_expression) | A cron() or rate() expression that defines the schedule for rotating your secret. Either automatically\_after\_days or schedule\_expression must be specified. | `string` | `null` | no |
| <a name="input_master_user_secret_kms_key_id"></a> [master\_user\_secret\_kms\_key\_id](#input\_master\_user\_secret\_kms\_key\_id) | The key ARN, key ID, alias ARN or alias name for the KMS key to encrypt the master user password secret in Secrets Manager.<br/>  If not specified, the default KMS key for your Amazon Web Services account is used. | `string` | `null` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Specifies the value for Storage Autoscaling | `number` | `0` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| <a name="input_option_group_name"></a> [option\_group\_name](#input\_option\_group\_name) | Name of the DB option group to associate. | `string` | `null` | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | Name of the DB parameter group to associate | `string` | `null` | no |
| <a name="input_password_wo"></a> [password\_wo](#input\_password\_wo) | Write-Only required unless `manage_master_user_password` is set to `true`, `snapshot_identifier`, or `replicate_source_db` is provided). Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file | `string` | `null` | no |
| <a name="input_password_wo_version"></a> [password\_wo\_version](#input\_password\_wo\_version) | Used together with password\_wo to trigger an update. Increment this value when an update to password\_wo is required. | `number` | `null` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Specifies whether Performance Insights are enabled | `bool` | `false` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | The ARN for the KMS key to encrypt Performance Insights data. | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years). | `number` | `7` | no |
| <a name="input_port"></a> [port](#input\_port) | The port on which the DB accepts connections | `string` | `null` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Bool to control if instance is publicly accessible | `bool` | `false` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_replica_mode"></a> [replica\_mode](#input\_replica\_mode) | Specifies whether the replica is in either mounted or open-read-only mode. This attribute is only supported by Oracle instances. Oracle replicas operate in open-read-only mode unless otherwise specified | `string` | `null` | no |
| <a name="input_replicate_source_db"></a> [replicate\_source\_db](#input\_replicate\_source\_db) | Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate. | `string` | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05. | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB instance is encrypted | `bool` | `true` | no |
| <a name="input_storage_throughput"></a> [storage\_throughput](#input\_storage\_throughput) | Storage throughput value for the DB instance. This setting applies only to the `gp3` storage type. See `notes` for limitations regarding this variable for `gp3` | `number` | `null` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not. If you specify 'io1' or 'gp3' , you must also include a value for the 'iops' parameter | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Updated Terraform resource management timeouts. Applies to `aws_db_instance` in particular to permit resource management times | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | Time zone of the DB instance. timezone is currently only supported by Microsoft SQL Server. The timezone can only be set on creation. See MSSQL User Guide for more information. | `string` | `null` | no |
| <a name="input_upgrade_storage_config"></a> [upgrade\_storage\_config](#input\_upgrade\_storage\_config) | Whether to upgrade the storage file system configuration on the read replica. Can only be set with replicate\_source\_db. | `bool` | `null` | no |
| <a name="input_username"></a> [username](#input\_username) | Username for the master DB user | `string` | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate | `list(string)` | `[]` | no |

## Outputs

| Name                     | Description                                                  |
|--------------------------|--------------------------------------------------------------|
| `id`                     | The ID and ARN of the load balancer we created               |
| `arn`                    | The ID and ARN of the load balancer we created               |
| `dns_name`               | The DNS name of the load balancer                       |
| `arn_suffix`             | ARN suffix of our load balancer - can be used with CloudWatch |
| `zone_id`                | The zone_id of the load balancer to assist with creating DNS records |
| `listeners`              | Map of listeners created and their attributes                |
| `listener_arns`          | Map of listener ARNs, keyed by listener name                  |
| `listener_ids`           | Map of listener IDs, keyed by listener name                   |
| `listener_rules`         | Map of listeners rules created and their attributes           |
| `target_groups`          | Map of target groups created and their attributes             |
| `target_group_arns`      | Map of target group ARNs, keyed by target group name           |
| `target_group_ids`       | Map of target group IDs, keyed by target group name            |
| `target_group_attachments` | ARNs of the target group attachment IDs                     |
| `security_group_arn`     | Amazon Resource Name (ARN) of the security group              |
| `security_group_id`      | ID of the security group                                      |
| `route53_records`        | The Route53 records created and attached to the load balancer |

## Notes
-	Weighted Forwarding is only available for Application Load Balancers. Weighted forwarding requires actions with multiple target_groups and weight values.
-	If using HTTPS, ensure an ACM certificate is available in the same region.
-	Target group protocols must match listener protocols in supported combinations.
- WAFv2 is only supported for ALB.
- Ensure the subnets belong to the same VPC.
- For detailed use case, please refer example folder