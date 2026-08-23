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
- 1 S3 bucket in **each** of the dev/prod accounts, for the customer's own
  application Terraform to use as its state backend -- distinct from this
  repo's own state, and distinct per account so a customer's dev and prod
  app state never share a bucket (bucket-only, no DynamoDB lock table --
  see notes below)

## Why two Terraform roots

`organizations` + `identity-center` are management-account-only resources —
Organizations and IAM Identity Center are always managed from the account
where they're enabled, regardless of which account they target. They live in
the repo root and share one state file.

The GitHub OIDC provider, IAM role, and the customer's app-state S3 bucket,
however, are resources that must physically exist
**inside each member account**. Terraform provider blocks cannot be
generated dynamically per for_each item, so this can't be one
`terraform apply`. Instead `account-baseline/` is a second, tiny root module
applied **once per account** (its own state file, keyed by
`customers/<customer>/<env>/account-baseline.tfstate`), with its AWS provider
assuming `OrganizationAccountAccessRole` into whichever `target_account_id`
you pass in. `.github/workflows/cicd.yml` drives this automatically: stage 1
applies the root module and emits an `account_matrix` output, stage 2 fans
that out into one job per account -- so adding a customer to
`customers.tfvars` is the only step needed; nothing in the pipeline itself
needs to change as `account-baseline`'s own resources grow.

## Layout

```
config.tf, variables.tf, main.tf, outputs.tf   # root: organizations + identity-center
customers.tfvars                                # the only file you edit day-to-day
modules/organizations/                          # OUs + accounts
modules/identity-center/                        # groups, users, permission sets, assignments
modules/github-oidc/                             # OIDC provider + deploy role (single account)
modules/state-backend/                          # customer app-state S3 bucket (single account)
account-baseline/                                # per-account root that calls modules/github-oidc + modules/state-backend
```

## One-time bootstrap (do this before the pipeline can run)

1. Create (or reuse) an S3 bucket + DynamoDB table in the management account
   for Terraform state/locks, set as GitHub Actions repo variables
   `TF_STATE_BUCKET` / `TF_STATE_LOCK_TABLE`.
2. Create a GitHub OIDC provider + deploy role **in the management account**
   by hand (bootstrap chicken-and-egg — this repo's own pipeline can't
   provision its own credentials). Set its ARN as the `MANAGEMENT_DEPLOY_ROLE_ARN`
   repo variable. Scope its trust policy to `repo:BookingSystemAdvancedOrg/aws-accounts:*`.
3. `cp backend.hcl.example backend.hcl`, fill in the same bucket/table, and
   run `terraform init -backend-config=backend.hcl` for local plans.

## Adding a customer

1. Add the customer name to `customers` in `customers.tfvars`.
2. Add its users to `customer_users` (usernames prefixed `a-` or `d-`).
3. Open a PR — CI plans the org/identity-center stage. Merge to `main` to
   apply it and fan out `account-baseline` into the two new accounts, which
   creates the GitHub OIDC role and the app-state S3 bucket in both.
4. Once applied, `terraform output` in each account's `account-baseline`
   state (or the CI apply log) gives you `tfstate_bucket_name` -- point the
   customer's own app repo's backend config at it.

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
- The app-state S3 bucket also carries `prevent_destroy`, same reasoning:
  dropping a customer from `customers.tfvars` must not be able to take
  their application state with it.
- The bucket has no DynamoDB lock table, per the requirement. Terraform's
  S3 backend only gets native locking (`use_lockfile = true`) on >=1.11;
  below that, or with `use_lockfile` unset, concurrent applies against the
  same customer state can race and corrupt it. If the customer's own
  pipeline runs a single serialized apply (no parallel/manual applies
  against the same state), this is a non-issue -- otherwise pin their
  Terraform to >=1.11 with `use_lockfile = true`, or this needs a lock
  table added back.
- The app-state bucket name is deterministic
  (`<customer>-<env>-tfstate-<account_id>`), not looked up automatically by
  the customer's own pipeline yet. If that manual step becomes a hassle,
  the next move is publishing it to SSM Parameter Store in the same account
  so the customer's CI can resolve it at init time instead of hardcoding it.
- Permission sets (`AdministratorAccess` / `PowerUserAccess`) are created
  once and shared across all customers; only the group -> account assignment
  is per customer, so there's no permission-set sprawl as customers grow.
