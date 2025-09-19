# Azure PowerShell Function App Infrastructure
# This Terraform configuration creates all resources needed for the Metrc API Function App

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
  
  # Azure Backend Configuration for State Management
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev"
    storage_account_name = "tfstatedev1476"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    # Enable automatic deletion of resources when destroyed
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
  # Skip automatic resource provider registration
  skip_provider_registration = true
}

# Generate random suffix for globally unique names
resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

# Local values for consistent naming and configuration
locals {
  # Naming convention: project-environment-resource-suffix
  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  
  # Generate consistent names with random suffix
  resource_group_name    = "${local.project_name}-${local.environment}-rg"
  storage_account_name   = "${replace(local.project_name, "-", "")}${local.environment}sa${random_integer.suffix.result}"
  function_app_name      = "${local.project_name}-${local.environment}-func-${random_integer.suffix.result}"
  app_insights_name      = "${local.project_name}-${local.environment}-ai"
  
  # Common tags applied to all resources
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Purpose     = "Metrc API Function App"
    Owner       = var.owner_email
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
  
  # Application settings for the Function App
  function_app_settings = {
    "ALPHAVANTAGE_API_KEY"         = var.alphavantage_api_key
    "API_TIMEOUT_SECONDS"          = tostring(var.api_timeout_seconds)
    "ENVIRONMENT"                  = local.environment
    "PROJECT_NAME"                 = local.project_name
    "WEBSITE_TIME_ZONE"            = var.time_zone
  }
}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource-group"
  
  name     = local.resource_group_name
  location = local.location
  tags     = local.common_tags
}

# Storage Account Module
module "storage_account" {
  source = "./modules/storage-account"
  
  name                            = local.storage_account_name
  resource_group_name             = module.resource_group.name
  location                        = module.resource_group.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  enable_deletion_protection      = var.enable_deletion_protection
  
  tags = local.common_tags
}

# Application Insights Module
module "application_insights" {
  source = "./modules/application-insights"
  
  name                       = local.app_insights_name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  application_type           = "web"
  retention_in_days          = var.app_insights_retention_days
  enable_deletion_protection = var.enable_deletion_protection
  
  tags = local.common_tags
}

# Function App Module
module "function_app" {
  source = "./modules/function-app"
  
  name                             = local.function_app_name
  resource_group_name              = module.resource_group.name
  location                         = module.resource_group.location
  service_plan_id                  = null  # Will be created by the module
  storage_account_name             = module.storage_account.name
  storage_account_access_key       = module.storage_account.primary_access_key
  powershell_core_version          = "7.4"
  cors_allowed_origins             = var.cors_allowed_origins
  app_insights_instrumentation_key = module.application_insights.instrumentation_key
  app_insights_connection_string   = module.application_insights.connection_string
  app_settings                     = local.function_app_settings
  enable_deletion_protection       = var.enable_deletion_protection
  enable_staging_slot              = var.enable_staging_slot
  
  tags = local.common_tags
  
  depends_on = [
    module.storage_account,
    module.application_insights
  ]
}
