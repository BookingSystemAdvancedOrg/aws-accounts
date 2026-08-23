output "role_arn" {
  description = "ARN of the IAM role GitHub Actions assumes via OIDC."
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  value = data.aws_iam_openid_connect_provider.github.arn
}
