terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-functionapp-demo"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "funcstorage12345"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "plan" {
  name                = "function-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  os_type  = "Linux"
  sku_name = "Y1"
}

resource "azurerm_application_insights" "appi" {
  name                = "func-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "function" {
  name                = "my-linux-function-app-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  service_plan_id = azurerm_service_plan.plan.id

  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key

  functions_extension_version = "~4"

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME                  = "dotnet-isolated"
    APPLICATIONINSIGHTS_CONNECTION_STRING     = azurerm_application_insights.appi.connection_string
    WEBSITE_RUN_FROM_PACKAGE                  = "1"
  }

  https_only = true
}
