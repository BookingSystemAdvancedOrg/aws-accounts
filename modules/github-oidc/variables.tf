variable "github_org" {
  description = "GitHub organization that owns github_repo."
  type        = string
}

variable "github_org_id" {
  description = "Numeric ID of github_org. Pinning it means a renamed or re-registered org of the same name can't match."
  type        = string
}

variable "github_repo" {
  description = "The one repo in github_org whose workflows may assume this role. Any other repo, including customer site-* repos, is refused."
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
