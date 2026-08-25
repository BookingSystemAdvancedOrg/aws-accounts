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
  description = "Domain used to build the email address for each generated Identity Center user: <username>+aws@<domain>. Plus-addressed against a single real mailbox (aws@<domain>), same convention as billing_email_domain."
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

variable "access_portal_url" {
  description = "AWS access portal (token vending machine) sign-in URL, included in the user-provisioning SNS notification. Defaults to the standard AWS-generated pattern (https://<identity-store-id>.awsapps.com/start) -- VERIFY against the actual URL in your browser's address bar and override here if IAM Identity Center Settings has a custom portal subdomain configured instead."
  type        = string
  default     = "https://d-c3676ded63.awsapps.com/start"
}

variable "notification_email" {
  description = "Email address subscribed to the user-provisioning SNS topic. CI publishes here after every apply with the current list of provisioned Identity Center users and their sign-in emails -- AWS has no native invite/notification email for Identity Center users created via the API. Must confirm the SNS subscription once (a link sent to this address) before notifications start delivering."
  type        = string
  default     = "aws@ithjalparna.se"
}

variable "github_org" {
  description = "GitHub organization allowed to assume the per-account OIDC deploy role."
  type        = string
  default     = "BookingSystemAdvancedOrg"
}
