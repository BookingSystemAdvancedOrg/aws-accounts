output "customer_groups" {
  description = "Map of customer -> { admin_group_id, developer_group_id }."
  value = {
    for c in var.customers : c => {
      admin_group_id     = aws_identitystore_group.admin[c].group_id
      developer_group_id = aws_identitystore_group.developer[c].group_id
    }
  }
}

output "administrator_permission_set_arn" {
  value = aws_ssoadmin_permission_set.administrator.arn
}

output "developer_permission_set_arn" {
  value = aws_ssoadmin_permission_set.developer.arn
}

output "provisioned_users" {
  description = "username -> sign-in email for every Identity Center user this module manages. Consumed by the CI step that notifies notification_email after every apply."
  value = {
    for username in local.unique_usernames : username => "${username}+aws@${var.user_email_domain}"
  }
}
