# *Authentication managed with environmental variables pulled from github secrets:
# ARM_TENANT_ID
# ARM_SUBSCRIPTION_ID
# ARM_CLIENT_ID
# ARM_SUBSCRIPTION_ID

# *Secret for storage account managed with environmental variables pulled from github secrets:
# ARM_ACCESS_KEY

terraform {
  backend "azurerm" {
    resource_group_name  = "kj-rg"
    storage_account_name = "kjastorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

