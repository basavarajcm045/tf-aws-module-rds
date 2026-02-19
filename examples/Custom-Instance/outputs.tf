# Oracle Outputs
output "db_endpoint" {
  description = "Production Oracle database endpoint"
  value       = module.oracle_db.db_instance_endpoint
}

/*output "db_connection_string" {
  description = "Production Oracle JDBC connection string"
  value       = module.oracle_db.db_connection_string
}*/

/*output "db_secret_arn" {
  description = "Production database credentials secret ARN"
  value       = module.oracle_db.db_credentials_secret_arn
}*/

output "db_instance_id" {
  description = "Production database instance ID"
  value       = module.oracle_db.db_instance_id
}

output "db_arn" {
  description = "Production database ARN"
  value       = module.oracle_db.db_instance_arn
}