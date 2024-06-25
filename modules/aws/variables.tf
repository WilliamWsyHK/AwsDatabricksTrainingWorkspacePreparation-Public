variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "databricks_vpc_cidr" {
  type = string
  description = "VPC CIDR for Databricks"
}