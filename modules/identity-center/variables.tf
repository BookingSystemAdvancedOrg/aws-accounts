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
  description = "Domain used to build each Identity Center user's email: <username>+aws@<domain>."
  type        = string
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
