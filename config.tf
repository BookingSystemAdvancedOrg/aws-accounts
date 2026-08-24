terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State for the org/identity-center stage lives in the management account.
  # Hardcoded (no per-environment variation, no secrets in a bucket name) --
  # `terraform init` needs no flags at all for this root module.
  # Locking is native S3 conditional-write locking (use_lockfile, Terraform
  # >=1.11) -- no DynamoDB table.
  backend "s3" {
    bucket       = "388343452097-tfstate-bucket"
    key          = "org/customers.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}

# This root module must run with credentials for the MANAGEMENT account
# (388343452097 / it-hjalparna-admin). It creates OUs, member accounts, and
# all IAM Identity Center objects (users/groups/permission sets/assignments),
# none of which live "inside" the member accounts.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Repo      = "aws-accounts"
    }
  }
}
