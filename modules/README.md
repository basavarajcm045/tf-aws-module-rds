# Terraform Module: Simple Storage Service

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

This Terraform module creates and manages AWS S3 with support for:

- Bucket creation
- Versioning and Object lock
- Encryption and KMS key creation
- Public access block
- Lifecycle configuration
- Bucket Policy
- 
## Features

  ### 🔒 Security
- ✅ Server-side encryption (AES256 or KMS)
- ✅ SSL/TLS enforcement
- ✅ Public access blocking
- ✅ Bucket policies with least privilege
- ✅ IAM access controls
- ✅ Versioning and MFA delete protection
- ✅ Object lock for compliance
- ✅ Encrypted logging

### 📊 Lifecycle Management
- ✅ Automatic object archival
- ✅ Storage class transitions (S3, IA, Glacier, Deep Archive)
- ✅ Expiration policies
- ✅ Noncurrent version management
- ✅ Incomplete multipart upload cleanup
- ✅ Intelligent tiering
- ✅ Option to choose required lifecycle policies as per bucket requirement.

### 📋 Compliance & Governance
- ✅ Access logging with audit trail
- ✅ Inventory reports (CSV, Parquet, ORC)
- ✅ CloudWatch metrics and alarms
- ✅ Object lock (GOVERNANCE or COMPLIANCE mode)
- ✅ Cross-region replication
- ✅ Retention policies
- ✅ Compliance summary reporting

- **Supports multiple types**: Development env, Production env - Max security and compliance, Static Website hosting, Backup-read only replica, Data lake - optimized for analysis.
- **Access logs** configuration (S3 bucket & prefix).
- **Deletion protection** toggle.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.14 |
| aws | >= 6 |

## Usage

### Simple storage service

This is just a sample code. Please refer to example folder for actual use case.

### Basic Usage

```hcl
module "s3_bucket" {
  # Path to your S3 module
  source = "../../tf-aws-module-s3"

  project_name = "myapp"
  environment  = "dev"
  bucket_name  = "myapp-dev-bucket"

  tags = {
    Team = "Engineering"
  }
}
```
### Get Bucket Information

```bash
terraform output -from-module=./modules/s3
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

Enable versioning for data protection and recovery:

```hcl
enable_versioning = true
enable_mfa_delete = false  # Requires root account setup
```

### Object Lock (Compliance)

Prevent object deletion for regulatory requirements:

```hcl
enable_object_lock       = true
object_lock_default_mode = "COMPLIANCE"  # or "GOVERNANCE"
object_lock_default_years = 7
```

### Encryption

**AES256 (Default)**
```hcl
encryption_type = "aes256"
```

**KMS (Recommended for sensitive data)**
```hcl
encryption_type = "kms"
kms_key_id      = ""  # Auto-create or provide existing key
bucket_key_enabled = true  # Reduces KMS API calls
```

### Public Access Control

Block all public access (recommended):

```hcl
acl                     = "private"
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

Allow public read-only:

```hcl
acl                     = "public-read"
block_public_acls       = false
block_public_policy     = false
ignore_public_acls      = false
restrict_public_buckets = false
```

### Lifecycle Rules

Archive and delete objects based on age:

```hcl
lifecycle_rules = [
  {
    id      = "archive-old-objects"
    enabled = true
    prefix  = ""
    
    # Transition to cheaper storage
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      },
      {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    ]

    
    # Delete after 7 years
    expiration = {
      days = 2555
    }
    
    # Clean old versions
    noncurrent_version_expiration = {
      noncurrent_days = 90
    }
    
    # Clean incomplete uploads
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
  }
]
```
### Logging Configuration

Enable access logging for audit trails:

```hcl
enable_logging     = true
log_prefix         = "access-logs/"
log_retention_days = 2555  # 7 years
```

### Replication (Disaster Recovery)


### CORS Configuration

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

| Name | Description |
|------|-------------|
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