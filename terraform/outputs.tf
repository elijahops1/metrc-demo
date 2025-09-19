# Outputs for Azure Function App Infrastructure
# These outputs provide important information about the deployed resources

# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

# Storage Account Outputs
output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage_account.id
}

# Application Insights Outputs
output "application_insights_name" {
  description = "Name of the Application Insights instance"
  value       = module.application_insights.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.application_insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = module.application_insights.connection_string
  sensitive   = true
}

# Function App Outputs
output "function_app_name" {
  description = "Name of the Function App"
  value       = module.function_app.name
}

output "function_app_id" {
  description = "ID of the Function App"
  value       = module.function_app.id
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = module.function_app.function_app_url
}

output "function_app_principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = module.function_app.principal_id
}

output "service_plan_id" {
  description = "ID of the App Service Plan"
  value       = module.function_app.service_plan_id
}

output "service_plan_name" {
  description = "Name of the App Service Plan"
  value       = module.function_app.service_plan_name
}

# API Endpoint
output "api_endpoint_url" {
  description = "Complete URL for the GetStockQuote API endpoint"
  value       = "${module.function_app.function_app_url}/api/GetStockQuote"
}

# Staging Slot (if enabled)
output "staging_slot_url" {
  description = "URL of the staging slot (if enabled)"
  value       = module.function_app.staging_slot_url
}

# Terraform Backend Configuration Outputs
output "backend_config" {
  description = "Backend configuration for migrating to remote state"
  value = {
    resource_group_name  = azurerm_resource_group.terraform_state.name
    storage_account_name = azurerm_storage_account.terraform_state.name
    container_name       = azurerm_storage_container.terraform_state.name
    key                  = "${var.environment}/terraform.tfstate"
  }
}

output "backend_migration_commands" {
  description = "Commands to migrate to remote backend"
  value = <<-EOT
    
    🚀 Backend Storage Created! Next Steps:
    
    1. Uncomment the backend block in metrc-api-infrastructure.tf:
    
    backend "azurerm" {
      resource_group_name  = "${azurerm_resource_group.terraform_state.name}"
      storage_account_name = "${azurerm_storage_account.terraform_state.name}"
      container_name       = "${azurerm_storage_container.terraform_state.name}"
      key                  = "${var.environment}/terraform.tfstate"
    }
    
    2. Run: terraform init -migrate-state
    3. Answer 'yes' when prompted to migrate state
    
    📍 Backend Details:
    - Resource Group: ${azurerm_resource_group.terraform_state.name}
    - Storage Account: ${azurerm_storage_account.terraform_state.name}
    - Container: ${azurerm_storage_container.terraform_state.name}
    
  EOT
}

# Deployment Information
output "deployment_info" {
  description = "Key deployment information"
  value = {
    resource_group    = module.resource_group.name
    function_app_name = module.function_app.name
    function_app_url  = module.function_app.function_app_url
    api_endpoint_url  = "${module.function_app.function_app_url}/api/GetStockQuote"
    location          = module.resource_group.location
    environment       = var.environment
  }
}