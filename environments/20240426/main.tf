locals {
  databricks_vpc_cidr                               = "172.16.0.0/24"
  databricks_unity_catalog_s3_bucket_name           = "your-unity-catalog-${var.aws_region}"
  databricks_unity_catalog_admin_group_display_name = "Databricks Unity Catalog Administrators"
  databricks_metastore_name                         = "your-metastore-${var.aws_region}"
  databricks_workspace_name                         = "your-databricks-workspace-aws-${var.aws_region}"
}

module "aws" {
  source = "../../modules/aws"

  aws_region          = var.aws_region
  databricks_vpc_cidr = local.databricks_vpc_cidr
}

module "databricks_accounts" {
  source = "../../modules/databricks_accounts"

  aws_region = var.aws_region

  vpc_id                 = module.aws.databricks_vpc_id
  vpc_subnet_ids         = module.aws.databricks_vpc_subnet_ids
  vpc_security_group_ids = module.aws.databricks_vpc_security_group_ids

  databricks_unity_catalog_s3_bucket_name = local.databricks_unity_catalog_s3_bucket_name

  databricks_account_id    = var.databricks_account_id
  databricks_client_id     = var.databricks_client_id
  databricks_client_secret = var.databricks_client_secret

  databricks_unity_catalog_admin_group_display_name = local.databricks_unity_catalog_admin_group_display_name
  databricks_metastore_name                         = local.databricks_metastore_name

  databricks_workspace_name               = local.databricks_workspace_name
  databricks_account_cloud_credentials_id = var.databricks_account_cloud_credentials_id
}

# provider "databricks" {
#   host = module.databricks_accounts.databricks_workspace_url
#   token = module.databricks_accounts.databricks_workspace_token
# }