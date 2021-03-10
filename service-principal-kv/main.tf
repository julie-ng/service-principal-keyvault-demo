# Resource Group
# --------------

resource "azurerm_resource_group" "demo" {
  name     = "${local.name}-rg"
  location = var.location
}

# Service Principal
# -----------------

# 1) Create an "App Registrations" in Azure AD with random password
resource "azuread_application" "demo_app_registration" {
  display_name = "${local.name}-rg-sp"

  depends_on = [
    azurerm_resource_group.demo
  ]
}

resource "random_password" "demo_sp_secret" {
  length           = 30
  special          = true
  min_numeric      = 5
  min_special      = 2
  override_special = "-_%@?"
}

resource "azuread_application_password" "demo_sp_secret" {
  application_object_id = azuread_application.demo_app_registration.object_id
  value                 = random_password.demo_sp_secret.result
  end_date_relative     = "168h" # 7 days
}

# 2) Reference AAD App Registration as Service Principal for next step
resource "azuread_service_principal" "demo_sp" {
  application_id = azuread_application.demo_app_registration.application_id
}

# 3) Scope Service Principal to Resource Group
resource "azurerm_role_assignment" "demo_sp" {
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.demo_sp.id
  scope                = azurerm_resource_group.demo.id
}

# Key Vault
# ---------

# 1) Get reference to local Azure client
data "azurerm_client_config" "current" {}

# 2) Create Key Vault
resource "azurerm_key_vault" "kv" {
  name                        = "${local.name}-kv"
  location                    = azurerm_resource_group.demo.location
  resource_group_name         = azurerm_resource_group.demo.name
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

# 4) Store Service Principal client ID and secret in Key Vault
# Note: we need to wait for access policy before we can add secrets

resource "azurerm_key_vault_secret" "demo_sp_client_id" {
  name         = "demo-sp-client-id"
  value        = azuread_application.demo_app_registration.application_id
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.self
  ]
}

resource "azurerm_key_vault_secret" "demo_sp_client_secret" {
  name         = "demo-sp-client-secret"
  value        = random_password.demo_sp_secret.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_key_vault_access_policy.self
  ]
}
