data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

/*data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["my-prod-vpc"]
  }
}*/

data "aws_vpc" "default" {
  default = true
}

/*data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}*/

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_iam_role" "existing" {
  name = "AWSServiceRoleForRDS"
}

/*data "aws_secretsmanager_secret" "rds" {
  name = "prod/postgres/rds"
}

data "aws_secretsmanager_secret_version" "rds" {
  secret_id = data.aws_secretsmanager_secret.rds.id
}*/

/*data "aws_kms_key" "by_id" {
  key_id = "example-" # KMS key associated with the CEV
}*/

/*locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds.secret_string)
}*/

module "postgress_db" {
  source = "../../modules"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  deployment_mode = "postgres" // specify the deployment mode, either "postgres" for postgres SE2 or "sqlserver" for SQL Server. This will determine the supported engine versions, parameter groups, and options available for the RDS instance.
  environment     = "prod"
  project         = "my-rds-postgres-project"
  name            = "myims-db"

  vpc_security_group_ids = ["sg-0a0368d327c6a80ea"] //attch all user-provided sg, if needed along with sg cretaed by this module.
  //[module.security_groups.db_sg.id] 

  # DB Parameter Group settings
  create_db_parameter_group = true
  db_parameter_group_family = "postgres17"

  db_parameter = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]

  # Option Group settings
  create_db_option_group = false
  major_engine_version   = 17

  # IAM Role settings
  enable_enhanced_monitoring = true
  monitoring_interval        = 60 // specify the interval, in seconds, between enhanced monitoring metrics collection. Valid values are 0 (disabled), 1, 5, 10, 15, 30, and 60. The default is 60.
  rds_iam_roles = [
    {
      role_arn     = data.aws_iam_role.existing.arn // example, replace with actual role ARN
      feature_name = "EC2_INTEGRATION"              # example
    }
  ]

  # RDS instance settings
  identifier                 = "my-ims-db-instance"
  db_name                    = "IMSDB"
  engine                     = "postgres"
  engine_version             = "17"
  instance_class             = "db.t4g.large"
  storage_type               = "gp3"
  allocated_storage          = 200
  max_allocated_storage      = 500
  storage_encrypted          = true
  storage_throughput         = 1000
  iops                       = 100
  license_model              = "postgresql-license"
  publicly_accessible        = false
  auto_minor_version_upgrade = false
  enable_storage_autoscaling = true
  //username = local.rds_secret.username //No need to pass the username and password as variables, if manage_master_user_password is true 
  //password = local.rds_secret.password

  manage_master_user_password = true
  master_username             = "adminuser"
  //aws_db_instance.postgres.master_user_secret[0].secret_arn

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:23:00-Mon:01:00"
  deletion_protection     = true
  skip_final_snapshot     = false
  apply_immediately       = false


  //kms_key_id                  = data.aws_kms_key.by_id.id
  //port = 1521
  multi_az = true

  performance_insights_enabled          = false
  performance_insights_retention_period = 7 // specify the retention period for Performance Insights data in days, or set to -1 for indefinite retention  

  # CloudWatch Logs settings
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["postgresql", "upgrade"] 
  cloudwatch_log_group_retention_in_days = 14                                      // specify the retention period for the CloudWatch log groups in days
  cloudwatch_log_group_kms_key_id        = "data.aws_kms_key.by_id"                // provide the KMS key ID to encrypt the CloudWatch log groups, if needed
  cloudwatch_log_group_skip_destroy      = false                                   // set to true to prevent the CloudWatch log groups from being destroyed when the RDS instance is deleted
  cloudwatch_log_group_class             = "STANDARD"                              // specify the CloudWatch log group class, either STANDARD or INFREQUENT_ACCESS. The default is STANDARD. Note that using INFREQUENT_ACCESS may result in additional costs, refer to AWS documentation for pricing details.
  region                                 = "eu-west-1"
  cloudwatch_log_group_tags = {

  }
  # backup replication settings
  create_replication     = false
  source_db_instance_arn = "" // provide the ARN of the source DB instance to replicate from, if create_replication is true
  kms_key_arn            = "" // provide the ARN of the KMS key to encrypt the replicated backup, if create_replication is true
  pre_signed_url         = "" // provide a pre-signed URL for the replication, if create_replication is true. This is required for cross-region replication.
  replica_region         = "" // provide the region where the replica will be created, if create_replication is true and source and replica are in different regions.
  retention_period       = 7

  # Required Tags
  required_tags = {
    CostCenter = "Engineering"
    Team       = "Database"
    Compliance = "SOC2"
  }

  tags = var.tags

}

