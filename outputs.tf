output "customer_ous" {
  description = "Map of customer -> OU ID created under workloads/."
  value       = module.organizations.customer_ou_ids
}

output "customer_accounts" {
  description = "Map of customer -> { dev_account_id, prod_account_id }. Consumed by the account-baseline stage / CI matrix."
  value       = module.organizations.customer_accounts
}

# Convenience flat list for generating a GitHub Actions matrix:
# [{ customer, env, account_id }, ...]
output "account_matrix" {
  description = "Flattened list of every generated account, for the account-baseline CI matrix."
  value = flatten([
    for customer, accts in module.organizations.customer_accounts : [
      {
        customer   = customer
        env        = "dev"
        account_id = accts.dev_account_id
      },
      {
        customer   = customer
        env        = "prod"
        account_id = accts.prod_account_id
      },
    ]
  ])
}

output "identity_center_groups" {
  description = "Map of customer -> { admin_group_id, developer_group_id }."
  value       = module.identity_center.customer_groups
}

output "provisioned_users" {
  description = "username -> sign-in email for every provisioned Identity Center user. Read by the CI 'notify user provisioning' step after every apply."
  value       = module.identity_center.provisioned_users
}

output "provisioning_topic_arn" {
  description = "SNS topic ARN the CI 'notify user provisioning' step publishes to."
  value       = aws_sns_topic.user_provisioning.arn
}
