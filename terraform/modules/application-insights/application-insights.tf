# Application Insights Module

resource "azurerm_application_insights" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = var.application_type
  retention_in_days   = var.retention_in_days
  
  tags = var.tags
  
  # Prevent accidental deletion of monitoring data and configuration
  lifecycle {
    # prevent_destroy = true  # Commented out to allow destruction if needed
    ignore_changes = [
      workspace_id  # Ignore changes to workspace_id as it can't be removed once set
    ]
  }
}
