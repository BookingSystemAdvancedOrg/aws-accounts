variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "target_account_id" {
  description = "Account ID this apply targets (one of the accounts created by the org/customers.tfvars stage)."
  type        = string
}

variable "customer" {
  description = "Customer this account belongs to, e.g. 'acme'."
  type        = string
}

variable "env" {
  description = "Which account this is: 'dev' or 'prod'."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be 'dev' or 'prod'."
  }
}

variable "github_org" {
  type    = string
  default = "BookingSystemAdvancedOrg"
}
