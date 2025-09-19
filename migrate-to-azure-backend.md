# Migrating Terraform State to Azure Backend

This guide walks you through setting up Azure Storage as the backend for your Terraform state files, keeping you within the Azure free tier limits.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Terraform installed
- Active Azure subscription with free tier available

## Quick Setup (Automated)

Run the PowerShell script for automated setup:

```powershell
.\setup-backend.ps1 -Environment dev
```

## Manual Setup (Step by Step)

### Step 1: Create Backend Storage Resources

First, we need to create the Azure Storage Account that will host our state files:

```bash
cd terraform
terraform init
terraform plan -target=azurerm_resource_group.terraform_state -target=azurerm_storage_account.terraform_state -target=azurerm_storage_container.terraform_state
terraform apply -target=azurerm_resource_group.terraform_state -target=azurerm_storage_account.terraform_state -target=azurerm_storage_container.terraform_state
```

### Step 2: Get Backend Configuration

After the storage resources are created, get the configuration values:

```bash
terraform output terraform_backend_config
```

This will output something like:
```
{
  "container_name" = "tfstate"
  "key" = "dev/terraform.tfstate"
  "resource_group_name" = "rg-terraform-state-dev"
  "storage_account_name" = "tfstatemetrcapiappdev1234"
}
```

### Step 3: Update Main Terraform Configuration

Add the backend configuration to your `terraform` block in `metrc-api-infrastructure.tf`:

```hcl
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
  
  # Add this backend configuration block
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state-dev"        # Replace with your output
    storage_account_name = "tfstatemetrcapiappdev1234"     # Replace with your output
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
  }
}
```

### Step 4: Migrate Existing State

Initialize Terraform with the new backend:

```bash
terraform init
```

Terraform will detect the new backend configuration and ask if you want to migrate the existing state. Type `yes` to confirm.

### Step 5: Verify Migration

Check that your state is now stored in Azure:

```bash
# Verify state is accessible
terraform plan

# Check Azure Storage (optional)
az storage blob list --container-name tfstate --account-name <your-storage-account-name>
```

### Step 6: Clean Up Local State (Optional)

After verifying the migration was successful, you can remove the local state files:

```bash
# Terraform automatically creates backups
rm terraform.tfstate.backup
rm terraform.tfstate  # Only if you're confident the migration worked
```

## Free Tier Considerations

✅ **What's included in Azure Free Tier:**
- 5 GB of Locally Redundant Storage (LRS)
- 20,000 Get/List operations per month
- Standard storage account features

✅ **Our configuration:**
- Uses Standard_LRS (included in free tier)
- Terraform state files are typically < 1 MB
- Minimal read/write operations (only during terraform runs)
- Versioning enabled with 30-day retention

✅ **Cost optimization features:**
- Automatic cleanup of old versions after 30 days
- LRS replication (cheapest option)
- Private container (no public access costs)

## Security Features

🔒 **Security measures implemented:**
- Storage account requires TLS 1.2 minimum
- Private container access only
- No public blob access allowed
- Resource lifecycle protection (prevent_destroy)
- Blob versioning for state history

## Troubleshooting

### Error: "Backend configuration changed"
If you see this error, run `terraform init -reconfigure`

### Error: "Access denied to storage account"
Ensure you're authenticated with Azure CLI: `az login`

### Error: "Storage account name already exists"
Storage account names must be globally unique. The configuration includes a random suffix to avoid conflicts.

### Reverting to Local State
If you need to revert to local state:
1. Remove the `backend` block from your terraform configuration
2. Run `terraform init`
3. Download the state from Azure if needed

## Monitoring Usage

To monitor your free tier usage:
1. Go to Azure Portal > Storage Account > Monitoring
2. Check storage usage and transaction metrics
3. Set up alerts if approaching limits

## Next Steps

After successful migration:
1. Update your deployment scripts to not include state files in version control
2. Consider setting up state locking for team environments
3. Document the backend configuration for team members
4. Set up monitoring alerts for storage usage

Your Terraform state is now securely stored in Azure with versioning and within free tier limits! 🎉
