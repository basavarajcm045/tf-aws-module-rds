variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Project   = "RDS-Oracle"
    Owner     = "Platform-Team"
  }
}