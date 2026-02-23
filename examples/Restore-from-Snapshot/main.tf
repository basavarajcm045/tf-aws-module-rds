data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

data "aws_db_snapshot" "latest" {
  db_instance_identifier = "prod-oracle"
  most_recent            = true
}

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

/*data "aws_kms_key" "by_id" {
  key_id = "example-" # KMS key associated with the CEV
}*/

module "restore" {
  source = "../../modules"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  deployment_mode = "oracle" // specify the deployment mode, either "oracle" for Oracle SE2 or "sqlserver" for SQL Server. This will determine the supported engine versions, parameter groups, and options available for the RDS instance.
  environment     = "prod"
  project         = "my-rds-oracle-project"
  name            = "myims-db"

  db_subnet_group_name   = "${var.name}-subnet-group" // specify the name of the DB subnet group to use for the RDS instance. The DB subnet group must be created in advance and should include the subnets specified in the subnet_ids variable.
  parameter_group_name   = "${var.name}-pg"
  option_group_name      = "${var.name}-og"
  vpc_security_group_ids = ["sg-0a0368d327c6a80ea"] 

  # Restore from snapshot
  //snapshot_identifier = "arn:aws:rds:us-east-1:123456789012:snapshot:myapp-snapshot-2024-01-15"
  snapshot_identifier = data.aws_db_snapshot.latest.id

  # RDS instance settings
  identifier        = "my-ims-db-instance"
  db_name           = "IMSDB"
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  storage_type      = var.storage_type
  allocated_storage = var.allocated_storage
  license_model     = var.license_model
  
  storage_encrypted     = true
  publicly_accessible   = false
  max_allocated_storage = var.max_allocated_storage
  copy_tags_to_snapshot = true

  major_engine_version    = var.major_engine_version
  backup_retention_period = var.backup_retention_period
  deletion_protection     = true
  skip_final_snapshot     = false
  
  create_db_parameter_group   = var.create_db_parameter_group
  create_db_option_group      = var.create_db_option_group
  manage_master_user_password = true
  db_parameter_group_family   = var.db_parameter_group_family
//=============
  performance_insights_enabled          = true
  performance_insights_retention_period = 7 // specify the retention period for Performance Insights data in days, or set to -1 for indefinite retention  

  # Required Tags
  required_tags = {
    CostCenter = "Engineering"
    Team       = "Database"
    Compliance = "SOC2"
  }

  tags = var.tags

}

