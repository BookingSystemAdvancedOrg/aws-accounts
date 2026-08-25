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

# CI publishes here after every apply with the current list of provisioned
# users and their sign-in emails, since AWS has no native "email the user on
# provision" API for Identity Center -- see aws_sns_topic_subscription below.
resource "aws_sns_topic" "user_provisioning" {
  name = "aws-accounts-user-provisioning"
}

# Email subscriptions require a one-time confirmation click before delivery
# starts -- check notification_email's inbox for a "AWS Notification -
# Subscription Confirmation" message right after this is first applied.
resource "aws_sns_topic_subscription" "user_provisioning_email" {
  topic_arn = aws_sns_topic.user_provisioning.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
