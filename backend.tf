terraform {
  backend "azurerm" {
    resource_group_name  = "kj-rg"
    storage_account_name = "kjastorage"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    secret_key           = "qLmeOPsUrdUvacz8pR1AsYML0Tg2pMg4lCqyik3fH2qHVN3RqRY6hgOWgROJbvaAzs7vRSAL5f9ruxHqRmIFLg=="
  }
}

