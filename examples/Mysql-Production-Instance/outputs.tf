# Oracle Outputs
output "db_endpoint" {
  description = "Production Oracle database endpoint"
  value       = module.mysql_db.db_instance_endpoint
}

output "db_instance_id" {
  description = "Production database instance ID"
  value       = module.mysql_db.db_instance_id
}

output "db_arn" {
  description = "Production database ARN"
  value       = module.mysql_db.db_instance_arn
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = module.mysql_db.db_instance_address
}

output "db_instance_port" {
  description = "The database port"
  value       = module.mysql_db.db_instance_port
}

output "db_instance_availability_zone" {
  description = "The availability zone of the instance"
  value       = module.mysql_db.db_instance_availability_zone
}

output "db_instance_multi_az" {
  description = "If the RDS instance is multi AZ enabled"
  value       = module.mysql_db.db_instance_availability_zone
}

# Database Information
output "db_instance_name" {
  description = "The database name"
  value       = module.mysql_db.db_instance_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = module.mysql_db.db_instance_username
  sensitive   = true
}

output "db_instance_engine_version" {
  description = "The database engine version"
  value       = module.mysql_db.db_instance_engine_version
}

/*output "db_connection_string" {
  description = "Production Oracle JDBC connection string"
  value       = module.mysql_db.db_connection_string
}*/

/*output "db_secret_arn" {
  description = "Production database credentials secret ARN"
  value       = module.mysql_db.db_credentials_secret_arn
}*/