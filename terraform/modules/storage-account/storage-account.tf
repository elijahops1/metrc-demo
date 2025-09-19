# Storage Account Module

resource "azurerm_storage_account" "this" {
  name                     = var.name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  
  # Security and compliance settings
  min_tls_version                 = var.min_tls_version
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  
  tags = var.tags
  
  # Prevent accidental deletion of storage account
  lifecycle {
    prevent_destroy = false
  }
}
