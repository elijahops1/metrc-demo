# Function App Module Outputs

output "name" {
  description = "Name of the Function App"
  value       = azurerm_windows_function_app.this.name
}

output "id" {
  description = "ID of the Function App"
  value       = azurerm_windows_function_app.this.id
}

output "default_hostname" {
  description = "Default hostname of the Function App"
  value       = azurerm_windows_function_app.this.default_hostname
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${azurerm_windows_function_app.this.default_hostname}"
}

output "principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = azurerm_windows_function_app.this.identity[0].principal_id
}

output "service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.this.id
}

output "service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.this.name
}

output "staging_slot_url" {
  description = "URL of the staging slot (if enabled)"
  value       = var.enable_staging_slot ? "https://${azurerm_windows_function_app_slot.staging[0].default_hostname}" : null
}
