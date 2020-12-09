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

# resource "azurerm_sql_server" "sqlserver" {
  name                         = "${var.prefix}-server"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = data.azurerm_key_vault_secret.sqlserverusr.value
  administrator_login_password = data.azurerm_key_vault_secret.sqlserverpw.value
}

# Create logic apps with ARM imbedded in terraform
resource "azurerm_resource_group_template_deployment" "templateTEST" {
  name                = "arm-Deployment"
  resource_group_name = azurerm_resource_group.rg.name
  deployment_mode     = "Incremental" # If complete, will blow away everythin in the resource group not in the ARM template
  template_content    = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "workflows_tsa_logic_dgtlbi_stage_001_name": {
            "defaultValue": "tsa-logic-dgtlbi-stage-001",
            "type": "String"
        }
    },
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Logic/workflows",
            "apiVersion": "2017-07-01",
            "name": "[parameters('workflows_tsa_logic_dgtlbi_stage_001_name')]",
            "location": "eastus2",
            "identity": {
                "principalId": "",
                "tenantId": "",
                "type": "SystemAssigned"
            },
            "properties": {
                "state": "Enabled",
                "definition": {
                    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {},
                    "triggers": {
                        "manual": {
                            "type": "Request",
                            "kind": "Http",
                            "inputs": {
                                "schema": {
                                    "properties": {
                                        "body": {
                                            "type": "string"
                                        },
                                        "callBackUri": {
                                            "type": "string"
                                        },
                                        "partition": {
                                            "type": "string"
                                        }
                                    },
                                    "type": "object"
                                }
                            }
                        }
                    },
                    "actions": {
                        "If_Processing_was_unsuccessful": {
                            "actions": {
                                "ADF_Callback_Success": {
                                    "runAfter": {},
                                    "type": "Http",
                                    "inputs": {
                                        "body": {
                                            "Output": {
                                                "PartitionExecuted": "@{triggerBody()?['partition']}"
                                            },
                                            "StatusCode": "200"
                                        },
                                        "method": "POST",
                                        "uri": "@triggerBody()?['callBackUri']"
                                    }
                                }
                            },
                            "runAfter": {
                                "Until_processing_is_finished": [
                                    "Succeeded",
                                    "Skipped",
                                    "Failed",
                                    "TimedOut"
                                ]
                            },
                            "else": {
                                "actions": {
                                    "ADF_Callback_Failure": {
                                        "runAfter": {},
                                        "type": "Http",
                                        "inputs": {
                                            "body": {
                                                "Error": {
                                                    "ErrorCode": "AasFailed",
                                                    "Message": "AAS Failed to Run"
                                                },
                                                "Output": {
                                                    "PartitionExecuted": "@{triggerBody()?['partition']}"
                                                },
                                                "StatusCode": "405"
                                            },
                                            "method": "POST",
                                            "uri": "@triggerBody()?['callBackUri']"
                                        }
                                    },
                                    "Terminate": {
                                        "runAfter": {
                                            "ADF_Callback_Failure": [
                                                "Succeeded"
                                            ]
                                        },
                                        "type": "Terminate",
                                        "inputs": {
                                            "runError": {
                                                "code": "500",
                                                "message": "Refresh failed with unknown status."
                                            },
                                            "runStatus": "Failed"
                                        }
                                    }
                                }
                            },
                            "expression": {
                                "and": [
                                    {
                                        "equals": [
                                            "@variables('processingWasSuccessful')",
                                            "@true"
                                        ]
                                    }
                                ]
                            },
                            "type": "If"
                        },
                        "Initialize_processingFinished_variable": {
                            "runAfter": {
                                "Initialize_upscalingFinished_variable": [
                                    "Succeeded"
                                ]
                            },
                            "type": "InitializeVariable",
                            "inputs": {
                                "variables": [
                                    {
                                        "name": "processingFinished",
                                        "type": "boolean",
                                        "value": "@false"
                                    }
                                ]
                            }
                        },
                        "Initialize_processingWasSuccessful_variable": {
                            "runAfter": {
                                "Initialize_processingFinished_variable": [
                                    "Succeeded"
                                ]
                            },
                            "type": "InitializeVariable",
                            "inputs": {
                                "variables": [
                                    {
                                        "name": "processingWasSuccessful",
                                        "type": "boolean",
                                        "value": "@false"
                                    }
                                ]
                            }
                        },
                        "Initialize_upscalingFinished_variable": {
                            "runAfter": {},
                            "type": "InitializeVariable",
                            "inputs": {
                                "variables": [
                                    {
                                        "name": "resourceName",
                                        "type": "boolean",
                                        "value": "@false"
                                    }
                                ]
                            }
                        },
                        "POST_Refresh": {
                            "runAfter": {
                                "Initialize_processingWasSuccessful_variable": [
                                    "Succeeded"
                                ]
                            },
                            "type": "Http",
                            "inputs": {
                                "authentication": {
                                    "audience": "https://*.asazure.windows.net",
                                    "type": "ManagedServiceIdentity"
                                },
                                "body": {
                                    "CommitMode": "transactional",
                                    "MaxParallelism": 6,
                                    "Objects": [
                                        {
                                            "database": "MVP",
                                            "partition": "Apr 2020",
                                            "table": "mvp Item"
                                        },
                                        {
                                            "database": "MVP",
                                            "partition": "Jun 2020",
                                            "table": "mvp Item"
                                        },
                                        {
                                            "database": "MVP",
                                            "partition": "Jul 2020",
                                            "table": "mvp Item"
                                        },
                                        {
                                            "database": "MVP",
                                            "partition": "Aug 2020",
                                            "table": "mvp Item"
                                        },
                                        {
                                            "database": "MVP",
                                            "partition": "Sep 2020",
                                            "table": "mvp Item"
                                        },
                                        {
                                            "database": "MVP",
                                            "partition": "Nov 2020",
                                            "table": "mvp Item"
                                        }
                                    ],
                                    "RetryCount": 3,
                                    "Type": "Full"
                                },
                                "method": "POST",
                                "uri": "https://aspaaseastus2.asazure.windows.net/servers/tsaasdgtlbistage001/models/MVP/refreshes"
                            },
                            "operationOptions": "DisableAsyncPattern"
                        },
                        "Until_processing_is_finished": {
                            "actions": {
                                "Delay_to_wait_for_processing": {
                                    "runAfter": {},
                                    "type": "Wait",
                                    "inputs": {
                                        "interval": {
                                            "count": 30,
                                            "unit": "Second"
                                        }
                                    }
                                },
                                "GET_refresh_status": {
                                    "runAfter": {
                                        "Delay_to_wait_for_processing": [
                                            "Succeeded"
                                        ]
                                    },
                                    "type": "Http",
                                    "inputs": {
                                        "authentication": {
                                            "audience": "https://*.asazure.windows.net",
                                            "type": "ManagedServiceIdentity"
                                        },
                                        "method": "GET",
                                        "uri": "@{outputs('POST_Refresh')['headers']?['Location']}"
                                    }
                                },
                                "Parse_GET_refresh_status": {
                                    "runAfter": {
                                        "GET_refresh_status": [
                                            "Succeeded"
                                        ]
                                    },
                                    "type": "ParseJson",
                                    "inputs": {
                                        "content": "@body('GET_refresh_status')",
                                        "schema": {
                                            "properties": {
                                                "currentRefreshType": {
                                                    "type": "string"
                                                },
                                                "endTime": {
                                                    "type": "string"
                                                },
                                                "startTime": {
                                                    "type": "string"
                                                },
                                                "status": {
                                                    "type": "string"
                                                },
                                                "type": {
                                                    "type": "string"
                                                }
                                            },
                                            "type": "object"
                                        }
                                    }
                                },
                                "Switch_on_processing_status": {
                                    "runAfter": {
                                        "Parse_GET_refresh_status": [
                                            "Succeeded"
                                        ]
                                    },
                                    "cases": {
                                        "inProgress": {
                                            "case": "inProgress",
                                            "actions": {}
                                        },
                                        "notStarted": {
                                            "case": "notStarted",
                                            "actions": {}
                                        },
                                        "succeeded": {
                                            "case": "succeeded",
                                            "actions": {
                                                "Set_processingFinished_variable_to_true": {
                                                    "runAfter": {},
                                                    "type": "SetVariable",
                                                    "inputs": {
                                                        "name": "processingFinished",
                                                        "value": "@true"
                                                    }
                                                },
                                                "Set_processingWasSuccessful_to_true": {
                                                    "runAfter": {
                                                        "Set_processingFinished_variable_to_true": [
                                                            "Succeeded"
                                                        ]
                                                    },
                                                    "type": "SetVariable",
                                                    "inputs": {
                                                        "name": "processingWasSuccessful",
                                                        "value": "@true"
                                                    }
                                                }
                                            }
                                        }
                                    },
                                    "default": {
                                        "actions": {
                                            "Set_processingFinished_variable_to_true_after_unknown_status": {
                                                "runAfter": {},
                                                "type": "SetVariable",
                                                "inputs": {
                                                    "name": "processingFinished",
                                                    "value": "@true"
                                                }
                                            },
                                            "Set_processingWasSuccessful_to_false": {
                                                "runAfter": {
                                                    "Set_processingFinished_variable_to_true_after_unknown_status": [
                                                        "Succeeded"
                                                    ]
                                                },
                                                "type": "SetVariable",
                                                "inputs": {
                                                    "name": "processingWasSuccessful",
                                                    "value": "@false"
                                                }
                                            }
                                        }
                                    },
                                    "expression": "@body('Parse_GET_refresh_status')?['status']",
                                    "type": "Switch"
                                }
                            },
                            "runAfter": {
                                "POST_Refresh": [
                                    "Succeeded"
                                ]
                            },
                            "expression": "@equals(variables('processingFinished'), true)",
                            "limit": {
                                "count": 1200,
                                "timeout": "PT12H"
                            },
                            "type": "Until"
                        }
                    },
                    "outputs": {}
                },
                "parameters": {}
            }
        }
    ]
}
TEMPLATE

}


# # Then create a datafactory
# # Create Azure Datafactory
# resource "azurerm_data_factory" "adf" {
#   name                = "${var.prefix}DF"
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
# }


# # Create Azure Analysis Services
# resource "azurerm_analysis_services_server" "analysisserver" {
#   name                    = "${var.prefix}aas"
#   location                = azurerm_resource_group.rg.location
#   resource_group_name     = azurerm_resource_group.rg.name
#   sku                     = "S0"
#   enable_power_bi_service = true

#   ipv4_firewall_rule {
#     name        = "myRule1"
#     range_start = "0.0.0.0"
#     range_end   = "255.255.255.255"
#   }

# }





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
