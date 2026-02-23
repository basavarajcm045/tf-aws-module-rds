
# Mysql Production Instance Example

## Purpose

The purpose of these examples is to:

- Demonstrate real-world production usage patterns.

- Show engine-specific configurations.

- Illustrate snapshot restoration workflow

- Standardize monitoring and logging across environments

These examples are intended for production-grade deployments with monitoring, backups, and logging enabled.

## What this Example Cretaes

- Amazon RDS MySQL instance

- DB Subnet Group (private subnets)

- Mysql-specific Parameter Group

- Mysql Option Group (Optional)

- CloudWatch Log Group(s)

- CloudWatch CPU, Free Storage, and Memory alarms

- Performance Insights (optional)

- Automated backups

- Multi-AZ deployment (optional based on variables)

### Engine

- Engine: oracle-se (example)

- License model: Bring Your Own License (BYOL) or license included

- Production sizing configuration

### Usage

cd examples/Mysql-Production-Instance
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply

### Key Variables

| Variable                  | Description                  |
| ------------------------- | ---------------------------- |
| `instance_class`          | RDS instance type            |
| `allocated_storage`       | Storage size (GB)            |
| `multi_az`                | Enable Multi-AZ deployment   |
| `backup_retention_period` | Backup retention days        |
| `monitoring_interval`     | Enhanced monitoring interval |

