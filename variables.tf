variable "aws_region" {
  description = "Region for the management-account provider and IAM Identity Center."
  type        = string
  default     = "eu-north-1"
}

variable "workloads_ou_id" {
  description = "OU ID of the existing 'workloads' OU (parent for all per-customer OUs)."
  type        = string
  default     = "ou-oti7-vk4layff"
}

variable "billing_email_domain" {
  description = "Domain used to build the root email address for each generated account: <customer>-<env>+aws@<domain>."
  type        = string
  default     = "ithjalparna.se"
}

variable "user_email_domain" {
  description = "Domain used to build the email address for each generated Identity Center user: aws+<username>@<domain>. Plus-addressed against the real mailbox aws@<domain> -- base local-part must be 'aws' for delivery to not depend on a catch-all."
  type        = string
  default     = "ithjalparna.se"
}

variable "customers" {
  description = "List of customer identifiers. Each entry gets an OU under workloads/, plus a dev and a prod account."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.customers : can(regex("^[a-z0-9](?:[a-z0-9-]{0,30}[a-z0-9])?$", c))])
    error_message = "Customer names must be lowercase alphanumeric with optional hyphens, 2-32 chars (used in OU/account names, emails and GitHub repo names)."
  }
}

variable "customer_users" {
  description = <<-EOT
    Per-customer list of Identity Center usernames. Each username MUST start
    with 'a-' (added to the customer's admin group -> AdministratorAccess) or
    'd-' (added to the customer's developer group -> PowerUserAccess) in both
    the dev and prod accounts. Example: { acme = ["a-jane", "d-john"] }.
  EOT
  type        = map(list(string))
  default     = {}

  validation {
    condition = alltrue(flatten([
      for customer, users in var.customer_users : [
        for u in users : can(regex("^[ad]-[a-z0-9._-]+$", u))
      ]
    ]))
    error_message = "Every username must start with 'a-' (admin) or 'd-' (developer), e.g. a-jane or d-john."
  }

  validation {
    condition     = alltrue([for customer, users in var.customer_users : contains(var.customers, customer)])
    error_message = "Every key in customer_users must also be present in the customers list."
  }
}

variable "github_org" {
  description = "GitHub organization allowed to assume the per-account OIDC deploy role."
  type        = string
  default     = "BookingSystemAdvancedOrg"
}
