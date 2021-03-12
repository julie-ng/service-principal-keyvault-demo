# Setup
# -----
# Suffix to avoid errors on Azure resources
# that require globally unique names.

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Main
# ----

module "demo" {
  source = "./modules/service-principal-kv"
  name   = "tf-kv-demo"
  suffix = random_string.suffix.result
}

# Outputs
# -------

output "summary" {
  value = module.demo.summary
}

output "key_vault_name" {
  value = module.demo.summary.key_vault.name
}

output "demo_secret" {
  value = module.demo.demo_secret
}
