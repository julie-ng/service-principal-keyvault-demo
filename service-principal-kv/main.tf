resource "azurerm_resource_group" "rg" {
  name     = "${local.name}-rg"
  location = var.location
}
