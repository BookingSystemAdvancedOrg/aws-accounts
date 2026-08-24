resource "aws_organizations_organizational_unit" "customer" {
  for_each = toset(var.customers)

  name      = each.value
  parent_id = var.workloads_ou_id

  tags = {
    Customer = each.value
  }
}

resource "aws_organizations_account" "dev" {
  for_each = toset(var.customers)

  name      = "${each.value}-dev"
  email     = "${each.value}-dev+aws@${var.billing_email_domain}"
  parent_id = aws_organizations_organizational_unit.customer[each.value].id

  # Default role Organizations creates in the new account, used by the
  # account-baseline stage to assume into it.
  role_name = "OrganizationAccountAccessRole"

  iam_user_access_to_billing = "ALLOW"
  close_on_deletion          = false

  tags = {
    Customer    = each.value
    Environment = "dev"
  }

  # Deleting an AWS account via Terraform is (mostly) irreversible. Require a
  # deliberate `terraform state rm` / manual override rather than an
  # accidental `terraform destroy` or a customer dropped from the list.
  #
  # role_name / iam_user_access_to_billing are write-only at account
  # creation -- AWS never returns them afterward, so a `terraform import`
  # can't populate them in state. Left untracked, that mismatch shows as
  # "forces replacement" on every plan against an imported account, even
  # though the real values already match. Ignore them post-creation.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name, iam_user_access_to_billing]
  }
}

resource "aws_organizations_account" "prod" {
  for_each = toset(var.customers)

  name      = "${each.value}-prod"
  email     = "${each.value}-prod+aws@${var.billing_email_domain}"
  parent_id = aws_organizations_organizational_unit.customer[each.value].id

  role_name = "OrganizationAccountAccessRole"

  iam_user_access_to_billing = "ALLOW"
  close_on_deletion          = false

  tags = {
    Customer    = each.value
    Environment = "prod"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name, iam_user_access_to_billing]
  }
}
