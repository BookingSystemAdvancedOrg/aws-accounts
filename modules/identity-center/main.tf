data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # Flatten { customer => [usernames] } into per-role, per-user maps keyed by
  # "customer/username" so each resource has a stable for_each key.
  admin_users = {
    for pair in flatten([
      for customer, users in var.customer_users : [
        for u in users : { customer = customer, username = u } if startswith(u, "a-")
      ]
    ]) : "${pair.customer}/${pair.username}" => pair
  }

  developer_users = {
    for pair in flatten([
      for customer, users in var.customer_users : [
        for u in users : { customer = customer, username = u } if startswith(u, "d-")
      ]
    ]) : "${pair.customer}/${pair.username}" => pair
  }

  all_users = merge(local.admin_users, local.developer_users)

  # customer x env x role -> account assignment
  account_assignments = merge(
    { for pair in flatten([
      for customer, accts in var.customer_accounts : [
        for env, account_id in { dev = accts.dev_account_id, prod = accts.prod_account_id } : {
          key                = "${customer}/${env}/admin"
          customer           = customer
          env                = env
          account_id         = account_id
          permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
          group_key          = customer
        }
      ]
    ]) : pair.key => pair },
    { for pair in flatten([
      for customer, accts in var.customer_accounts : [
        for env, account_id in { dev = accts.dev_account_id, prod = accts.prod_account_id } : {
          key                = "${customer}/${env}/developer"
          customer           = customer
          env                = env
          account_id         = account_id
          permission_set_arn = aws_ssoadmin_permission_set.developer.arn
          group_key          = customer
        }
      ]
    ]) : pair.key => pair }
  )
}

# --- Permission sets (created once, shared across every customer account) ---

resource "aws_ssoadmin_permission_set" "administrator" {
  name             = var.admin_permission_set_name
  description      = "Full administrator access. Assigned to each customer's <customer>-admin group."
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_ssoadmin_permission_set" "developer" {
  name             = var.developer_permission_set_name
  description      = "Power-user access (no IAM/org management). Assigned to each customer's <customer>-developer group."
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# --- Per-customer groups ---

resource "aws_identitystore_group" "admin" {
  for_each          = toset(var.customers)
  identity_store_id = local.identity_store_id

  display_name = "${each.value}-admin"
  description  = "Admins for the ${each.value} dev and prod accounts."
}

resource "aws_identitystore_group" "developer" {
  for_each          = toset(var.customers)
  identity_store_id = local.identity_store_id

  display_name = "${each.value}-developer"
  description  = "Developers for the ${each.value} dev and prod accounts."
}

# --- Users ---

resource "aws_identitystore_user" "this" {
  for_each          = local.all_users
  identity_store_id = local.identity_store_id

  user_name    = each.value.username
  display_name = each.value.username

  name {
    given_name  = title(replace(substr(each.value.username, 2, -1), "-", " "))
    family_name = title(each.value.customer)
  }

  emails {
    value   = "${each.value.username}@${var.user_email_domain}"
    primary = true
  }
}

# --- Group membership ---

resource "aws_identitystore_group_membership" "admin" {
  for_each          = local.admin_users
  identity_store_id = local.identity_store_id

  group_id  = aws_identitystore_group.admin[each.value.customer].group_id
  member_id = aws_identitystore_user.this[each.key].user_id
}

resource "aws_identitystore_group_membership" "developer" {
  for_each          = local.developer_users
  identity_store_id = local.identity_store_id

  group_id  = aws_identitystore_group.developer[each.value.customer].group_id
  member_id = aws_identitystore_user.this[each.key].user_id
}

# --- Account assignments (SSO access to dev + prod for each group) ---

resource "aws_ssoadmin_account_assignment" "admin" {
  for_each = { for k, v in local.account_assignments : k => v if endswith(k, "/admin") }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = aws_identitystore_group.admin[each.value.group_key].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "developer" {
  for_each = { for k, v in local.account_assignments : k => v if endswith(k, "/developer") }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = each.value.permission_set_arn

  principal_id   = aws_identitystore_group.developer[each.value.group_key].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}
