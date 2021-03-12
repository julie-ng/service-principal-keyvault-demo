output "summary" {
  value = {
    resource_group_name = azurerm_resource_group.demo.name
    key_vault           = azurerm_key_vault.kv
  }
}

output "demo_secret" {
  value = random_password.demo_sp_secret.result
}
