terraform {
  required_providers {
    aws = {
      source = "registry.terraform.io/hashicorp/aws"
    }
    databricks = {
      source = "registry.terraform.io/databricks/databricks"
      configuration_aliases = [databricks.accounts]
    }
  }
}

provider "databricks" {
  alias         = "accounts"
  host          = "https://accounts.cloud.databricks.com"
  account_id    = var.databricks_account_id
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}