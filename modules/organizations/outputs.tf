output "customer_ou_ids" {
  description = "Map of customer -> OU ID."
  value       = { for c, ou in aws_organizations_organizational_unit.customer : c => ou.id }
}

output "customer_accounts" {
  description = "Map of customer -> { dev_account_id, prod_account_id }."
  value = {
    for c in var.customers : c => {
      dev_account_id  = aws_organizations_account.dev[c].id
      prod_account_id = aws_organizations_account.prod[c].id
    }
  }
}
