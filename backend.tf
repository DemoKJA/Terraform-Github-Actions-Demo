terraform {
  backend "azurerm" {
    resource_group_name  = "kj-rg"
    storage_account_name = "kjastorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    access_key           = ARM_ACCESS_KEY
  }
}

