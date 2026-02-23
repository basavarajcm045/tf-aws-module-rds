
# Restore from Snapshot Example

## Purpose

The purpose of these examples is to:

- Illustrate snapshot restoration workflow

## What this Example Cretaes

- Restored RDS instance from an existing snapshot

### Use Case

This example is useful for:

- Disaster recovery

- Environment cloning

- Point-in-time recovery testing

- Migrating database instances

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
| `snapshot_identifier`          | Existing RDS snapshot name or ARN            |
