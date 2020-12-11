# *Authentication managed with environmental variables pulled from github secrets:
# ARM_TENANT_ID
# ARM_SUBSCRIPTION_ID
# ARM_CLIENT_ID
# ARM_CLIENT_SECRET -- Client Secret from Service Principal


# Create a resource groups
resource "azurerm_resource_group" "rg" {
  name     = var.prefix
  location = var.location
}

resource "azurerm_sql_server" "sqlserver" {
  name                         = "${var.prefix}-server"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.sqlserverusr.value
  administrator_login_password = data.azurerm_key_vault_secret.sqlserverpw.value
}

# Create logic apps with ARM imbedded in terraform
# MAKE SURE to replace principalId and tenantId with "":
# "identity": {
#     "principalId": "", 
#     "tenantId": "",
#     "type": "SystemAssigned"
# },

resource "azurerm_resource_group_template_deployment" "templateTEST" {
  name                = "arm-Deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental" # If set to "Complete", will blow away everything in the resource group that's not in the ARM template
  template_content    = file("${path.module}/arm/createLogicAppsTEST.json")
  parameters_content = jsonencode({ # Has to be wrapped in jsonencode given passing to .json file
    "logic_app_name" : {
      "value" : "logic-${var.prefix}"
    }
  })

}

# Output the ARM deployment information:
output "logic-app-run-AAS" {
  value = azurerm_resource_group_template_deployment.templateTEST.output_content
}

output "logic-app-run-AAS-jsonencode" {
  value = jsonendode(azurerm_resource_group_template_deployment.templateTEST.output_content)
}

resource "azurerm_resource_group_template_deployment" "ARMADF" {
  name                = "arm-adf-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_data_factory.adf] # Since the expored ARM template is not creating the ADF
  deployment_mode     = "Incremental"              # If set to "Complete", will blow away everything in the resource group that's not in the ARM template
  template_content    = file("${path.module}/adf-kjdemo/ARMTemplateForFactory.json")
  parameters_content = jsonencode({ # Has to be wrapped in jsonencode given passing to .json file
    "factoryName" : {
      "value" : "adf-${var.prefix}"
    },
    "AzureKeyVault_properties_typeProperties_baseUrl" : {
      "value" : "https://kv-demo-kja.vault.azure.net/"
    }
  })
}


# Then create a datafactory
# Create Azure Datafactory
resource "azurerm_data_factory" "adf" {
  name                = "adf-${var.prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  github_configuration {
    account_name    = "demokja"
    git_url         = "https://github.com"
    branch_name     = "holder-colab"
    repository_name = "Terraform-Github-Actions-Demo"
    root_folder     = "/ADF-ARM"
  }
}


# Create Azure Analysis Services
resource "azurerm_analysis_services_server" "analysisserver" {
  name                    = "${var.prefix}aas"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku                     = "S0"
  enable_power_bi_service = true

  ipv4_firewall_rule {
    name        = "myRule1"
    range_start = "0.0.0.0"
    range_end   = "255.255.255.255"
  }

}





#* BELOW IS USED TO CREATE A SYNAPSE POOL, TODD WALKER NOTED WE MAY BE ABLE TO SETUP ONE MANUALLU WITH THE TEAM
/*

#*** Storage account ** will most likely replace with references to existing storage accounts
resource "azurerm_storage_account" "storage" {
  name                     = "${var.prefix}storage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

#** Setting the role to permit the filestore creation
resource "azurerm_role_assignment" "role" {
	scope                = azurerm_resource_group.rg.id
	role_definition_name = "Storage Blob Data Contributor"
    principal_id         = "0b2df119-bc75-4148-a92d-b1a5c4132a7a"  #** Should be the service Principal on the resource groun and take ObjectID from Kroger to place here
}

# File system
resource "azurerm_storage_data_lake_gen2_filesystem" "filesystem" {
  name               = "filesystem"
  storage_account_id = azurerm_storage_account.storage.id
  depends_on = [azurerm_role_assignment.role]  # dependency for the role created
}


# Synapse 
resource "azurerm_synapse_workspace" "workspace" {
  name                                 = "${var.prefix}workspace"
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.filesystem.id
  sql_administrator_login              = "kjakah08"
  sql_administrator_login_password     = "123456!"
}

# Firewall rule to allow all ** May want to change before sending to Kroger...
resource "azurerm_synapse_firewall_rule" "example" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.workspace.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# 
resource "azurerm_synapse_sql_pool" "synapsepool" {
  name                 = "${var.prefix}sqlpool"
  synapse_workspace_id = azurerm_synapse_workspace.workspace.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  
  timeouts {
    create = "1h"
    delete = "1h"
	update = "1h"
  }
}

*/
