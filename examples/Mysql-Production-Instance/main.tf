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

/*data "aws_kms_key" "by_id" {
  key_id = "example-" # KMS key associated with the CEV
}*/

module "mysql_db" {
  source = "../../modules"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  deployment_mode = "mysql" 
  environment     = "prod"
  project         = "my-rds-mysql-project"
  name            = "myims-db"

  vpc_security_group_ids = ["sg-0a0368d327c6a80ea"] //attch all user-provided sg, if needed along with sg cretaed by this module.
  //[module.security_groups.db_sg.id] 

  # DB Parameter Group settings
  create_db_parameter_group = true
  db_parameter_group_family = "mysql8.4"

  db_parameter = [
    {
      name         = "slow_query_log"
      value        = "1"
      apply_method = "pending-reboot" //"immediate", pending-reboot, //static parameters require reboot, dynamic parameters can be applied immediately.
    },

    {
      name         = "long_query_time"
      value        = "2"
      apply_method = "pending-reboot"
    }
  ]

  # Option Group settings
  create_db_option_group = false
  major_engine_version   = 8.0

  enable_enhanced_monitoring = false
  
  # RDS instance settings
  identifier            = "my-ims-db-instance"
  db_name               = "IMSDB"
  engine                = "mysql"
  engine_version        = "8.4.7"
  instance_class        = "db.m6i.large"
  storage_type          = "gp3"
  allocated_storage     = 20
  max_allocated_storage = 100
  //storage_encrypted     = true
  storage_throughput = 100
  iops               = 1000


  license_model = "license-included"
  //publicly_accessible        = false
  //auto_minor_version_upgrade = false

  manage_master_user_password = true
  master_username             = "adminuser"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:23:00-Mon:01:00"
  deletion_protection     = true
  skip_final_snapshot     = false
  apply_immediately       = false


  //kms_key_id                  = data.aws_kms_key.by_id.id
  //port = 1521
  multi_az = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # CloudWatch Logs settings
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["general"] // specify the log types to export to CloudWatch Logs, refer to AWS documentation for supported log types for Mysql.
  cloudwatch_log_group_retention_in_days = 14          // specify the retention period for the CloudWatch log groups in days
  cloudwatch_log_group_kms_key_id        = ""          // provide the KMS key ID to encrypt the CloudWatch log groups, if needed
  cloudwatch_log_group_skip_destroy      = false       // set to true to prevent the CloudWatch log groups from being destroyed when the RDS instance is deleted
  cloudwatch_log_group_class             = "STANDARD"  // specify the CloudWatch log group class, either STANDARD or INFREQUENT_ACCESS. The default is STANDARD. Note that using INFREQUENT_ACCESS may result in additional costs, refer to AWS documentation for pricing details.
  region                                 = "eu-west-1"

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

