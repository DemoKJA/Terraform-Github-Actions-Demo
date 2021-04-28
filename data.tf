# Retrieve already created keyvault resource 
data "azurerm_key_vault" "keyvault" {
  name                = "kv-demo-kja"
  resource_group_name = "kja-rg"
}

# Secrets
# admin-demo-user: demoadmin
# admin-demo-psw: demoP@$$word

# Retrieve keyvault sql server username
data "azurerm_key_vault_secret" "sqlserverusr" {
  name         = "admin-demo-user"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

# Retrieve keyvault sql server password
data "azurerm_key_vault_secret" "sqlserverpw" {
  name         = "admin-demo-psw"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}

# Retrieve keyvault sql-mi password
data "azurerm_key_vault_secret" "sqlmipw" {
  name         = "sql-mi-passwod"
  key_vault_id = data.azurerm_key_vault.keyvault.id
}


data "azurerm_subnet" "sql-mi-subnet" {
  name                 = "ManagedInstances"
  virtual_network_name = "KJVNet-mi-manually"
  resource_group_name  = var.prefix
}

# Attempt to retrieve objectID and applicationID for Active Directory:
# data "azuread_application" "logicappdata" {
#   depends_on = [azurerm_resource_group_template_deployment.templateTEST]
#   name       = "logic-${var.prefix}"

# }

# Logic appp data with ips
# data "azurerm_logic_app_workflow" "example" {
#   name                = "logic-${var.prefix}"
#   resource_group_name = azurerm_resource_group.rg.name
#   depends_on          = [azurerm_template_deployment.templateTEST]
# }

