data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "unity_catalog" {
  bucket        = var.databricks_unity_catalog_s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "unity_catalog" {
  bucket = aws_s3_bucket.unity_catalog.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "unity_catalog" {
  bucket = aws_s3_bucket.unity_catalog.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "unity_catalog" {
  bucket = aws_s3_bucket.unity_catalog.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [
    aws_s3_bucket.unity_catalog
  ]
}

resource "aws_s3_bucket_acl" "unity_catalog" {
  bucket = aws_s3_bucket.unity_catalog.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.unity_catalog,
    aws_s3_bucket_public_access_block.unity_catalog
  ]
}

resource "aws_s3_bucket_versioning" "unity_catalog" {
  bucket = aws_s3_bucket.unity_catalog.id
  versioning_configuration {
    status = "Disabled"
  }
}

data "aws_iam_policy_document" "databricks_data_access" {
  statement {
    sid    = "Grant Databricks Access"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::414351767826:root"
      ]
    }
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.unity_catalog.arn,
      "${aws_s3_bucket.unity_catalog.arn}/*"
    ]
    condition {
      test = "StringEquals"
      variable = "aws:PrincipalTag/DatabricksAccountId"
      values = [
        var.databricks_account_id
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "databricks_data_access" {
  bucket = aws_s3_bucket.unity_catalog.id
  policy = data.aws_iam_policy_document.databricks_data_access.json
}

resource "databricks_mws_storage_configurations" "unity_catalog" {
  provider = databricks.accounts

  account_id                 = var.databricks_account_id
  storage_configuration_name = aws_s3_bucket.unity_catalog.bucket
  bucket_name                = aws_s3_bucket.unity_catalog.bucket

  depends_on = [
    aws_s3_bucket_policy.databricks_data_access
  ]
}

resource "databricks_mws_networks" "this" {
  provider = databricks.accounts

  account_id         = var.databricks_account_id
  network_name       = "${var.aws_region}-network"
  vpc_id             = var.vpc_id
  subnet_ids         = var.vpc_subnet_ids
  security_group_ids = var.vpc_security_group_ids
}

data "databricks_group" "unity_catalog_admin" {
  provider = databricks.accounts

  display_name = var.databricks_unity_catalog_admin_group_display_name
}

resource "databricks_metastore" "this" {
  provider = databricks.accounts

  name = var.databricks_metastore_name
  storage_root = format("s3://%s/",
    var.databricks_unity_catalog_s3_bucket_name
  )
  owner = data.databricks_group.unity_catalog_admin.display_name
  region = aws_s3_bucket.unity_catalog.region

  force_destroy = true
}

resource "databricks_mws_workspaces" "this" {
  provider = databricks.accounts

  account_id     = var.databricks_account_id
  workspace_name = var.databricks_workspace_name
  aws_region     = var.aws_region

  credentials_id           = var.databricks_account_cloud_credentials_id
  storage_configuration_id = databricks_mws_storage_configurations.unity_catalog.storage_configuration_id
  network_id               = databricks_mws_networks.this.network_id

  token {}
}

resource "databricks_metastore_assignment" "this" {
  provider = databricks.accounts

  metastore_id = databricks_metastore.this.id
  workspace_id = databricks_mws_workspaces.this.workspace_id
  default_catalog_name = "hive_metastore"
}