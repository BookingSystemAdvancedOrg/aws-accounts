variable "customers" {
  description = "List of customer identifiers."
  type        = list(string)
}

variable "customer_users" {
  description = "Map of customer -> list of usernames (each prefixed 'a-' or 'd-')."
  type        = map(list(string))
}

variable "customer_accounts" {
  description = "Map of customer -> { dev_account_id, prod_account_id }, from the organizations module."
  type = map(object({
    dev_account_id  = string
    prod_account_id = string
  }))
}

variable "user_email_domain" {
  description = "Domain used to build each Identity Center user's email: aws+<username>@<domain>. Exception: the hardcoded aws_admin user uses the bare aws@<domain> mailbox directly."
  type        = string
}

variable "aws_admin_email" {
  description = <<-EOT
    Toggle for the hardcoded aws_admin break-glass user, not an email override.
    Leave as "" (the default) to deploy aws_admin with the fixed address
    aws@<user_email_domain>, added to every customer's admin group. Set to
    any non-empty value to skip creating it entirely.
  EOT
  type        = string
  default     = ""
}

variable "admin_permission_set_name" {
  description = "Name of the AdministratorAccess permission set (shared across all customers)."
  type        = string
  default     = "AdministratorAccess"
}

variable "developer_permission_set_name" {
  description = "Name of the PowerUserAccess permission set (shared across all customers)."
  type        = string
  default     = "PowerUserAccess"
}
