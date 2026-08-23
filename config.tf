terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State for the org/identity-center stage lives in the management account.
  # Fill in the bucket/table (e.g. from the shared-account state resources)
  # and initialize with:
  #   terraform init -backend-config=backend.hcl
  backend "s3" {
    # bucket         = "sbs-terraform-state"
    # key            = "org/customers.tfstate"
    # region         = "eu-north-1"
    # encrypt        = true
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
