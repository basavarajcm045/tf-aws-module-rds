# RDS Instance Outputs 
output "db_instance_id" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.this[*].id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this[*].arn
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.this[*].endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = aws_db_instance.this[*].address
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this[*].port
}

output "db_instance_availability_zone" {
  description = "The availability zone of the instance"
  value       = aws_db_instance.this[*].availability_zone
}

output "db_instance_multi_az" {
  description = "If the RDS instance is multi AZ enabled"
  value       = aws_db_instance.this[*].multi_az
}

# Database Information
output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this[*].db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this[*].username
  sensitive   = true
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.this[*].engine
}

output "db_instance_engine_version" {
  description = "The database engine version"
  value       = aws_db_instance.this[*].engine_version
}

output "db_instance_license_model" {
  description = "The license model of the instance"
  value       = aws_db_instance.this[*].license_model
}

output "db_instance_character_set_name" {
  description = "The character set name"
  value       = aws_db_instance.this[*].character_set_name
}

# Storage Information
output "db_instance_allocated_storage" {
  description = "The amount of allocated storage in gigabytes"
  value       = aws_db_instance.this[*].allocated_storage
}

output "db_instance_storage_type" {
  description = "The storage type"
  value       = aws_db_instance.this[*].storage_type
}

output "db_instance_storage_encrypted" {
  description = "Whether the DB instance is encrypted"
  value       = aws_db_instance.this[*].storage_encrypted
}

output "db_instance_kms_key_id" {
  description = "The KMS key ID used for encryption"
  value       = aws_db_instance.this[*].kms_key_id
}

output "db_instance_iops" {
  description = "The provisioned IOPS (if applicable)"
  value       = aws_db_instance.this[*].iops
}

# Network Information
output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance"
  value       = aws_db_instance.this[*].hosted_zone_id
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_instance.this[*].db_subnet_group_name
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = try(aws_db_subnet_group.default[*][0].arn, null)
}

output "db_instance_vpc_security_groups" {
  description = "The VPC security group IDs"
  value       = aws_db_instance.this[*].vpc_security_group_ids
}

# Parameter and Option Groups
output "db_parameter_group_id" {
  description = "The db parameter group name"
  value       = aws_db_instance.this[*].parameter_group_name
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = try(aws_db_parameter_group.this[*][0].arn, null)
}

output "db_option_group_id" {
  description = "The db option group name"
  value       = aws_db_instance.this[*].option_group_name
}

output "db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = try(aws_db_option_group.this[*][0].arn, null)
}

# Backup and Maintenance
output "db_instance_backup_retention_period" {
  description = "The backup retention period"
  value       = aws_db_instance.this[*].backup_retention_period
}

output "db_instance_backup_window" {
  description = "The backup window"
  value       = aws_db_instance.this[*].backup_window
}

output "db_instance_maintenance_window" {
  description = "The maintenance window"
  value       = aws_db_instance.this[*].maintenance_window
}

output "db_instance_latest_restorable_time" {
  description = "The latest time to which a database can be restored with point-in-time restore"
  value       = aws_db_instance.this[*].latest_restorable_time
}

# Monitoring
output "db_instance_performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_db_instance.this[*].performance_insights_enabled
}

output "db_instance_performance_insights_retention_period" {
  description = "Performance Insights retention period"
  value       = aws_db_instance.this[*].performance_insights_retention_period
}

output "db_instance_cloudwatch_log_groups" {
  description = "List of CloudWatch log groups for the database logs"
  value       = aws_db_instance.this[*].enabled_cloudwatch_logs_exports
}

# Secrets Manager

# KMS Keys
/*output "rds_kms_key_id" {
  description = "The KMS key ID for RDS encryption"
  value       = try(aws_kms_key.rds[0].id, var.kms_key_id)
}*/

/*output "rds_kms_key_arn" {
  description = "The KMS key ARN for RDS encryption"
  value       = try(aws_kms_key.rds[0].arn, var.kms_key_id)
}*/


# Status Information
output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.this[*].status
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this[*] instance"
  value       = aws_db_instance.this[*].resource_id
}

output "db_instance_deletion_protection" {
  description = "Whether deletion protection is enabled"
  value       = aws_db_instance.this[*].deletion_protection
}

# Connection String Output (Formatted)
/*output "db_connection_string" {
  description = "Database connection string (without password)"
  value       = "jdbc:oracle:thin:@${aws_db_instance.this[*].address}:${aws_db_instance.this[*].port}:${coalesce(aws_db_instance.this[*].db_name, "ORCL")}"
}*/

# Complete Instance Object
output "db_instance" {
  description = "Complete RDS instance object"
  value       = aws_db_instance.this[*]
  sensitive   = true
}

# Useful Information for Applications
/*output "db_connection_info" {
  description = "Database connection information for application configuration"
  value = {
    endpoint          = aws_db_instance.this[*].endpoint
    address           = aws_db_instance.this[*].address
    port              = aws_db_instance.this[*].port
    database_name     = aws_db_instance.this[*].db_name
    username          = aws_db_instance.this[*].username
    secret_arn        = try(aws_secretsmanager_secret.db_credentials[0].arn, null)
    connection_string = "jdbc:oracle:thin:@${aws_db_instance.this[*].address}:${aws_db_instance.this[*].port}:${coalesce(aws_db_instance.this[*].db_name, "ORCL")}"
  }
  sensitive = true
}*/