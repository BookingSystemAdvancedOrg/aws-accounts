variable "github_org" {
  description = "GitHub organization allowed to assume this role. Every repo in this org can assume it -- no other org can, since the sub claim is namespaced by org."
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role assumed by GitHub Actions via OIDC."
  type        = string
  default     = "github-actions-deploy"
}

variable "create_oidc_provider" {
  description = "Whether to create the token.actions.githubusercontent.com OIDC provider in this account. Set to false if it already exists (an AWS account can only have one)."
  type        = bool
  default     = true
}

variable "allowed_ref" {
  description = "Git ref pattern allowed to assume the role, e.g. '*' for any branch/tag, or 'refs/heads/main' to restrict to main."
  type        = string
  default     = "*"
}
