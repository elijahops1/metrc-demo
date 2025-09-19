# PowerShell Script to Setup Azure Backend for Terraform State
# This script automates the process of setting up remote state storage in Azure

param(
    [string]$Environment = "dev",
    [switch]$Force = $false
)

Write-Host "🚀 Setting up Azure Backend for Terraform State Management" -ForegroundColor Green
Write-Host "Environment: $Environment" -ForegroundColor Yellow

# Ensure we're in the terraform directory
$TerraformDir = Join-Path $PSScriptRoot "terraform"
if (-not (Test-Path $TerraformDir)) {
    Write-Error "Terraform directory not found at: $TerraformDir"
    exit 1
}

Set-Location $TerraformDir

Write-Host "`n📋 Step 1: Checking Azure CLI authentication..." -ForegroundColor Cyan
try {
    $account = az account show --output json | ConvertFrom-Json
    Write-Host "✅ Authenticated as: $($account.user.name)" -ForegroundColor Green
    Write-Host "✅ Subscription: $($account.name)" -ForegroundColor Green
}
catch {
    Write-Error "❌ Not authenticated with Azure CLI. Please run 'az login' first."
    exit 1
}

Write-Host "`n📋 Step 2: Initializing Terraform..." -ForegroundColor Cyan
terraform init
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Terraform init failed"
    exit 1
}

Write-Host "`n📋 Step 3: Planning backend storage resources..." -ForegroundColor Cyan
terraform plan -target=azurerm_resource_group.terraform_state -target=azurerm_storage_account.terraform_state -target=azurerm_storage_container.terraform_state -out=backend.tfplan
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Terraform plan failed"
    exit 1
}

Write-Host "`n📋 Step 4: Creating backend storage resources..." -ForegroundColor Cyan
if ($Force -or (Read-Host "Do you want to proceed with creating the backend storage? (y/N)") -eq 'y') {
    terraform apply backend.tfplan
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Terraform apply failed"
        exit 1
    }
} else {
    Write-Host "⏸️ Deployment cancelled by user" -ForegroundColor Yellow
    exit 0
}

Write-Host "`n📋 Step 5: Getting backend configuration..." -ForegroundColor Cyan
$backendConfig = terraform output -json terraform_backend_config | ConvertFrom-Json

Write-Host "`n✅ Backend storage created successfully!" -ForegroundColor Green
Write-Host "`n📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Add the following backend configuration to your terraform {} block in metrc-api-infrastructure.tf:" -ForegroundColor White

$backendBlock = @"

  backend `"azurerm`" {
    resource_group_name  = `"$($backendConfig.resource_group_name)`"
    storage_account_name = `"$($backendConfig.storage_account_name)`"
    container_name       = `"$($backendConfig.container_name)`"
    key                  = `"$($backendConfig.key)`"
  }
"@

Write-Host $backendBlock -ForegroundColor Cyan

Write-Host "`n2. Run 'terraform init' to migrate your state to Azure" -ForegroundColor White
Write-Host "3. Verify the migration was successful" -ForegroundColor White
Write-Host "4. Remove the local terraform.tfstate file (optional - it will be backed up)" -ForegroundColor White

Write-Host "`n💰 Cost Information:" -ForegroundColor Yellow
Write-Host "- Storage Account Type: Standard_LRS (Locally Redundant Storage)" -ForegroundColor White
Write-Host "- Free Tier Allowance: 5 GB storage + 20,000 operations/month" -ForegroundColor White
Write-Host "- Expected Usage: < 1 MB for state files (well within free tier)" -ForegroundColor White
Write-Host "- Versioning: Enabled with 30-day retention" -ForegroundColor White

Write-Host "`n🎉 Setup complete! Your Terraform state will now be stored securely in Azure." -ForegroundColor Green
