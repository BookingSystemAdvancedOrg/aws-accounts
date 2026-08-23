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

  # One state file PER ACCOUNT: initialize with a distinct key, e.g.
  #   terraform init -backend-config=key=customers/${customer}/${env}/account-baseline.tfstate
  backend "s3" {
    # bucket         = "sbs-terraform-state"
    # region         = "eu-north-1"
    # dynamodb_table = "sbs-terraform-locks"
    # encrypt        = true
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
