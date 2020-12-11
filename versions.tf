terraform {
  required_version = "~> 0.14.2"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.40.0"
    }
  }
}

provider azurerm {
  features {}
  skip_provider_registration = true
}
