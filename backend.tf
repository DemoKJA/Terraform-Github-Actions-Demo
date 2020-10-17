provider "azurerm" {
  version = "2.31.1"
  subscription_id = var.sub
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
  features {}
}

terraform {
  backend "azurerm" {
    resource_group_name  = "kj-rg"
    storage_account_name = "kjastorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

