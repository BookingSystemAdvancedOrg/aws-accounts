output "github_actions_role_arn" {
  value = module.github_oidc.role_arn
}

output "tfstate_bucket_name" {
  value = module.state_backend.bucket_name
}

output "tfstate_bucket_arn" {
  value = module.state_backend.bucket_arn
}
