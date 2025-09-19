# Backend Configuration Template
# This file contains the backend configuration that will be added to your main terraform block
# after the backend storage resources are created

# STEP 1: First create the backend storage by running:
# terraform apply -target=azurerm_resource_group.terraform_state -target=azurerm_storage_account.terraform_state -target=azurerm_storage_container.terraform_state

# STEP 2: After backend storage is created, uncomment and add this block to your terraform {} block in metrc-api-infrastructure.tf:

/*
  backend "azurerm" {
    # These values will be populated after running the backend-setup.tf
    resource_group_name  = "rg-terraform-state-dev"
    storage_account_name = "tfstatemetrcapiappdev1234"  # This will be generated
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
*/

# STEP 3: Run 'terraform init' to migrate your existing state to the new backend
# STEP 4: Verify the state file exists in Azure Storage
# STEP 5: Remove the local terraform.tfstate file (it will be backed up automatically)

# Note: The storage account name will include a random suffix for global uniqueness
# Use 'terraform output terraform_backend_config' to get the exact values after Step 1
