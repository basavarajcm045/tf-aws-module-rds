# Terraform Module: AWS RDS Instance

## Table of Contents

- [Overview](#overview) 
- [Features](#Features)
- [Requirements](#Requirements)
- [Usage](#usage)
- [Resources](#Resources)
- [Security Best Practices](#securitybestpractices)
- [Cost Optimization](#costoptimization)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)

## Overview

Enterprise-grade Terraform module for deploying and managing AWS RDS Oracle databases with comprehensive security, monitoring, backup, and compliance features.

This repository contains example implementations of the reusable RDS Terraform module.
The module provisions a fully configured Amazon RDS instance along with:

- DB Subnet Group

- DB Parameter Group

- DB Option Group

- CloudWatch Log Groups

- CloudWatch Alarms

- Monitoring & logging configuration

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

- **Required Tags** - CostCenter, Team, Compliance
- **Tag Validation** - Enforced via preconditions
- **Lifecycle Management** - Prevent destructive changes

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.14.0 | 
| aws | >= 6.0.0 |

## Usage

### Examples Directory Structure

see the **`examples/`**` directory for small, focused examples you can copy and adapt.

1. **Oracle Production Instance Example** - Multi-AZ with all features
2. **Oracle Development/Test Instance Example** - Single-AZ cost-optimized
3. **Mysql Production Instance Example** 
4. **Restore from Snapshot Example** - Multi-AZ with all features

### Oracle Production Intance Example

```hcl
module "oracle_prod" {
  source = "../../modules/"

  environment = "production"

  # Oracle EE 21c
  engine               = "oracle-ee"
  engine_version       = "21"
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
  multi-az.              = true

  manage_master_user_password = true

  # Backup
  backup_retention_period = 35

  # Custom Parameter Group
  create_parameter_group = true
  parameter_group_family = "oracle-ee-19"
  parameters = [
    {
      name  = "open_cursors"
      value = "2000"
    },
    {
      name  = "processes"
      value = "500"
    },
    {
      name  = "sessions"
      value = "555"
    },
    {
      name  = "db_file_multiblock_read_count"
      value = "64"
    }
  ]

  # Custom Option Group
  create_option_group = true
  options = [
    {
      option_name = "OEM"
      port        = 5500
      vpc_security_group_memberships = [aws_security_group.rds.id]
      option_settings = [
        {
          name  = "OMS_PORT"
          value = "5500"
        }
      ]
    },
    {
      option_name = "STATSPACK"
    }
  ]
  
  # Monitoring - Extended retention
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["alert", "audit", "trace", "listener"]
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id = var.cloudwatch_kms_key
  cloudwatch_log_group_skip_destroy = true
  cloudwatch_log_group_class = STANDARD // INFREQUENT_ACCESS
  region = var.region

  # CloudWatch Alarms
  #create_cloudwatch_alarms = true
  #alarm_actions           = [aws_sns_topic.alarms.arn]

  enable_enhanced_monitoring         = true
  monitoring_interval                = 30
  performance_insights_enabled        = true
  performance_insights_retention_period = 731  # 2 years

  # Security
  deletion_protection = true
}
```

### Oracle Development/Test Instance Example

```hcl
module "oracle_dev" {
  source = "../../modules/"

  environment = "dev"

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
  multi-az.              = false  # Single-AZ for dev

  # Database
  database_name = "DEVDB"
  manage_master_user_password = true

  # Backup - shorter retention for dev
  backup_retention_period = 7
  skip_final_snapshot    = true

  # Monitoring
  create_cloudwatch_log_group = true
  enable_enhanced_monitoring  = true
  
  # Security - less strict for dev
  deletion_protection = false
  apply_immediately   = true

  # Required Tags
  equired_tags = {
    CostCenter = "Engineering"
    Team       = "Database"
    Compliance = "SOC2"
  }
}
```

### Mysql Production Instance Example

```hcl
module "oracle_high_perf" {
  source = "../../modules/"

  environment = "prod"

  # Mysql EE
  engine               = "mysql-ee"
  engine_version       = "8.0"
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
  multi-az               = true

  manage_master_user_password = true

  # Backup
  backup_retention_period = 35

  # Custom Parameter Group
  create_parameter_group = true
  parameter_group_family = "mysql8.4"
  
  db_parameter = [
    {
      name         = "slow_query_log"
      value        = "1"
      apply_method = "pending-reboot" //"immediate", pending-reboot, 
    },

    {
      name         = "long_query_time"
      value        = "2"
      apply_method = "pending-reboot"
    }
  ]

  # Custom Option Group
  create_db_option_group = false
  major_engine_version   = 8.0
  
  # Monitoring - Extended retention
  
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["general"]
  cloudwatch_log_group_retention_in_days = 14
  cloudwatch_log_group_kms_key_id = var.cloudwatch_kms_key
  cloudwatch_log_group_skip_destroy = true
  cloudwatch_log_group_class = STANDARD // INFREQUENT_ACCESS
  region = var.region

  enable_enhanced_monitoring         = true
  monitoring_interval                = 30
  performance_insights_enabled        = true
  performance_insights_retention_period = 731  # 2 years

  # Security
  deletion_protection = true
}
```

### Restore from Snapshot Example

```hcl
module "oracle_restored" {
  source = "../modules/"

  environment = "production"

  # Restore from snapshot
  snapshot_identifier = "arn:aws:rds:us-east-1:123456789012:snapshot:myapp-snapshot-2024-01-15"

  subnet_ids             = var.subnet_ids
  manage_master_user_password = true

  backup_retention_period = ""

  create_cloudwatch_log_group      = ""

  enable_performance_insights = ""

}
```

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this] | resource |
| [aws_db_instance.this] | resource |
| [aws_iam_role_policy_attachment.enhanced_monitoring] | resource |

## Security Best Practices

### 1. Encryption

```hcl
storage_encrypted = true  # MANDATORY
create_kms_key    = true  # Recommended
```

### 2. Network Isolation

```hcl
publicly_accessible = false  # ENFORCED
multi-az           = true  # Production
```

### 3. Access Control

```hcl
manage_master_user_password = true  # Use Secrets Manager
vpc_security_group_ids      = [sg_id]  # Restrict access
```

### 4. Monitoring & Auditing

```hcl
create_cloudwatch_log_group      = true
cloudwatch_log_types       = ["alert", "audit", "trace", "listener"]
enable_enhanced_monitoring  = true
enable_performance_insights = true
```

### 5. Backup & Recovery

```hcl
backup_retention_period = 30  # 30 days for production
skip_final_snapshot    = false
copy_tags_to_snapshot  = true
deletion_protection    = true
```

## Cost Optimization

### 1. Right-Size Instances

- Start with smaller instances
- Monitor Performance Insights
- Scale up based on metrics

### 2. Storage Optimization

```hcl
enable_storage_autoscaling = true
max_allocated_storage     = 2 * allocated_storage
```

### 3. Use gp3 Instead of io2

- 20% cheaper than gp2
- Configurable performance
- Upgrade from gp2 without downtime

### 4. Optimize Backups

- 7 days for dev/test
- 30 days for production
- Delete old manual snapshots

### 5. Reserved Instances

- 30-60% savings
- 1 or 3-year terms
- Match instance class exactly

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allocated_storage"></a> [allocated\_storage](#input\_allocated\_storage) | The allocated storage in gigabytes | `number` | `null` | no |
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Indicates that major version upgrades are allowed. Changing this parameter does not result in an outage and the change is asynchronously applied as soon as possible | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Specifies whether any database modifications are applied immediately, or during the next maintenance window | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window | `bool` | `true` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The Availability Zone of the RDS instance | `string` | `null` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | The days to retain backups for | `number` | `null` | no |
| <a name="input_backup_window"></a> [backup\_window](#input\_backup\_window) | The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance\_window | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_class"></a> [cloudwatch\_log\_group\_class](#input\_cloudwatch\_log\_group\_class) | Specified the log class of the log group. Possible values are: STANDARD or INFREQUENT\_ACCESS | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | The ARN of the KMS Key to use when encrypting log data | `string` | `null` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | The number of days to retain CloudWatch logs for the DB instance | `number` | `7` | no |
| <a name="input_cloudwatch_log_group_skip_destroy"></a> [cloudwatch\_log\_group\_skip\_destroy](#input\_cloudwatch\_log\_group\_skip\_destroy) | Set to true if you do not wish the log group (and any logs it may contain) to be deleted at destroy time, and instead just remove the log group from the Terraform state | `bool` | `null` | no |

| <a name="input_copy_tags_to_snapshot"></a> [copy\_tags\_to\_snapshot](#input\_copy\_tags\_to\_snapshot) | On delete, copy all Instance tags to the final snapshot | `bool` | `true` | no |
| <a name="input_create_cloudwatch_log_group"></a> [create\_cloudwatch\_log\_group](#input\_create\_cloudwatch\_log\_group) | Determines whether a CloudWatch log group is created for each `enabled_cloudwatch_logs_exports` | `bool` | `false` | no |
| <a name="input_create_db_instance"></a> [create\_db\_instance](#input\_create\_db\_instance) | Whether to create a database instance | `bool` | `true` | no |
| <a name="input_create_db_option_group"></a> [create\_db\_option\_group](#input\_create\_db\_option\_group) | Create a database option group | `bool` | `true` | no |
| <a name="input_create_db_parameter_group"></a> [create\_db\_parameter\_group](#input\_create\_db\_parameter\_group) | Whether to create a database parameter group | `bool` | `true` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Whether to create a database subnet group | `bool` | `false` | no |
| <a name="input_create_monitoring_role"></a> [create\_monitoring\_role](#input\_create\_monitoring\_role) | Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `bool` | `false` | no |
| <a name="input_custom_iam_instance_profile"></a> [custom\_iam\_instance\_profile](#input\_custom\_iam\_instance\_profile) | RDS custom iam instance profile | `string` | `null` | no |
| <a name="input_database_insights_mode"></a> [database\_insights\_mode](#input\_database\_insights\_mode) | The mode of Database Insights that is enabled for the instance. Valid values: standard, advanced | `string` | `null` | no |
| <a name="input_db_instance_role_associations"></a> [db\_instance\_role\_associations](#input\_db\_instance\_role\_associations) | A map of DB instance supported feature name to role association ARNs. | `map(string)` | `{}` | no |
| <a name="input_db_instance_tags"></a> [db\_instance\_tags](#input\_db\_instance\_tags) | Additional tags for the DB instance | `map(string)` | `{}` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | The DB name to create. If omitted, no database is created initially | `string` | `null` | no |
| <a name="input_db_option_group_tags"></a> [db\_option\_group\_tags](#input\_db\_option\_group\_tags) | Additional tags for the DB option group | `map(string)` | `{}` | no |
| <a name="input_db_parameter_group_tags"></a> [db\_parameter\_group\_tags](#input\_db\_parameter\_group\_tags) | Additional tags for the  DB parameter group | `map(string)` | `{}` | no |
| <a name="input_db_subnet_group_name"></a> [db\_subnet\_group\_name](#input\_db\_subnet\_group\_name) | Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC | `string` | `null` | no |
| <a name="input_db_subnet_group_tags"></a> [db\_subnet\_group\_tags](#input\_db\_subnet\_group\_tags) | Additional tags for the DB subnet group | `map(string)` | `{}` | no |
| <a name="input_delete_automated_backups"></a> [delete\_automated\_backups](#input\_delete\_automated\_backups) | Specifies whether to remove automated backups immediately after the DB instance is deleted | `bool` | `true` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | The database can't be deleted when this value is set to true | `bool` | `false` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL) | `list(string)` | `[]` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine to use | `string` | `null` | no |
| <a name="input_engine_lifecycle_support"></a> [engine\_lifecycle\_support](#input\_engine\_lifecycle\_support) | The life cycle type for this DB instance. This setting applies only to RDS for MySQL and RDS for PostgreSQL. Valid values are `open-source-rds-extended-support`, `open-source-rds-extended-support-disabled`. Default value is `open-source-rds-extended-support`. | `string` | `null` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The engine version to use | `string` | `null` | no |
| <a name="input_family"></a> [family](#input\_family) | The family of the DB parameter group | `string` | `null` | no |
| <a name="input_final_snapshot_identifier_prefix"></a> [final\_snapshot\_identifier\_prefix](#input\_final\_snapshot\_identifier\_prefix) | The name which is prefixed to the final snapshot on cluster destroy | `string` | `"final"` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Specifies whether or not the mappings of AWS Identity and Access Management (IAM) accounts to database accounts are enabled | `bool` | `false` | no |
| <a name="input_identifier"></a> [identifier](#input\_identifier) | The name of the RDS instance | `string` | n/a | yes |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance type of the RDS instance | `string` | `null` | no |
| <a name="input_instance_use_identifier_prefix"></a> [instance\_use\_identifier\_prefix](#input\_instance\_use\_identifier\_prefix) | Determines whether to use `identifier` as is or create a unique identifier beginning with `identifier` as the specified prefix | `bool` | `false` | no |
| <a name="input_iops"></a> [iops](#input\_iops) | The amount of provisioned IOPS. Setting this implies a storage\_type of 'io1' or `gp3`. See `notes` for limitations regarding this variable for `gp3` | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage\_encrypted is set to true and kms\_key\_id is not specified the default KMS key created in your account will be used. Be sure to use the full ARN, not a key alias. | `string` | `null` | no |
| <a name="input_license_model"></a> [license\_model](#input\_license\_model) | License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1 | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance\_window](#input\_maintenance\_window) | The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00' | `string` | `null` | no |
| <a name="input_major_engine_version"></a> [major\_engine\_version](#input\_major\_engine\_version) | Specifies the major version of the engine that this option group should be associated with | `string` | `null` | no |
| <a name="input_manage_master_user_password"></a> [manage\_master\_user\_password](#input\_manage\_master\_user\_password) | Set to true to allow RDS to manage the master user password in Secrets Manager | `bool` | `true` | no |
| <a name="input_max_allocated_storage"></a> [max\_allocated\_storage](#input\_max\_allocated\_storage) | Specifies the value for Storage Autoscaling | `number` | `0` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60 | `number` | `0` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Must be specified if monitoring\_interval is non-zero | `string` | `null` | no |
| <a name="input_monitoring_role_description"></a> [monitoring\_role\_description](#input\_monitoring\_role\_description) | Description of the monitoring IAM role | `string` | `null` | no |
| <a name="input_monitoring_role_name"></a> [monitoring\_role\_name](#input\_monitoring\_role\_name) | Name of the IAM role which will be created when create\_monitoring\_role is enabled | `string` | `"rds-monitoring-role"` | no |
| <a name="input_monitoring_role_permissions_boundary"></a> [monitoring\_role\_permissions\_boundary](#input\_monitoring\_role\_permissions\_boundary) | ARN of the policy that is used to set the permissions boundary for the monitoring IAM role | `string` | `null` | no |
| <a name="input_monitoring_role_use_name_prefix"></a> [monitoring\_role\_use\_name\_prefix](#input\_monitoring\_role\_use\_name\_prefix) | Determines whether to use `monitoring_role_name` as is or create a unique identifier beginning with `monitoring_role_name` as the specified prefix | `bool` | `false` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | Specifies if the RDS instance is multi-AZ | `bool` | `false` | no |
| <a name="input_option_group_name"></a> [option\_group\_name](#input\_option\_group\_name) | Name of the option group | `string` | `null` | no |
| <a name="input_option_group_skip_destroy"></a> [option\_group\_skip\_destroy](#input\_option\_group\_skip\_destroy) | Set to true if you do not wish the option group to be deleted at destroy time, and instead just remove the option group from the Terraform state | `bool` | `null` | no |
| <a name="input_option_group_timeouts"></a> [option\_group\_timeouts](#input\_option\_group\_timeouts) | Define maximum timeout for deletion of `aws_db_option_group` resource | <pre>object({<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | Name of the DB parameter group to associate or create | `string` | `null` | no |
| <a name="input_parameter_group_skip_destroy"></a> [parameter\_group\_skip\_destroy](#input\_parameter\_group\_skip\_destroy) | Set to true if you do not wish the parameter group to be deleted at destroy time, and instead just remove the parameter group from the Terraform state | `bool` | `null` | no |
| <a name="input_parameter_group_use_name_prefix"></a> [parameter\_group\_use\_name\_prefix](#input\_parameter\_group\_use\_name\_prefix) | Determines whether to use `parameter_group_name` as is or create a unique name beginning with the `parameter_group_name` as the prefix | `bool` | `true` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | A list of DB parameters (map) to apply | <pre>list(object({<br/>    name         = string<br/>    value        = string<br/>    apply_method = optional(string)<br/>  }))</pre> | `null` | no |
| <a name="input_password_wo"></a> [password\_wo](#input\_password\_wo) | Write-Only required unless `manage_master_user_password` is set to `true`, `snapshot_identifier`, or `replicate_source_db` is provided). Password for the master DB user. Note that this may show up in logs, and it will be stored in the state file | `string` | `null` | no |
| <a name="input_password_wo_version"></a> [password\_wo\_version](#input\_password\_wo\_version) | Used together with password\_wo to trigger an update. Increment this value when an update to password\_wo is required. | `number` | `null` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Specifies whether Performance Insights are enabled | `bool` | `false` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | The ARN for the KMS key to encrypt Performance Insights data | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | The amount of time in days to retain Performance Insights data. Valid values are `7`, `731` (2 years) or a multiple of `31` | `number` | `7` | no |
| <a name="input_port"></a> [port](#input\_port) | The port on which the DB accepts connections | `string` | `null` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Bool to control if instance is publicly accessible | `bool` | `false` | no |
| <a name="input_putin_khuylo"></a> [putin\_khuylo](#input\_putin\_khuylo) | Do you agree that Putin doesn't respect Ukrainian sovereignty and territorial integrity? More info: https://en.wikipedia.org/wiki/Putin_khuylo! | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where this resource will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_replica_mode"></a> [replica\_mode](#input\_replica\_mode) | Specifies whether the replica is in either mounted or open-read-only mode. This attribute is only supported by Oracle instances. Oracle replicas operate in open-read-only mode unless otherwise specified | `string` | `null` | no |
| <a name="input_replicate_source_db"></a> [replicate\_source\_db](#input\_replicate\_source\_db) | Specifies that this resource is a Replicate database, and to use this value as the source database. This correlates to the identifier of another Amazon RDS Database to replicate | `string` | `null` | no |
| <a name="input_restore_to_point_in_time"></a> [restore\_to\_point\_in\_time](#input\_restore\_to\_point\_in\_time) | Restore to a point in time (MySQL is NOT supported) | <pre>object({<br/>    restore_time                             = optional(string)<br/>    source_db_instance_automated_backups_arn = optional(string)<br/>    source_db_instance_identifier            = optional(string)<br/>    source_dbi_resource_id                   = optional(string)<br/>    use_latest_restorable_time               = optional(bool)<br/>  })</pre> | `null` | no |
| <a name="input_s3_import"></a> [s3\_import](#input\_s3\_import) | Restore from a Percona Xtrabackup in S3 (only MySQL is supported) | <pre>object({<br/>    source_engine_version = string<br/>    bucket_name           = string<br/>    bucket_prefix         = optional(string)<br/>    ingestion_role        = string<br/>  })</pre> | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted | `bool` | `false` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05 | `string` | `null` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Specifies whether the DB instance is encrypted | `bool` | `true` | no |
| <a name="input_storage_throughput"></a> [storage\_throughput](#input\_storage\_throughput) | Storage throughput value for the DB instance. See `notes` for limitations regarding this variable for `gp3` | `number` | `null` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (new generation of general purpose SSD), or 'io1' (provisioned IOPS SSD). The default is 'io1' if iops is specified, 'gp2' if not. If you specify 'io1' or 'gp3' , you must also include a value for the 'iops' parameter | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of VPC subnet IDs | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Updated Terraform resource management timeouts. Applies to `aws_db_instance` in particular to permit resource management times | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security groups to associate | `list(string)` | `[]` | no |


## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_instance_address"></a> [db\_instance\_address](#output\_db\_instance\_address) | The address of the RDS instance |
| <a name="output_db_instance_arn"></a> [db\_instance\_arn](#output\_db\_instance\_arn) | The ARN of the RDS instance |
| <a name="output_db_instance_availability_zone"></a> [db\_instance\_availability\_zone](#output\_db\_instance\_availability\_zone) | The availability zone of the RDS instance |
| <a name="output_db_instance_cloudwatch_log_groups"></a> [db\_instance\_cloudwatch\_log\_groups](#output\_db\_instance\_cloudwatch\_log\_groups) | Map of CloudWatch log groups created and their attributes |
| <a name="output_db_instance_domain"></a> [db\_instance\_domain](#output\_db\_instance\_domain) | The ID of the Directory Service Active Directory domain the instance is joined to |
(#output\_db\_instance\_domain\_iam\_role\_name) | The name of the IAM role to be used when making API calls to the Directory Service |
| <a name="output_db_instance_domain_ou"></a> [db\_instance\_domain\_ou](#output\_db\_instance\_domain\_ou) | The self managed Active Directory organizational unit for your DB instance to join |
| <a name="output_db_instance_endpoint"></a> [db\_instance\_endpoint](#output\_db\_instance\_endpoint) | The connection endpoint |
| <a name="output_db_instance_engine"></a> [db\_instance\_engine](#output\_db\_instance\_engine) | The database engine |
| <a name="output_db_instance_engine_version_actual"></a> [db\_instance\_engine\_version\_actual](#output\_db\_instance\_engine\_version\_actual) | The running version of the database |
| <a name="output_db_instance_hosted_zone_id"></a> [db\_instance\_hosted\_zone\_id](#output\_db\_instance\_hosted\_zone\_id) | The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record) |
| <a name="output_db_instance_identifier"></a> [db\_instance\_identifier](#output\_db\_instance\_identifier) | The RDS instance identifier |
| <a name="output_db_instance_master_user_secret_arn"></a> [db\_instance\_master\_user\_secret\_arn](#output\_db\_instance\_master\_user\_secret\_arn) | The ARN of the master user secret (Only available when manage\_master\_user\_password is set to true) |
| <a name="output_db_instance_name"></a> [db\_instance\_name](#output\_db\_instance\_name) | The database name |
| <a name="output_db_instance_port"></a> [db\_instance\_port](#output\_db\_instance\_port) | The database port |
| <a name="output_db_instance_resource_id"></a> [db\_instance\_resource\_id](#output\_db\_instance\_resource\_id) | The RDS Resource ID of this instance |
| <a name="output_db_instance_role_associations"></a> [db\_instance\_role\_associations](#output\_db\_instance\_role\_associations) | A map of DB Instance Identifiers and IAM Role ARNs separated by a comma |
(#output\_db\_instance\_secretsmanager\_secret\_rotation\_enabled) | Specifies whether automatic rotation is enabled for the secret |
| <a name="output_db_instance_status"></a> [db\_instance\_status](#output\_db\_instance\_status) | The RDS instance status |
(#output\_db\_instance\_upgrade\_rollout\_order) | Order in which the instances are upgraded (first, second, last) |
| <a name="output_db_instance_username"></a> [db\_instance\_username](#output\_db\_instance\_username) | The master username for the database |
| <a name="output_db_option_group_arn"></a> [db\_option\_group\_arn](#output\_db\_option\_group\_arn) | The ARN of the db option group |
| <a name="output_db_option_group_id"></a> [db\_option\_group\_id](#output\_db\_option\_group\_id) | The db option group id |
| <a name="output_db_parameter_group_arn"></a> [db\_parameter\_group\_arn](#output\_db\_parameter\_group\_arn) | The ARN of the db parameter group |
| <a name="output_db_parameter_group_id"></a> [db\_parameter\_group\_id](#output\_db\_parameter\_group\_id) | The db parameter group id |
| <a name="output_db_subnet_group_arn"></a> [db\_subnet\_group\_arn](#output\_db\_subnet\_group\_arn) | The ARN of the db subnet group |
| <a name="output_db_subnet_group_id"></a> [db\_subnet\_group\_id](#output\_db\_subnet\_group\_id) | The db subnet group name |
| <a name="output_enhanced_monitoring_iam_role_arn"></a> [enhanced\_monitoring\_iam\_role\_arn](#output\_enhanced\_monitoring\_iam\_role\_arn) | The Amazon Resource Name (ARN) specifying the monitoring role |
| <a name="output_enhanced_monitoring_iam_role_name"></a> [enhanced\_monitoring\_iam\_role\_name](#output\_enhanced\_monitoring\_iam\_role\_name) | The name of the monitoring role |

## Troubleshooting

### Common Issues

**Issue**: Storage full

- **Solution**: Enable storage autoscaling
- **Monitor**: Free storage alarm

**Issue**: High CPU

- **Solution**: Upgrade instance class
- **Monitor**: CPU utilization alarm

**Issue**: Connection errors

- **Solution**: Check security groups
- **Verify**: VPC routing, NACLs

**Issue**: Slow queries

- **Solution**: Review Performance Insights
- **Enable**: SQL tracing
