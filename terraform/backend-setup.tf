# Azure Backend Storage Setup for Terraform State
# This configuration creates the necessary Azure resources for storing Terraform state remotely

# This resource group will be created manually first to host the backend storage
# It should be separate from your main application resources
resource "azurerm_resource_group" "terraform_state" {
  name     = "rg-terraform-state-${var.environment}"
  location = var.location

  tags = {
    Purpose     = "Terraform State Storage"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Storage account specifically for Terraform state files
# Using Standard_LRS (Locally Redundant Storage) which is free tier compatible
resource "azurerm_storage_account" "terraform_state" {
  name                     = "tfstate${var.environment}${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  
  # Enable versioning for state file history (optional but recommended)
  blob_properties {
    versioning_enabled = true
    
    # Automatically delete old versions after 30 days to stay within free tier
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
  }

  tags = {
    Purpose     = "Terraform State Storage"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_email
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Storage container for the state files
resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

# Output values for backend configuration
output "terraform_backend_config" {
  description = "Backend configuration values for terraform"
  value = {
    resource_group_name  = azurerm_resource_group.terraform_state.name
    storage_account_name = azurerm_storage_account.terraform_state.name
    container_name       = azurerm_storage_container.terraform_state.name
    key                  = "${var.environment}/terraform.tfstate"
  }
  sensitive = false
}

# Instructions output
output "backend_setup_instructions" {
  description = "Instructions for configuring the backend"
  value = <<-EOT
    
    Backend Setup Complete!
    
    1. Copy the backend configuration block to your main terraform configuration:
    
    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.terraform_state.name}"
        storage_account_name = "${azurerm_storage_account.terraform_state.name}"
        container_name       = "${azurerm_storage_container.terraform_state.name}"
        key                  = "${var.environment}/terraform.tfstate"
      }
    }
    
    2. Run 'terraform init' to migrate your state to Azure
    
    3. Your state file will be stored securely in Azure with versioning enabled
    
    Storage Account: ${azurerm_storage_account.terraform_state.name}
    Resource Group: ${azurerm_resource_group.terraform_state.name}
    
    Free Tier Usage: This setup uses Standard_LRS storage which is included 
    in Azure free tier (5 GB storage + 20,000 operations/month).
    
  EOT
}
