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

data "aws_rds_orderable_db_instance" "custom-oracle" {
  engine                     = "oracle-se2"
  engine_version             = "19.0.0.0.ru-2025-10.rur-2025-10.r1" # CEV engine version to be used
  license_model              = "license-included"
  storage_type               = "gp2"
  preferred_instance_classes = ["db.m5.large", "db.r5.xlarge", "db.r5.2xlarge", "db.r5.4xlarge"]
}

/*data "aws_kms_key" "by_id" {
  key_id = "example-" # KMS key associated with the CEV
}*/

module "restore" {
  source = "../modules"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  deployment_mode = "oracle" // specify the deployment mode, either "oracle" for Oracle SE2 or "sqlserver" for SQL Server. This will determine the supported engine versions, parameter groups, and options available for the RDS instance.
  environment     = "production"
  project         = "my-rds-oracle-project"
  name            = "myims-db"

  vpc_security_group_ids = ["sg-0a0368d327c6a80ea"] //attch all user-provided sg, if needed along with sg cretaed by this module.
  //[module.security_groups.db_sg.id] 
  
  # Restore from snapshot
  snapshot_identifier = "arn:aws:rds:us-east-1:123456789012:snapshot:myapp-snapshot-2024-01-15"


  # RDS instance settings
  identifier            = "my-ims-db-instance"
  db_name               = "IMSDB"
  engine                = data.aws_rds_orderable_db_instance.custom-oracle.engine
  engine_version        = data.aws_rds_orderable_db_instance.custom-oracle.engine_version
  instance_class        = data.aws_rds_orderable_db_instance.custom-oracle.preferred_instance_classes[0]
  //storage_type          = data.aws_rds_orderable_db_instance.custom-oracle.storage_type
  allocated_storage     = 20
  storage_encrypted     = true
  
  manage_master_user_password = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7 // specify the retention period for Performance Insights data in days, or set to -1 for indefinite retention  

  # CloudWatch Logs settings
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["alert", "audit", "listener", "trace"] // specify the log types to export to CloudWatch Logs, refer to AWS documentation for supported log types for Oracle SE2.
  cloudwatch_log_group_retention_in_days = 14                                      // specify the retention period for the CloudWatch log groups in days
  cloudwatch_log_group_kms_key_id        = ""                                      // provide the KMS key ID to encrypt the CloudWatch log groups, if needed
  cloudwatch_log_group_skip_destroy      = false                                   // set to true to prevent the CloudWatch log groups from being destroyed when the RDS instance is deleted
  cloudwatch_log_group_class             = "STANDARD"                              // specify the CloudWatch log group class, either STANDARD or INFREQUENT_ACCESS. The default is STANDARD. Note that using INFREQUENT_ACCESS may result in additional costs, refer to AWS documentation for pricing details.
  region                                 = "eu-west-1"

  # Required Tags
  required_tags = {
    CostCenter = "Engineering"
    Team       = "Database"
    Compliance = "SOC2"
  }

  tags = var.tags

}

