# 1) Get reference to local Azure client
data "azurerm_client_config" "current" {}

# 2) Create Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${local.name}-kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7     # minimum
  purge_protection_enabled    = false # so we can fully delete it
  sku_name                    = "standard"
}

# 3) Give local client access to key vault
resource "azurerm_key_vault_access_policy" "self" {
  key_vault_id = azurerm_key_vault.kv.id
  object_id    = data.azurerm_client_config.current.object_id
  tenant_id    = data.azurerm_client_config.current.tenant_id

  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set"
  ]
}

# 4) Save random secret
resource "random_password" "kv_demo" {
  length           = 30
  special          = true
  min_numeric      = 5
  min_special      = 2
  override_special = "-_%@?"
}

resource "azurerm_key_vault_secret" "demo_secret" {
  name         = "demo-secret"
  value        = random_password.kv_demo.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.self
  ]
}
