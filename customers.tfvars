# One entry per customer. Adding a string here creates:
#   - 1 OU under workloads/<customer>
#   - 2 accounts: <customer>-dev and <customer>-prod
customers = [
  "test"
]

# Per-customer Identity Center usernames.
#   a-<name>  -> added to <customer>-admin group      -> AdministratorAccess in dev+prod
#   d-<name>  -> added to <customer>-developer group   -> PowerUserAccess in dev+prod
customer_users = {
  acme = [
    "a-lamo",
    "d-zach",
  ]
}
