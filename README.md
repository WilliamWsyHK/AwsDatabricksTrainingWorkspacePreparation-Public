# Introduction
This repository contains `terraform` code to deploy Databricks workspace for training purpose in AWS.

## Resources to be created by this script
<!-- 1. Microsoft Entra ID Users and Groups (region-agnostic)
    - Instructors
    - Students -->
1. AWS VPC, with
    - 4 subnets
        - 2 Private subnets (connected to Internet via NAT Gateway with routing table), each in different availability zone
        - 2 Public subnets (connected to Internet Gateway with routing table), each in different availability zone
    - 1 NAT Gateway, in the first public subnet availability zone
    - 1 Internet Gateway
    - 1 Routing table
        - 0.0.0.0/0 to Internet Gateway
    - 1 Network ACL
        - 1 Ingress rule within VPC (by VPC CIDR)
        - 1 Ingress rule from all (required by Databricks)
        - 1 Egress rule within VPC (by VPC CIDR)
        - 2 Egress rules to Internet HTTP(s) (TCP/80 and TCP/443)
        - 2 Egress rules required to communicate with Databricks Infra (TCP/3306 and TCP/6666)
    - 1 Security Group
        - 1 Ingress rule within VPC
        - 1 Egress rule within VPC
        - 2 Egress rules to Internet HTTP(s) (TCP/80 and TCP/443)
        - 2 Egress rules required to communicate with Databricks Infra (TCP/3306 and TCP/6666)
1. AWS S3 Bucket for Databricks Unity Catalog (region-specific)
    - **Important!** One AWS region can only setup one Databricks Unity Catalog. If you want to reuse the existing Databricks Unity Catalog, then change the `terraform` code accordingly.
1. AWS S3 IAM Policy for Databricks to access S3 bucket
1. "Databricks on AWS" Storage configuration
1. "Databricks on AWS" Network configuration
1. "Databricks on AWS" Workspace (E2) (region-specific)
1. "Databricks on AWS" Clusters
    - Instructors' Clusters
        - Data Engineering
        - Machine Learning
    - Students' Clusters
        - Data Engineering
        - Machine Learning
1. AWS Databricks Training Materials ((c) Databricks)

## Required AWS/Databricks resources and accesses
1. AWS User for Terraform, with access key/secret generated.
1. "Databricks on AWS" account (can be found with link [here](https://accounts.cloud.databricks.com/)), which is already created by following [this documentation](https://docs.databricks.com/en/getting-started/index.html).
1. "Databricks on AWS" Credential configuration ([Setup guide](https://docs.databricks.com/en/administration-guide/account-settings-e2/credentials.html)). Use "Customer-managed VPC with default restrictions policy" for training purpose.
1. Databricks Group `Databricks Unity Catalog Administrators` (this is created separately from this project).
1. Databricks `Service Principal` have been created in "Databricks on AWS" Account.

## Preparing `secrets.tfvars` for deploying with Service Principal
```tfvars
aws_region = "<AWS region>"
aws_access_key = "<AWS Access Key ID>"
aws_secret_key = "<AWS Secret Value>"
aws_terraform_role_arn = "<AWS Terraform Role ARN>"
databricks_account_id = "<`Databricks on AWS` account ID>"
databricks_client_id = "<`Databricks on AWS` Service Principal ID>"
databricks_client_secret = "<`Databricks on AWS` Service Principal secret>"
databricks_account_cloud_credentials_id = "<`Databricks on AWS` Credential Configuration ID>"
```

## Preparing `backend.tfvars` for `terraform init --backend-config=backend.tfvars`
The values must be hard-coded (cannot be used with variables), as it is limitation on the backend config.
```tfvars
region = "<AWS region>"
bucket = "<AWS S3 Bucket Name>"
key    = "<AWS S3 Object Name>"
```

# Deployment Steps
1. Install AWS CLI `aws` & `terraform`
1. Login AWS CLI, run `aws configure`
1. `cd` to the correct sub-folder first, e.g. `cd ./environments/20240426`
1. Install terraform providers, run `terraform init --backend-config=backend.tfvars`
1. Check and see if there is anything wrong, run `terraform plan -var-file='<file>.tfvars' -out='<file>.tfplan'`
1. Deploy the infra, run `terraform apply '<file>.tfplan'`
1. To remove the whole deployment, run `terraform plan -destroy -var-file='<file>.tfvars' -out='<file-destroy>.tfplan'` and then `terraform apply '<file-destroy>.tfplan'`

# Databricks users
The user list can be modified to suit your needs, e.g. number of users required.
As this repository is served for creating training workspace, therefore the users are divided into 2 groups, `Instructors` and `Students`.
The example format of the users are
`student01.databricks.<training-date-yyyyMMdd>@<your email domain>`

# Reference
Pre-requisite steps documents are listed in the links below.

## Links
- [Databricks administration introduction | Databricks on AWS](https://docs.databricks.com/en/administration-guide/index.html)
- [OAuth machine-to-machine (M2M) authentication | Databricks on AWS](https://docs.databricks.com/en/dev-tools/auth/oauth-m2m.html)
- [Databricks Terraform provider | Databricks on AWS](https://docs.databricks.com/en/dev-tools/terraform/index.html)
- [Create Databricks workspaces using Terraform | Databricks on AWS](https://docs.databricks.com/en/dev-tools/terraform/e2-workspace.html)
- [Docs overview | databricks/databricks | Terraform | Terraform Registry](https://registry.terraform.io/providers/databricks/databricks/latest/docs)

## Terraform Providers
- `hashicorp/aws`
- `databricks/databricks`
