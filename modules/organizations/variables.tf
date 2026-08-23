variable "workloads_ou_id" {
  description = "OU ID of the existing 'workloads' OU. Each customer OU is created directly under it."
  type        = string
}

variable "customers" {
  description = "List of customer identifiers."
  type        = list(string)
}

variable "billing_email_domain" {
  description = "Domain used to build each account's root email: <customer>-<env>+aws@<domain>."
  type        = string
}
