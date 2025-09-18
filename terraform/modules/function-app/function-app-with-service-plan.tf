# Function App Module with App Service Plan

# App Service Plan - Consumption plan for serverless scaling
resource "azurerm_service_plan" "this" {
  name                = "${var.name}-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  
  # Consumption plan settings for serverless execution
  os_type  = "Windows"  # Required for PowerShell functions
  sku_name = "Y1"       # Consumption (serverless) plan - pay per execution
  
  tags = var.tags
}

# Function App - The main PowerShell function application
resource "azurerm_windows_function_app" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  
  # Link to storage account and service plan
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  service_plan_id           = azurerm_service_plan.this.id
  
  # Function app configuration
  site_config {
    # PowerShell runtime configuration
    application_stack {
      powershell_core_version = var.powershell_core_version
    }
    
    # Performance and scaling settings
    always_on                = false  # Not available for consumption plan
    use_32_bit_worker        = false  # Use 64-bit for better performance
    ftps_state              = "Disabled"  # Disable FTP for security
    http2_enabled           = true   # Enable HTTP/2 for better performance
    
    # CORS configuration for web clients
    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = false
    }
    
    # Application Insights integration
    application_insights_key               = var.app_insights_instrumentation_key
    application_insights_connection_string = var.app_insights_connection_string
  }
  
  # Application settings (environment variables)
  app_settings = merge({
    # Azure Functions runtime settings
    "FUNCTIONS_WORKER_RUNTIME"     = "powershell"
    "FUNCTIONS_EXTENSION_VERSION"  = "~4"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
    
    # Application Insights settings
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.app_insights_instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    
    # Performance and debugging settings
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE" = "true"
  }, var.app_settings)
  
  # Enable system-assigned managed identity for Azure resource access
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
  
  # Prevent accidental deletion of the production function app
  lifecycle {
    prevent_destroy = var.enable_deletion_protection
  }
}

# Optional: Function App Slot for staging deployments
resource "azurerm_windows_function_app_slot" "staging" {
  count                      = var.enable_staging_slot ? 1 : 0
  name                       = "staging"
  function_app_id           = azurerm_windows_function_app.this.id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_access_key
  
  site_config {
    application_stack {
      powershell_core_version = var.powershell_core_version
    }
    
    always_on         = false
    use_32_bit_worker = false
    ftps_state       = "Disabled"
    http2_enabled    = true
    
    cors {
      allowed_origins     = var.cors_allowed_origins
      support_credentials = false
    }
    
    application_insights_key               = var.app_insights_instrumentation_key
    application_insights_connection_string = var.app_insights_connection_string
  }
  
  # Staging-specific app settings
  app_settings = merge({
    "FUNCTIONS_WORKER_RUNTIME"     = "powershell"
    "FUNCTIONS_EXTENSION_VERSION"  = "~4"
    "WEBSITE_RUN_FROM_PACKAGE"     = "1"
    
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = var.app_insights_instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    
    "ENVIRONMENT" = "staging"
    
    "WEBSITE_ENABLE_SYNC_UPDATE_SITE" = "true"
  }, var.app_settings)
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}
