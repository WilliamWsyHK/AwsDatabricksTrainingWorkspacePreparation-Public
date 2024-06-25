variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "aws_access_key" {
  type        = string
  sensitive   = true
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  sensitive   = true
  description = "AWS secret key"
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

variable "databricks_account_cloud_credentials_id" {
  type        = string
  sensitive   = false
  description = "Databricks Account Cloud Credential ID"
}