terraform {
  required_providers {
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 5.44.0"
    }
    databricks = {
      source = "registry.terraform.io/databricks/databricks"
      version = "~> 1.39.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  default_tags {
    tags = {
      "Region": var.aws_region,
      "Environment": "Test",
      "ManagedBy": "Terraform"
    }
  }
}