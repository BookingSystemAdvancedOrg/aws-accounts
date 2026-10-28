# The Booqy platform's own deploy roles. Booqy's dev and prod accounts are the
# `test` customer's accounts; these roles were made by hand before this repo
# managed them and are imported as they are. The infrastructure repo's
# pipeline signs in with them, which is why they live here and not in that
# repo: a role must not manage its own trust.
locals {
  platform_roles = {
    "test/dev" = {
      name        = "dev-infra-oidc-role"
      description = "this is for the testing repo of the dev account for the SBS platform"
    }
    "test/prod" = {
      name        = "prod-infra-oidc-role"
      description = "this role is for the test prod environment for the SBS platform "
    }
  }

  # Zero or one entry, so other customers' accounts get nothing from this file.
  platform_role = {
    for k, v in local.platform_roles : k => v if k == "${var.customer}/${var.env}"
  }
}

# Only the infrastructure repo, never any other repo in the org (site-* repos
# included).
data "aws_iam_policy_document" "platform_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.github_oidc.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}@${var.github_org_id}/infrastructure@*:*"]
    }
  }
}

resource "aws_iam_role" "platform" {
  for_each = local.platform_role

  name                 = each.value.name
  description          = each.value.description
  assume_role_policy   = data.aws_iam_policy_document.platform_trust.json
  max_session_duration = 3600

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "platform_admin" {
  for_each = local.platform_role

  role       = aws_iam_role.platform[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

import {
  for_each = local.platform_role
  to       = aws_iam_role.platform[each.key]
  id       = each.value.name
}

import {
  for_each = local.platform_role
  to       = aws_iam_role_policy_attachment.platform_admin[each.key]
  id       = "${each.value.name}/arn:aws:iam::aws:policy/AdministratorAccess"
}
