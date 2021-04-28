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


resource "azurerm_resource_group_template_deployment" "managed-instance" {
  name                = "${var.prefix}-mi-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_content    = file("${path.module}/arm/sql-managed-instance.json")
  parameters_content  = <<TEMPLATE
{
    "managedInstanceName": {
        "value": "${var.prefix}-mi"
    },
    "location": {
        "value": "eastus2"
    },
    "skuName": {
        "value": "GP_Gen5"
    },
    "skuEdition": {
        "value": "GeneralPurpose"
    },
    "administratorLogin": {
        "value": "miadmin"
    },
    "administratorLoginPassword": {
        "value":"${data.azurerm_key_vault_secret.sqlmipw.value}"
    },
    "subnetId": {
        "value": "${data.azurerm_subnet.sql-mi-subnet.id}"
    },
    "storageSizeInGB": {
        "value": 32
    },
    "vCores": {
        "value": 4
    },
    "licenseType": {
        "value": "BasePrice"
    },
    "hardwareFamily": {
        "value": "Gen5"
    },
    "dnsZonePartner": {
        "value": ""
    },
    "collation": {
        "value": "SQL_Latin1_General_CP1_CI_AS"
    },
    "proxyOverride": {
        "value": "Proxy"
    },
    "publicDataEndpointEnabled": {
        "value": false
    },
    "minimalTlsVersion": {
        "value": "1.2"
    },
    "timezoneId": {
        "value": "UTC"
    },
    "storageAccountType": {
        "value": "GRS"
    }
}
TEMPLATE
  # depends_on = [
  #     # you probably need this for dependency management
  #     azurerm_key_vault_secret.password,
  # ]
  timeouts {
    create = "8h"
  }
}

/*
# Create Archive Storage account 
resource "azurerm_storage_account" "storageacc2" {
  name                      = "${var.org}dlsdgtlbi${var.environment}002"
  resource_group_name       = azurerm_resource_group.rg.name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  is_hns_enabled            = "true" # for datalake gen2
  enable_https_traffic_only = "true"
  min_tls_version           = "TLS1_0"
  allow_blob_public_access  = "true"

  /*removed for azure machine learning
  network_rules {
    default_action             = "Deny"
    bypass                     = var.bypass
    ip_rules                   = local.ip_whitelist
    virtual_network_subnet_ids = concat(var.subnet_ids, [azurerm_subnet.dbw_public_subnet.id])
  }
  
}
*/


/*
# Create Azure Analysis Services
resource "azurerm_analysis_services_server" "analysisserver" {
  name                    = "${var.prefix}aas"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku                     = "S0"
  enable_power_bi_service = true

  lifecycle {
    ignore_changes = [admin_users, ipv4_firewall_rule]
  }

}
*/


# resource "azurerm_sql_server" "sqlserver" {
#   name                         = "${var.prefix}-server"
#   resource_group_name          = azurerm_resource_group.rg.name
#   location                     = azurerm_resource_group.rg.location
#   version                      = "12.0"
#   administrator_login          = data.azurerm_key_vault_secret.sqlserverusr.value
#   administrator_login_password = data.azurerm_key_vault_secret.sqlserverpw.value
# }



/*
# Below is for the new version AzueRM 3, but has bugs 
# Create logic apps with ARM imbedded in terraform, overloading the Terraform managed one
# 1) Create a logic app with the same name as the one managed in ARM template passing parameter to it
# 2) In ARM template replace principalId and tenantId with "" AND remove the 'defaultValue' line within the variables
# and make sure to :
# "identity": {
#     "principalId": "", 
#     "tenantId": "",
#     "type": "SystemAssigned"
# },
# 3) Is ARM template, need to replace defaultValue in paramters with a paramterized variable passed ie. 
# "logic_app_name": {
#     "type": "string",
#     "defaultValue": "${logicappname}"
# }
# See below:
resource "azurerm_resource_group_template_deployment" "templateTEST" {
  name                = "arm-Deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental"
  template_content = templatefile("${path.module}/arm/createLogicAppsTEST.json", { # check within the 
    logicappname = "logic-${var.prefix}"
  })
  depends_on = [azurerm_logic_app_workflow.logicappaas]
}
*/

# resource "azurerm_template_deployment" "templateTEST" {
#   name                = "arm-Deployment"
#   depends_on          = [azurerm_logic_app_workflow.logicappaas]
#   resource_group_name = azurerm_resource_group.rg.name
#   deployment_mode     = "Incremental"
#   template_body       = file("${path.module}/arm/createLogicAppsTEST.json")
#   parameters = {
#     "workflows_logic_kjdemo_name" = "logic-${var.prefix}"
#   }

# }


# # Create teh terraform managed logic app
# resource "azurerm_logic_app_workflow" "logicappaas" {
#   name                = "logic-${var.prefix}" # added as it will refresh analysis services model 
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }

# Below now in own project
/*
resource "azurerm_template_deployment" "ARMADF" {
  name                = "arm-adf-deployment"
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [azurerm_data_factory.adf] # Since the expored ARM template is not creating the ADF
  deployment_mode     = "Incremental"              # If set to "Complete", will blow away everything in the resource group that's not in the ARM template
  template_body       = file("${path.module}/adf-kjdemo/ARMTemplateForFactory.json")
  parameters = { # Has to be wrapped in jsonencode given passing to .json file
    "factoryName"                                     = "adf-${var.prefix}"
    "AzureKeyVault_properties_typeProperties_baseUrl" = "https://kv-demo-kja.vault.azure.net/"
  }
}
*/

# # Then create a datafactory
# # Create Azure Datafactory
# resource "azurerm_data_factory" "adf" {
#   name                = "adf-${var.prefix}"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   identity {
#     type = "SystemAssigned"
#   }


# For "branch_name", it's the branch where actual version and work is done, note the 'main' branch, 
# which is what will be used to publich ARM template to envionrmenets in terraform.
# *** For handling different tiers, ie. dev,stage, prod, paramterize their own branch, see below, but publish from
# only the tier you want to then be published in terraform. If do not have different collab brnaches accross tiers,
# then all tier, dev, stage, prod, will share a branch and any update on one will automativally be updated on all!!! 

# As for the folder structure in 'main', it will take the 

# lifecycle {
#   ignore_changes = [github_configuration]
# }
# dynamic "github_configuration" {
#   for_each = var.adf_git ? [1] : []
#   content {
#     account_name    = "demokja"
#     git_url         = "https://github.com"
#     branch_name     = "colab"
#     repository_name = "Datafactory-Standalone"
#     root_folder     = "/ADF-ARM"
#   }

# }


# }



/*
# Create Azure Analysis Services
resource "azurerm_analysis_services_server" "analysisserver" {
  name                    = "${var.prefix}aas"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  sku                     = "S0"
  enable_power_bi_service = true
  admin_users             = ["kimiebi.akah@insight.com"]
  depends_on              = [azurerm_template_deployment.templateTEST]


  ipv4_firewall_rule {
    name        = "testRuleIP1"
    range_start = element(data.azurerm_logic_app_workflow.example.workflow_outbound_ip_addresses, 0)
    range_end   = element(data.azurerm_logic_app_workflow.example.workflow_outbound_ip_addresses, 0)
  }


  ipv4_firewall_rule {
    name        = "testRuleIP2"
    range_start = element(data.azurerm_logic_app_workflow.example.workflow_outbound_ip_addresses, 1)
    range_end   = element(data.azurerm_logic_app_workflow.example.workflow_outbound_ip_addresses, 1)
  }

}
*/




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
