
variable "deployment_mode" {
  description = "The deployment mode for the database (e.g., 'oracle', 'sqlserver-se' or 'instance'.)"
  type        = string

}

variable "environment" {
  description = "The environment for the deployment (e.g., 'dev', 'prod')"
  type        = string

}

variable "project" {
  description = "The project name for tagging purposes"
  type        = string

}

variable "name" {
  description = "The name prefix for resources"
  type        = string

}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the DB instance"
  type        = list(string)
}


variable "engine" {
  description = "The database engine to use for the RDS instance (e.g., oracle-se, sqlserver-se)"
  type        = string

}

variable "license_model" {
  description = "The license model for the DB instance (e.g., 'license-included', 'bring-your-own-license')"
  type        = string

}

variable "allocated_storage" {
  description = "The allocated storage size for the DB instance (in GB)"
  type        = number
}

variable "max_allocated_storage" {
  description = "The maximum allocated storage size for the DB instance (in GB)"
  type        = number

}

variable "create_db_parameter_group" {
  description = "Flag to determine whether to create a DB parameter group"
  type        = bool

}

variable "create_db_option_group" {
  description = "Flag to determine whether to create a DB option group"
  type        = bool
}

variable "backup_retention_period" {
  description = "The number of days to retain backups for the DB instance"
  type        = number
}

variable "db_parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null
}

variable "major_engine_version" {
  description = "The major engine version for the option group"
  type        = string
  default     = null
}

# RDS Instance Variables

variable "identifier" {
  description = "Name of the RDS instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = null

}
variable "instance_class" {
  description = "The instance class for the DB instance (e.g., 'db.m5.large')"
  type        = string

}

variable "engine_version" {
  description = "Version of the engine to be used"
  type        = string

}

variable "enable_storage_autoscaling" {
  description = "Enable storage autoscaling"
  type        = bool
  default     = null
}

variable "storage_type" {
  description = "The storage type for the DB instance (e.g., 'gp2', 'gp3', io1')"
  type        = string

}

variable "iops" {
  description = "The number of IOPS to provision for the DB instance (required if storage_type is 'io1')"
  type        = number
  default     = null

}

# Enhanced monitoring Variables

variable "enable_enhanced_monitoring" {
  description = "Enable monitoring for RDS instance "
  type = bool
  default = null
  
}

variable "rds_iam_roles" {
  description = "IAM roles to associate with the RDS instance"
  type = list(object({
    role_arn     = string
    feature_name = string
  }))
  default = []

}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "RDS-Oracle"
    Owner     = "Platform-Team"
  }
}