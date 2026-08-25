# One entry per customer. Adding a string here creates:
#   - 1 OU under workloads/<customer>
#   - 2 accounts: <customer>-dev and <customer>-prod
customers = [
  "test",
  "test-2"
]

# Per-customer Identity Center usernames.
#   a-<name>  -> added to <customer>-admin group      -> AdministratorAccess in dev+prod
#   d-<name>  -> added to <customer>-developer group   -> PowerUserAccess in dev+prod
# NOTE: the same username can be listed under multiple customers -- it's
# still one Identity Center identity, just added to each customer's groups.
customer_users = {
  test = [
    "a-lamo",
    "d-zach",
  ]
  test-2 = [
    "a-lamo",
    "d-zach",
  ]
}
