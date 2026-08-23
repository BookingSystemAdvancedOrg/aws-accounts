variable "customer" {
  description = "Customer this state bucket belongs to, e.g. 'acme'."
  type        = string
}

variable "env" {
  description = "Which account this state bucket lives in: 'dev' or 'prod'."
  type        = string
}

variable "target_account_id" {
  description = "Account ID this bucket/table are created in. Appended to the bucket name for guaranteed global uniqueness."
  type        = string
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep noncurrent state file versions before they're expired. Versioning itself stays on indefinitely; this just caps storage growth."
  type        = number
  default     = 90
}
