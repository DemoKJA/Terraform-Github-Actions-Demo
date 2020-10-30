# Retrieve already created keyvault resource 
data "azurerm_key_vault" "keyvault" {
  name                = "kv-demo-kja"
  resource_group_name = "kj-rg"
}

# Retrieve keyvault sql server username
data "azurerm_key_vault_secret" "sqlserverusr" {
  name         = "admin-demo-user"
  key_vault_id = data.azurerm_key_vault.id
}

# Retrieve keyvault sql server password
data "azurerm_key_vault_secret" "sqlserverpw" {
  name         = "admin-demo-psw"
  key_vault_id = data.azurerm_key_vault.id
}
