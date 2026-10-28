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

variable "github_org_id" {
  description = "Numeric ID of github_org (part of every OIDC subject the org issues)."
  type        = string
  default     = "307760488"
}

variable "deploy_repo" {
  description = "The repo whose workflows may assume github-actions-deploy in this account."
  type        = string
  default     = "infrastructure"
}
