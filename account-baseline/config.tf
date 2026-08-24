terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # One state file PER ACCOUNT -- bucket/region/locking are fixed, but `key`
  # can't be hardcoded here (backend blocks don't allow interpolation, and
  # this varies per customer/env). Initialize with:
  #   terraform init -backend-config="key=customers/<customer>/<env>/account-baseline.tfstate"
  # Locking is native S3 conditional-write locking (use_lockfile, Terraform
  # >=1.11) -- no DynamoDB table.
  backend "s3" {
    bucket       = "388343452097-tfstate-bucket"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}

# Runs with management-account credentials, then assumes
# OrganizationAccountAccessRole INTO the target member account -- every
# resource this root creates (OIDC provider, IAM role) lands in that account,
# never in the management account.
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = "arn:aws:iam::${var.target_account_id}:role/OrganizationAccountAccessRole"
  }

  default_tags {
    tags = {
      ManagedBy = "terraform"
      Repo      = "aws-accounts"
      Customer  = var.customer
      Env       = var.env
    }
  }
}
