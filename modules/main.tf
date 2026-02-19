# Data Sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {

  valid_deployment_modes = ["oracle", "sqlserver-se", "postgress", "mysqlserver"]

  is_oracle = var.deployment_mode == "oracle"
  //is_sqlserver = var.deployment_mode == "sqlserver-se"

  skip_final_snapshot       = (var.skip_final_snapshot != null ? var.skip_final_snapshot : var.environment != "prod")
  final_snapshot_identifier = (var.skip_final_snapshot == false ? var.final_snapshot_identifier : null)
  deletion_protection       = (var.deletion_protection != null ? var.deletion_protection : var.environment == "prod")
  storage_throughput        = var.storage_type == "gp3" ? var.storage_throughput : null
  iops                      = var.storage_type == "io1" || var.storage_type == "io2" || var.storage_type == "gp3" ? var.iops : null

  # Common tags
  common_tags = merge(
    var.tags,
    var.required_tags,
    {
      Name          = var.identifier
      ManagedBy     = "terraform"
      Engine        = var.engine
      EngineVersion = var.engine_version
      Environment   = var.environment
      Project       = var.project
    }
  )
}

# ---- Module validations ----

resource "null_resource" "validate_rds_configuration" {

  lifecycle {

    # --validate_deployment_mode--
    precondition {
      condition     = contains(local.valid_deployment_modes, var.deployment_mode)
      error_message = "deployment_mode must be one of: oracle, sqlserver-se."
    }

    # -- validate_instance_class --
    precondition {
      condition = (
        var.deployment_mode != "oracle" || !can(regex("^db\\.t[0-9]", var.instance_class))
      )
      error_message = "Oracle does not support burstable instance classes (db.t*)."
    }

    precondition {
      condition = (
        var.deployment_mode != "oracle" || !can(regex("\\.micro$|\\.small$", var.instance_class))
      )
      error_message = "Oracle does not support micro or small instance sizes."
    }

    precondition {
      condition = (
        var.deployment_mode != "sqlserver-se" || !can(regex("^db\\.t[0-9]", var.instance_class))
      )
      error_message = "SQL Server does not support burstable instance classes (db.t*)."
    }

    precondition {
      condition = (
        var.deployment_mode != "sqlserver-se" || !can(regex("\\.micro$|\\.small$", var.instance_class))
      )
      error_message = "SQL Server does not support micro or small instance sizes."
    }

    # -- validate_db_parameters -- 
    precondition {
      condition = alltrue([
        for p in coalesce(var.db_parameter, []) :
        (
          !contains(["processes", "sessions"], p.name) || p.apply_method == "pending-reboot"
        )
      ])
      error_message = "Static Oracle parameters (processes, sessions) must use apply_method = pending-reboot."
    }

    # -- validate_conditional_variables --
    precondition {
      condition     = !var.create_db_option_group || var.major_engine_version != null
      error_message = "major_engine_version must be provided when create_db_option_group is true."
    }

    precondition {
      condition     = !var.create_db_parameter_group || var.db_parameter_group_family != null
      error_message = "db_parameter_group_family must be provided when create_db_parameter_group is true."
    }

    # -- validate_parameter_group --
    precondition {
      condition     = !var.create_db_parameter_group || var.db_parameter_group_family != null
      error_message = "db_parameter_group_family must be provided when create_db_parameter_group is true."
    }

    precondition {
      condition     = !(var.create_db_parameter_group && var.db_parameter_group_name != null)
      error_message = "Do not set db_parameter_group_name when create_db_parameter_group is true."
    }

    # -- validate_parameter_group_family --
    precondition {
      condition = (
        local.is_oracle && can(regex("^oracle-", var.db_parameter_group_family))
      ) //|| (local.is_sqlserver && can(regex("^sqlserver-", var.db_parameter_group_family))
      //)
      error_message = "db_parameter_group_family does not match the selected deployment_mode."
    }

    # -- validate_option_group --
    precondition {
      condition     = !var.create_db_option_group || (var.engine != null && var.major_engine_version != null)
      error_message = "engine and major_engine_version must be set when create_db_option_group is true."
    }

    precondition {
      condition     = !(var.create_db_option_group && var.db_option_group_name != null)
      error_message = "Do not set db_option_group_name when create_db_option_group is true."
    }

    # -- validate_prod_settings --
    precondition {
      condition     = var.environment != "prod" || local.deletion_protection == true
      error_message = "deletion_protection must be enabled in prod."
    }

    precondition {
      condition     = var.environment != "prod" || local.skip_final_snapshot == false
      error_message = "skip_final_snapshot must be false in prod."
    }

    precondition {
      condition     = var.environment != "prod" || !can(regex("\\.micro$|\\.small$", var.instance_class))
      error_message = "Production databases cannot use micro or small instance classes."
    }

    # -- validate_rds_iam_roles --
    precondition {
      condition = alltrue([
        for r in var.rds_iam_roles :
        can(regex("^arn:aws:iam::[0-9]{12}:role/.+", r.role_arn))
      ])
      error_message = "Each rds_iam_roles.role_arn must be a valid IAM role ARN."
    }

    # -- validate_storage_configuration --
    precondition {
      condition = (var.storage_type != "gp3" && var.storage_type != "io1" && var.storage_type != "io2") || var.iops > 0

      error_message = "iops must be > 0 when storage_type is io1 or io2."
    }

    precondition {
      condition     = var.storage_type != "gp3" || var.storage_throughput > 0
      error_message = "storage_throughput must be > 0 when storage_type is gp3."
    }

    precondition {
      condition     = var.max_allocated_storage == null || var.max_allocated_storage >= var.allocated_storage
      error_message = "max_allocated_storage must be greater than or equal to allocated_storage."
    }

    # -- validate_multi_az --
    precondition {
      condition     = !(var.multi_az && var.engine == "aurora-mysql")
      error_message = "Do not use multi_az=true with Aurora. Aurora uses clusters instead."
    }

    precondition {
      condition     = !var.multi_az || !can(regex("\\.micro$|\\.small$", var.instance_class))
      error_message = "Multi-AZ is not supported on micro or small instance classes."
    }

    # -- validate_master_user_password --
    precondition {
      condition = (
        var.manage_master_user_password || (!var.manage_master_user_password && var.master_password != null)
      )
      error_message = "master_password must be provided when manage_master_user_password is false."
    }

    # -- validate_replication_settings --
    precondition {
      condition     = !var.create_replication || (var.source_db_instance_arn != null && var.kms_key_arn != null)
      error_message = "source_db_instance_arn and kms_key_arn must be set when create_replication is true."
    }

    # -- validate_performance_insights --
    precondition {
      condition = (
        !var.performance_insights_enabled || var.performance_insights_retention_period != null
      )
      error_message = "performance_insights_retention_period must be set when performance_insights_enabled is true."
    }

    # -- validate_cloudwatch_logs_exports --
    precondition {
      condition     = !var.create_cloudwatch_log_group || var.enabled_cloudwatch_logs_exports != null
      error_message = "enabled_cloudwatch_logs_exports must be provided when create_cloudwatch_log_group is true."
    }

    precondition {
      condition = var.cloudwatch_log_group_class == null || contains(["STANDARD", "INFREQUENT_ACCESS"], var.cloudwatch_log_group_class)

      error_message = "cloudwatch_log_group_class must be STANDARD or INFREQUENT_ACCESS."
    }

    precondition {
      condition = (
        var.enabled_cloudwatch_logs_exports == null || var.create_cloudwatch_log_group == true
      )

      error_message = "create_cloudwatch_log_group must be true when enabled_cloudwatch_logs_exports is set."
    }

  }
}

# =========RDS Module resources==============

#Subnet group for RDS (optional)
resource "aws_db_subnet_group" "default" {
  count = var.create_db_instance ? 1 : 0

  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.identifier}-subnet-group"
    }
  )

  lifecycle {
    precondition {
      condition     = length(var.subnet_ids) >= 2
      error_message = "RDS subnet group must contain at least two subnets in different AZs."
    }
  }
}

# Parameter group for RDS (optional)
# controls DB runtime behavior
resource "aws_db_parameter_group" "this" {
  count = var.create_db_instance && var.create_db_parameter_group ? 1 : 0

  name   = "${var.name}-pg"
  family = var.db_parameter_group_family // Change based on deployment_mode

  description = "Custom parameter group for RDS instance"

  dynamic "parameter" {
    for_each = var.db_parameter != null ? var.db_parameter : []
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "pending-reboot") //if not set, terraform uses "pending-reboot" for both static and dynamic parameters
    }
  }

  /*lifecycle {
        create_before_destroy = true
        ignore_changes = [parameter]
    }*/

  tags = merge(
    local.common_tags,
    {
      Name = "${var.identifier}-parameter-group"
    }
  )
}

# Option Group for RDS (optional, for certain engines)
# Option Group can require reboot, plan downtime accordingly.
# Preparably skip for dev/test environments. For DB + S3 alway create it.
resource "aws_db_option_group" "this" {
  count = var.create_db_instance && var.create_db_option_group ? 1 : 0

  name                     = "${var.name}-og"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version
  option_group_description = "Custom option group for RDS instance"

  dynamic "option" {
    for_each = var.db_option != null ? var.db_option : []
    content {
      option_name = option.value.option_name

      dynamic "option_settings" {
        for_each = try(option.value.option_settings, [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value

        }
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.identifier}-option-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for RDS to access other AWS services (optional, based on options used)
resource "aws_db_instance_role_association" "this" {
  for_each = {
    for idx, role in var.rds_iam_roles :
    idx => role
  }

  db_instance_identifier = aws_db_instance.this[0].identifier
  role_arn               = each.value.role_arn
  feature_name           = each.value.feature_name
}

#common computed locals
locals {
  db_subnet_group_name = var.db_subnet_group_name != null ? var.db_subnet_group_name : (length(aws_db_subnet_group.default) > 0 ? aws_db_subnet_group.default[0].name : null)
  parameter_group_name = var.db_parameter_group_name != "" ? var.db_parameter_group_name : (length(aws_db_parameter_group.this) > 0 ? aws_db_parameter_group.this[0].name : null)
  option_group_name    = var.db_option_group_name != "" ? var.db_option_group_name : (length(aws_db_option_group.this) > 0 ? aws_db_option_group.this[0].name : null)
}

# RDS instance creation based on conditions
resource "aws_db_instance" "this" {
  count = var.create_db_instance && (local.is_oracle) ? 1 : 0

  identifier            = var.identifier
  db_name               = var.db_name
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.enable_storage_autoscaling ? var.max_allocated_storage : null
  storage_type          = var.storage_type // General Purpose SSD
  storage_encrypted     = var.storage_encrypted
  iops                  = local.iops
  storage_throughput    = local.storage_throughput

  license_model              = var.license_model
  publicly_accessible        = var.publicly_accessible
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  //custom_iam_instance_profile = "AWSRDSCustomInstanceProfile"

  username                    = var.master_username
  password                    = var.manage_master_user_password ? null : var.master_password
  manage_master_user_password = var.manage_master_user_password
  //master_user_secret_kms_key_id = aws_kms_key.rds.id //if not set, AWS uses default kms_key
  //port = var.port

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  deletion_protection       = local.deletion_protection       // true for prod, false for dev/test, condition make false for dev/test env 
  skip_final_snapshot       = local.skip_final_snapshot       // true for dev/test, false for prod, condition make false for prod env   
  final_snapshot_identifier = local.final_snapshot_identifier //only if skip_final_snapshot is false, enable this if env is prod
  apply_immediately         = var.apply_immediately           // Set to true for immediate application of changes

  kms_key_id = var.storage_encrypted ? var.kms_key_id : null
  //kms_key_id        = var.storage_encrypted ? (var.kms_key_id != null ? var.kms_key_id : (var.create_kms_key ? aws_kms_key.rds[0].arn : null)) : null

  multi_az = var.multi_az

  db_subnet_group_name   = local.db_subnet_group_name
  parameter_group_name   = local.parameter_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  option_group_name      = local.option_group_name
  monitoring_role_arn    = var.enable_enhanced_monitoring ? aws_iam_role.rds_monitoring[0].arn : null
  monitoring_interval    = var.monitoring_interval // in seconds

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  //performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  timeouts {
    create = var.db_instance_create_timeout
    update = var.db_instance_update_timeout
    delete = var.db_instance_delete_timeout
  }

  tags = local.common_tags


  # 
  lifecycle {
    create_before_destroy = false
    ignore_changes = [
      snapshot_identifier,
      password
    ]

    precondition {
      condition = !var.create_db_instance || (var.vpc_security_group_ids != null && length(var.vpc_security_group_ids) > 0
      )
      error_message = "At least one security group must be provided when create_db_instance is true."
    }

    precondition {
      condition     = var.storage_encrypted
      error_message = "Storage encryption must be enabled for Oracle RDS instances."
    }

    precondition {
      condition     = var.backup_retention_period >= 7
      error_message = "Backup retention period must be at least 7 days for production databases."
    }

    precondition {
      condition     = !var.publicly_accessible
      error_message = "RDS instances should not be publicly accessible for security reasons."
    }

    precondition {
      condition     = var.deletion_protection || var.environment != "production"
      error_message = "Deletion protection must be enabled for production databases."
    }

    precondition {
      condition = (
        var.storage_type == "gp3" || var.storage_type == "io1" || var.storage_type == "io2" ? var.iops != null : true
      )
      error_message = "IOPS must be specified for gp3, io1 and io2 storage types."
    }

    precondition {
      condition     = var.environment != "prod" || (var.backup_window != null && var.maintenance_window != null)
      error_message = "backup_window and maintenance_window must be explicitly set in production."
    }

    precondition {
      condition     = !can(regex("^aurora", var.engine)) || var.multi_az == false
      error_message = "Aurora engines use clusters and do not support multi_az in aws_db_instance."
    }

    precondition {
      condition = (
        contains(keys(var.required_tags), "CostCenter") &&
        contains(keys(var.required_tags), "Team") &&
        contains(keys(var.required_tags), "Compliance")
      )
      error_message = "Required tags must include: CostCenter, Team, and Compliance."
    }
  }

  depends_on = [
    aws_db_subnet_group.default,
    aws_db_parameter_group.this,
    aws_db_option_group.this,

  ]

}

# Read replica creation based on conditions
  // keep all same as primary RDS except identifier and source db instance arn, kms key for encryption, region for cross-region replication
/*resource "aws_db_instance" "replica" {
  count = var.create_replication ? 1 : 0
  identifier          = "var.identifier-replica"
  replicate_source_db = aws_db_instance.this[0].id
  instance_class      = "db.m6i.large"

  publicly_accessible = false
}*/

# Cloudwatch Alarms for RDS (optional, based on monitoring needs)
/*resource "aws_cloudwatch_metric_alarm" "rds" {
  for_each = var.cloudwatch_alarms.enabled ? { for alarm in var.cloudwatch_alarms.alarms : alarm.name => alarm } : {}

  alarm_name          = each.value.name
  alarm_description   = each.value.description
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  statistic           = each.value.statistic 
  period              = each.value.period
  evaluation_periods  = each.value.evaluation_periods
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison_operator
  alarm_actions       = each.value.alarm_actions

  dimensions = [
    {
      name  = "DBInstanceIdentifier"
      value = aws_db_instance.this[0].identifier
    }
  ]

}*/


# Log groups will be created
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset([for log in var.enabled_cloudwatch_logs_exports : log if var.create_db_instance && var.create_cloudwatch_log_group])

  name              = "/aws/rds/instance/${var.identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  skip_destroy      = var.cloudwatch_log_group_skip_destroy
  log_group_class   = var.cloudwatch_log_group_class
  region            = var.region

  tags = merge(var.tags, var.cloudwatch_log_group_tags)
}

# Database Connections Alarm
//resource "aws_cloudwatch_metric_alarm" "connections" {
//}

resource "aws_db_instance_automated_backups_replication" "this" {
  count = var.create_replication ? 1 : 0

  source_db_instance_arn = var.source_db_instance_arn
  kms_key_id             = var.kms_key_arn
  pre_signed_url         = var.pre_signed_url
  region                 = var.replica_region
  retention_period       = var.retention_period
}

//not for oracle engine, for aurora, we need to create cluster and then create cluster instances.
# resource "aws_rds_cluster" "this" {

# }

