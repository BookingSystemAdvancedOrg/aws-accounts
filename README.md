# aws-accounts

Automates customer AWS account vending under the `workloads` OU.

Adding a customer to `customers.tfvars` produces:

- 1 OU under `workloads/` (`ou-oti7-vk4layff`) named after the customer
- 2 member accounts in that OU: `<customer>-dev`, `<customer>-prod`
- 1 IAM Identity Center group per role per customer: `<customer>-admin`,
  `<customer>-developer`, each assigned (via AWS-managed permission sets)
  `AdministratorAccess` / `PowerUserAccess` in **both** the dev and prod
  accounts
- 1 Identity Center user per entry in `customer_users`, added to the
  matching group by username prefix (`a-` -> admin, `d-` -> developer)
- 1 GitHub OIDC provider + `AdministratorAccess` IAM role
  (`github-actions-deploy`) in **each** of the dev/prod accounts, trusting
  `repo:BookingSystemAdvancedOrg/*:*` -- i.e. any repo in that GitHub org can
  assume the role in any customer's dev/prod account, but no other org can

## Why two Terraform roots

`organizations` + `identity-center` are management-account-only resources —
Organizations and IAM Identity Center are always managed from the account
where they're enabled, regardless of which account they target. They live in
the repo root and share one state file.

The GitHub OIDC provider and IAM role, however, are IAM resources that must
physically exist **inside each member account**. Terraform provider blocks
cannot be generated dynamically per for_each item, so this can't be one
`terraform apply`. Instead `account-baseline/` is a second, tiny root module
applied **once per account** (its own state file, keyed by
`customers/<customer>/<env>/account-baseline.tfstate`), with its AWS provider
assuming `OrganizationAccountAccessRole` into whichever `target_account_id`
you pass in. `.github/workflows/cicd.yml` drives this automatically: stage 1
applies the root module and emits an `account_matrix` output, stage 2 fans
that out into one job per account.

## Layout

```
config.tf, variables.tf, main.tf, outputs.tf   # root: organizations + identity-center
customers.tfvars                                # the only file you edit day-to-day
modules/organizations/                          # OUs + accounts
modules/identity-center/                        # groups, users, permission sets, assignments
modules/github-oidc/                             # OIDC provider + deploy role (single account)
account-baseline/                                # per-account root that calls modules/github-oidc
```

## One-time bootstrap (do this before the pipeline can run)

1. Create (or reuse) an S3 bucket in the management account for Terraform
   state -- bucket name is hardcoded in `config.tf` /
   `account-baseline/config.tf` (`388343452097-tfstate-bucket`), so nothing
   to set as a repo variable for this. Locking is native S3 conditional-write
   locking (`use_lockfile = true`, requires Terraform >=1.11 -- this repo
   pins `TF_VERSION` well above that in `cicd.yml`); no DynamoDB table.
2. Create a GitHub OIDC provider + deploy role **in the management account**
   by hand (bootstrap chicken-and-egg — this repo's own pipeline can't
   provision its own credentials). Set its ARN as the `MANAGEMENT_DEPLOY_ROLE_ARN`
   repo variable. Scope its trust policy to `repo:BookingSystemAdvancedOrg/aws-accounts:*`.
3. Local plans: `terraform init` at the repo root needs no flags (backend is
   fully hardcoded). In `account-baseline/`, `key` still can't be hardcoded
   (it varies per customer/env), so run:
   `terraform init -backend-config="key=customers/<customer>/<env>/account-baseline.tfstate"`

## Adding a customer

1. Add the customer name to `customers` in `customers.tfvars`.
2. Add its users to `customer_users` (usernames prefixed `a-` or `d-`).
3. Open a PR — CI plans the org/identity-center stage. Merge to `main` to
   apply it and fan out `account-baseline` into the two new accounts.

## Notes / things to revisit as this scales

- The GitHub deploy role gets `AdministratorAccess`, per the requirement —
  it's the broadest possible grant to a CI role. Worth narrowing to a
  deploy-scoped policy once each customer's actual IaC footprint is known.
- The deploy role's trust is org-wide (`repo:BookingSystemAdvancedOrg/*:*`),
  not scoped to one repo per customer, per the requirement. This means any
  repo in the org can deploy with `AdministratorAccess` into every
  customer's dev and prod accounts -- a compromised or careless workflow in
  one repo can reach every other customer's account. `allowed_ref` (module
  variable, defaults to `*`) is available to narrow this by branch/tag later
  without restructuring, if that tradeoff needs revisiting.
- `aws_organizations_account` has `prevent_destroy = true` — removing a
  customer from `customers.tfvars` will NOT delete its accounts; that has to
  be a deliberate, separate action (AWS account deletion is effectively
  irreversible).
- Permission sets (`AdministratorAccess` / `PowerUserAccess`) are created
  once and shared across all customers; only the group -> account assignment
  is per customer, so there's no permission-set sprawl as customers grow.
