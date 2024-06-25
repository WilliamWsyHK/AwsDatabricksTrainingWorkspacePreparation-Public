variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}

variable "vpc_subnet_ids" {
  type        = list(string)
  description = "AWS VPC Subnet IDs"
}

variable "vpc_security_group_ids" {
  type        = list(string)
  description = "AWS VPC Security Group IDs"
}

variable "databricks_account_id" {
  type        = string
  sensitive   = true
  description = "Databricks Account ID"
}

variable "databricks_client_id" {
  type        = string
  sensitive   = true
  description = "Databricks Account Service Principal ID"
}

variable "databricks_client_secret" {
  type        = string
  sensitive   = true
  description = "Databricks Account Service Principal Secret"
}

variable "databricks_unity_catalog_s3_bucket_name" {
  type        = string
  sensitive   = false
  description = "AWS S3 Bucket name for Databricks Metastore (Unity Catalog)"
}

variable "databricks_unity_catalog_admin_group_display_name" {
  type = string
  sensitive = false
  description = "Databricks Unity Catalog admin group display name"
}

variable "databricks_metastore_name" {
  type        = string
  sensitive   = false
  description = "Databricks Metastore (Unity Catalog) name"
}

variable "databricks_workspace_name" {
  type        = string
  sensitive   = false
  description = "Databricks Workspace name"
}

variable "databricks_account_cloud_credentials_id" {
  type        = string
  sensitive   = true
  description = "Databricks Account Cloud Credential ID"
}