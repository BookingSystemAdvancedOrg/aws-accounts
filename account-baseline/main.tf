module "github_oidc" {
  source = "../modules/github-oidc"

  github_org = var.github_org
  role_name  = "github-actions-deploy"
}

module "state_backend" {
  source = "../modules/state-backend"

  customer          = var.customer
  env               = var.env
  target_account_id = var.target_account_id
}
