
variable "create_db_instance" {
  description = "Flag to determine whether to create a DB instance"
  type        = bool
  default     = true

}

variable "deployment_mode" {
  description = "The deployment mode for the database (e.g., 'oracle', 'sqlserver-se' or 'instance'.)"
  type        = string

  validation {
    condition     = contains(["oracle", "sqlserver-se", "instance"], var.deployment_mode)
    error_message = "deployment_mode must be one of 'oracle', 'sqlserver-se', or 'instance'."
  }

}

variable "environment" {
  description = "The environment for the deployment (e.g., 'dev', 'prod')"
  type        = string

  validation {
    condition     = contains(["dev", "tst", "ppe", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod"
  }
}

variable "project" {
  description = "The project name for tagging purposes"
  type        = string

  validation {
    condition     = length(var.project) > 0
    error_message = "project cannot be empty."
  }
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "vpc_id must be a valid VPC ID (e.g., vpc-xxxxxxxx)."
  }
}

variable "name" {
  description = "The name prefix for resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, numbers and hyphens."
  }
}

# Subnet group Variables
variable "subnet_ids" {
  description = "A list of subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet_ids must be provided for high availability."
  }
}

// keep null to create a subnet group with a generated name, or provide a name to use an existing subnet group
variable "db_subnet_group_name" {
  description = "The name of the DB subnet group to associate with the DB instance"
  type        = string
  default     = null
}

//attch all user-provided sg
variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the DB instance"
  type        = list(string)

  validation {
    condition     = length(var.vpc_security_group_ids) > 0
    error_message = "At least one security group must be provided for RDS."
  }

}

#  DB Parameter Group Variables
variable "create_db_parameter_group" {
  description = "Flag to determine whether to create a DB parameter group"
  type        = bool

}

variable "db_parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[a-z0-9-]+[0-9.]*$", var.db_parameter_group_family))
    error_message = "db_parameter_group_family must follow AWS format (e.g., mysql8.0, postgres15, oracle-se2-19)."
  }
}

variable "db_parameter" {
  description = "A map of DB parameters to set in the parameter group: name, value, apply_method"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = null

}

//provide a name to use an existing parameter group.
// keep null to create a parameter group with a generated name, or provide a name to use an existing parameter group
variable "db_parameter_group_name" {
  description = "The name of the DB parameter group to associate with the DB instance"
  type        = string
  default     = null

}

#Option Group Variables
variable "create_db_option_group" {
  description = "Flag to determine whether to create a DB option group"
  type        = bool
}

// keep null to create a option group with a generated name, or provide a name to use an existing option group
variable "db_option_group_name" {
  description = "The name of the DB option group to associate with the DB instance"
  type        = string
  default     = null

}

variable "engine" {
  description = "The database engine name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.engine))
    error_message = "engine must contain only lowercase letters, numbers, and hyphens (e.g., mysql, postgres, oracle-se2, aurora-mysql)."
  }
}

variable "major_engine_version" {
  description = "The major engine version for the option group"
  type        = string
  default     = null

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)*$", var.major_engine_version))
    error_message = "major_engine_version must be numeric and dot-separated (e.g., 8.0, 13.7, 15, 19, 15.00)."
  }
}

variable "db_option" {
  description = "A map of DB options to set in the option group: option_name, option_settings"
  type = list(object({
    option_name = string
    option_settings = optional(list(object({
      name  = string
      value = string

    })))
  }))
  default = null
}

# Enhanced monitoring Variables

variable "rds_iam_roles" {
  description = "IAM roles to associate with the RDS instance"
  type = list(object({
    role_arn     = string
    feature_name = string
  }))
  default = null

}

# RDS Instance Variables

variable "identifier" {
  description = "Name of the RDS instance"
  type        = string

  validation {
    condition = (
      length(var.identifier) >= 3 &&
      length(var.identifier) <= 63 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.identifier)) &&
      !can(regex("--", var.identifier))
    )

    error_message = "identifier must be 3-63 characters, start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, cannot end with a hyphen, and cannot contain consecutive hyphens."
  }
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string

  validation {
    condition = can(
      regex("^[A-Za-z][A-Za-z0-9]{0,6}$", var.db_name)
    )
    error_message = "Invalid db_name. It must start with a letter, less than 8 characters, and contain only alphanumeric characters."
  }

}
variable "instance_class" {
  description = "The instance class for the DB instance (e.g., 'db.m5.large')"
  type        = string

  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.instance_class))
    error_message = "instance_class must follow AWS format (e.g., db.m5.large, db.r6i.xlarge)."
  }
}

variable "engine_version" {
  description = "Version of the engine to be used"
  type        = string

  /*validation {
    condition = can(regex("^[0-9]+(\\.[0-9A-Za-z]+)*$", var.engine_version))
    error_message = "engine_version must be numeric and dot-separated (e.g., 8.0, 13.7, 19, 15.00.4236.7.v1)."
  }*/
}

variable "allocated_storage" {
  description = "The allocated storage size for the DB instance (in GB)"
  type        = number

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GB."
  }
}

variable "max_allocated_storage" {
  description = "The maximum allocated storage size for the DB instance (in GB)"
  type        = number

}

variable "enable_storage_autoscaling" {
  description = "Enable storage autoscaling"
  type        = bool
  default     = true
}

variable "storage_type" {
  description = "The storage type for the DB instance (e.g., 'gp2', 'gp3', io1')"
  type        = string

  validation {
    condition = contains(
      ["gp2", "gp3", "io1", "io2", "standard"], var.storage_type
    )

    error_message = "storage_type must be one of: gp2, gp3, io1, io2, standard."
  }

}

variable "iops" {
  description = "The number of IOPS to provision for the DB instance (required if storage_type is 'io1')"
  type        = number
  default     = 0

}

variable "storage_throughput" {
  description = "The storage throughput to provision for the DB instance (in MB/s, required if storage_type is 'gp3')"
  type        = number
  default     = 0

}

variable "license_model" {
  description = "The license model for the DB instance (e.g., 'license-included', 'bring-your-own-license')"
  type        = string

  validation {
    condition = (
      var.license_model == null ||
      contains([
        "license-included",
        "bring-your-own-license",
        "general-public-license"
      ], var.license_model)
    )

    error_message = "license_model must be one of: license-included, bring-your-own-license, general-public-license."
  }
}

variable "publicly_accessible" {
  description = "Specifies if the DB instance is publicly accessible"
  type        = bool
  default     = false

}

variable "auto_minor_version_upgrade" {
  description = "Specifies if minor version upgrades will be applied automatically to the DB instance"
  type        = bool
  default     = true

}

variable "storage_encrypted" {
  description = "Specifies if the DB instance storage is encrypted"
  type        = bool
  default     = true

}
variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = true

}

// if true, password is managed automatically by AWS  Secrets Manager, if false, password must be provided in master_password variable
variable "manage_master_user_password" {
  description = "Flag to determine whether to manage the master user password automatically (e.g., via AWS Secrets Manager)"
  type        = bool
  default     = true

}

variable "master_username" {
  description = "master username (required: password managed automatically if manage_master_user_password is true)"
  type        = string
  default     = "dbadmin"

}

variable "master_password" {
  description = "master password (ruse only if manage_master_user_password is false)"
  type        = string
  default     = null
  sensitive   = true

}

/*variable "port" {
  description = "The port number on which the DB instance accepts connections"
  type        = number
  default     = null // default ports are 1521 for Oracle and 1433 for SQL Server, set based on engine if null
  
}*/

variable "kms_key_id" {
  description = "The KMS key ID to use for encrypting the DB instance storage"
  type        = string
  default     = null

}

variable "backup_retention_period" {
  description = "The number of days to retain backups for the DB instance"
  type        = number

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "The preferred backup window for the DB instance (e.g., '03:00-04:00')"
  type        = string
  default     = null

  validation {
    condition = (
      var.backup_window == null ||
      can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]-([01][0-9]|2[0-3]):[0-5][0-9]$", var.backup_window))
    )
    error_message = "backup_window must be in 24-hour format HH:MM-HH:MM (e.g., 03:00-04:00)."
  }
}

variable "maintenance_window" {
  description = "The preferred maintenance window for the DB instance (e.g., 'Sun:05:00-Sun:06:00')"
  type        = string
  default     = null

  validation {
    condition = (
      var.maintenance_window == null ||
      can(regex(
        "^(Mon|Tue|Wed|Thu|Fri|Sat|Sun):([01][0-9]|2[0-3]):[0-5][0-9]-(Mon|Tue|Wed|Thu|Fri|Sat|Sun):([01][0-9]|2[0-3]):[0-5][0-9]$",
        var.maintenance_window
      ))
    )
    error_message = "maintenance_window must be in format Ddd:HH:MM-Ddd:HH:MM (e.g., Sun:05:00-Sun:06:00)."
  }

}

variable "monitoring_interval" {
  description = "The interval, in seconds, between enhanced monitoring metrics collection"
  type        = number
  default     = 60

}

// null to set based on environment. true for prod, false for dev/test, 
variable "deletion_protection" {
  description = "Specifies if deletion protection is enabled for the DB instance"
  type        = bool
  default     = null

}

// true for dev/test, false for prod, null to set based on environment
variable "skip_final_snapshot" {
  description = "Specifies if a final snapshot is skipped when the DB instance is deleted"
  type        = bool

}

variable "final_snapshot_identifier" {
  description = "The name of the final snapshot to create when the DB instance is deleted (required if skip_final_snapshot is false)"
  type        = string
  default     = null

}

variable "apply_immediately" {
  description = "Specifies whether to apply modifications immediately or during the next maintenance window"
  type        = bool
  default     = false

}

variable "db_instance_create_timeout" {
  description = "The timeout for creating the DB instance (in minutes)"
  type        = number
  default     = null

}

variable "db_instance_update_timeout" {
  description = "The timeout for updating the DB instance (in minutes)"
  type        = number
  default     = null

}

variable "db_instance_delete_timeout" {
  description = "The timeout for deleting the DB instance (in minutes)"
  type        = number
  default     = null

}

# automated backup replication variables

variable "create_replication" {
  description = "Flag to determine whether to create a read replica for the DB instance"
  type        = bool

}

variable "source_db_instance_arn" {
  description = "The ARN of the source DB instance to replicate (required if create_replication is true)"
  type        = string
  default     = null

}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for encrypting the read replica (required if create_replication is true)"
  type        = string
  default     = null

}

variable "pre_signed_url" {
  description = "The pre-signed URL for creating a read replica in another region (required if create_replication is true and source and replica are in different regions)"
  type        = string
  default     = null

}

variable "replica_region" {
  description = "The region where the read replica will be created (required if create_replication is true and source and replica are in different regions)"
  type        = string
  default     = null

}

variable "retention_period" {
  description = "The retention period for the read replica (in days, required if create_replication is true)"
  type        = number
  default     = null

}

variable "performance_insights_enabled" {
  description = "Flag to determine whether to enable Performance Insights for the DB instance"
  type        = bool

}

variable "performance_insights_retention_period" {
  description = "The retention period for the performance insights (in days, required if performance_insights_enabled is true)"
  type        = number
  default     = null
}

variable "performance_insights_kms_key_id" {
  description = "The KMS key ID to use for encrypting Performance Insights data"
  type        = string
  default     = null

}

# CloudWatch Logs export variables
variable "create_cloudwatch_log_group" {
  description = "Flag to determine whether to create a CloudWatch Log Group for RDS logs"
  type        = bool
  default     = false

}

variable "enabled_cloudwatch_logs_exports" {
  description = "A list of log types to export to CloudWatch Logs (e.g., 'error', 'general', 'slowquery')"
  type        = list(string)
  default     = null

  validation {
    condition = (
      var.enabled_cloudwatch_logs_exports == null ||
      alltrue([
        for log in var.enabled_cloudwatch_logs_exports :
        contains([
          "error",
          "general",
          "slowquery",
          "audit",
          "listener",
          "trace",
          "alert",
          "postgresql",
          "upgrade"
        ], log)
      ])
    )

    error_message = "enabled_cloudwatch_logs_exports contains unsupported log types."
  }
}

// 0 means retain indefinitely, set to a specific number of days to automatically delete logs after that period
variable "cloudwatch_log_group_retention_in_days" {
  description = "The retention period for the CloudWatch Log Group (in days)"
  type        = number
  default     = null
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The KMS key ID to use for encrypting the CloudWatch Log Group"
  type        = string
  default     = null

}

// true for dev/test to preserve logs, false for prod, null to set based on environment
variable "cloudwatch_log_group_skip_destroy" {
  description = "Flag to determine whether to skip destroying the CloudWatch Log Group when the RDS instance is deleted"
  type        = bool
  default     = null

}

variable "cloudwatch_log_group_class" {
  description = "The class of the CloudWatch Log Group resource (e.g., 'aws_cloudwatch_log_group')"
  type        = string
  default     = null

}

variable "region" {
  description = "The AWS region where the RDS instance will be created"
  type        = string
  default     = null

  validation {
    condition     = var.region == null || can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "region must be valid AWS region format (e.g., eu-west-1)."
  }

}

variable "cloudwatch_log_group_tags" {
  description = "A map of tags to apply to the CloudWatch Log Group"
  type        = map(string)
  default     = {}

}

# Tags
variable "tags" {
  description = "A map of additional tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "required_tags" {
  description = "Required organizational tags (CostCenter, Team, Compliance)"
  type        = map(string)
  default     = {}

  validation {
    condition = (
      contains(keys(var.required_tags), "CostCenter") &&
      contains(keys(var.required_tags), "Team") &&
      contains(keys(var.required_tags), "Compliance")
    )
    error_message = "Required tags must include: CostCenter, Team, and Compliance."
  }
}