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

module "oracle_db" {
  source = "../modules"

  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

  deployment_mode = "oracle" // specify the deployment mode, either "oracle" for Oracle SE2 or "sqlserver" for SQL Server. This will determine the supported engine versions, parameter groups, and options available for the RDS instance.
  environment     = "dev"
  project         = "my-rds-oracle-project"
  name            = "myims-db"

  vpc_security_group_ids = ["sg-0a0368d327c6a80ea"] //attch all user-provided sg, if needed along with sg cretaed by this module.
  //[module.security_groups.db_sg.id] 

  # DB Parameter Group settings
  create_db_parameter_group = true
  db_parameter_group_family = "oracle-se2-19"

  db_parameter = [
    {
      name         = "processes"
      value        = "300"
      apply_method = "pending-reboot" //"immediate", pending-reboot, //static parameters require reboot, dynamic parameters can be applied immediately.
    }

  ]

  # Option Group settings
  create_db_option_group = false
  major_engine_version   = 19

  // Add more options as needed, refer to AWS documentation for supported options and settings for Oracle SE2.
  // Note: Some options may require additional permissions or configurations, such as IAM roles for S3 integration or SMTP settings for UTL_MAIL. Ensure to review the AWS documentation for each option you intend to use and provide the necessary settings accordingly.
  /*db_option = [
    {
      option_name = "OEM"
      option_settings = [
        {
          name  = "PORT"
          value = "5500"
        }
      ]
    }*/ //,
  /*{
      option_name = "S3_INTEGRATION"
      option_settings = [
        {
          name  = "IAM_ROLE_ARN"
          value = "arn:aws:iam::123456789012:role/my-s3-integration-role"
        }
      ]
    },*/
  /*{
      option_name = "UTL_MAIL"
        option_settings = [
          {
            name  = "SMTP_HOST"
            value = "smtp.example.com"
          },
          {
            name  = "SMTP_PORT"
            value = "587"
          },
          {
            name  = "SMTP_USERNAME"
            value = "smtp_user"
          },
          {
            name  = "SMTP_PASSWORD"
            value = "smtp_password"
          }
        ]
    }*/
  //]

  # IAM Role settings

  rds_iam_roles = [
    {
      role_arn     = data.aws_iam_role.existing.arn // example, replace with actual role ARN
      feature_name = "EC2_INTEGRATION"              # example
    }
  ]

  # RDS instance settings
  identifier            = "my-ims-db-instance"
  db_name               = "IMSDB"
  engine                = data.aws_rds_orderable_db_instance.custom-oracle.engine
  engine_version        = data.aws_rds_orderable_db_instance.custom-oracle.engine_version
  instance_class        = data.aws_rds_orderable_db_instance.custom-oracle.preferred_instance_classes[0]
  storage_type          = data.aws_rds_orderable_db_instance.custom-oracle.storage_type
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  storage_throughput    = 1000

  license_model              = data.aws_rds_orderable_db_instance.custom-oracle.license_model
  publicly_accessible        = false
  auto_minor_version_upgrade = false

  manage_master_user_password = true
  master_username             = "adminuser"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Sun:23:00-Mon:01:00"
  deletion_protection     = true
  skip_final_snapshot     = true
  apply_immediately       = false


  //kms_key_id                  = data.aws_kms_key.by_id.id
  //port = 1521
  multi_az = true

  performance_insights_enabled          = false
  performance_insights_retention_period = 7 // specify the retention period for Performance Insights data in days, or set to -1 for indefinite retention  

  # CloudWatch Logs settings
  create_cloudwatch_log_group            = true
  enabled_cloudwatch_logs_exports        = ["alert", "audit", "listener", "trace"] // specify the log types to export to CloudWatch Logs, refer to AWS documentation for supported log types for Oracle SE2.
  cloudwatch_log_group_retention_in_days = 14                                      // specify the retention period for the CloudWatch log groups in days
  cloudwatch_log_group_kms_key_id        = ""                                      // provide the KMS key ID to encrypt the CloudWatch log groups, if needed
  cloudwatch_log_group_skip_destroy      = false                                   // set to true to prevent the CloudWatch log groups from being destroyed when the RDS instance is deleted
  cloudwatch_log_group_class             = "STANDARD"                              // specify the CloudWatch log group class, either STANDARD or INFREQUENT_ACCESS. The default is STANDARD. Note that using INFREQUENT_ACCESS may result in additional costs, refer to AWS documentation for pricing details.
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

