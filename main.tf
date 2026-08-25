module "organizations" {
  source = "./modules/organizations"

  workloads_ou_id       = var.workloads_ou_id
  customers             = var.customers
  billing_email_domain  = var.billing_email_domain
}

module "identity_center" {
  source = "./modules/identity-center"

  customers        = var.customers
  customer_users   = var.customer_users
  user_email_domain = var.user_email_domain

  # customer -> { dev_account_id, prod_account_id }
  customer_accounts = module.organizations.customer_accounts
}
