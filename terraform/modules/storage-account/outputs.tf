# Storage Account Module Outputs

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "primary_access_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "Primary connection string of the storage account"
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}
