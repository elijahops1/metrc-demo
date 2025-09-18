# Azure Function App Deployment Script
# This script automates the deployment of the Stock Data Function App to Azure
# 
# Prerequisites:
# - Azure CLI installed and logged in
# - Azure Functions Core Tools installed
# - PowerShell 7+ recommended
#
# Usage: .\deploy.ps1 -FunctionAppName "your-function-app-name" -ResourceGroup "your-resource-group"

param(
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroup = "rg-stock-function",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$StorageAccountName = "",
    
    [Parameter(Mandatory=$false)]
    [string]$AlphaVantageApiKey = "demo"
)

# Function to log messages with timestamps
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
}

# Function to check if a command exists
function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Log "🚀 Starting Azure Function App deployment for Stock Data Service"

# Step 1: Validate prerequisites
Write-Log "🔍 Checking prerequisites..."

if (-not (Test-CommandExists "az")) {
    Write-Log "❌ Azure CLI not found. Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" "ERROR"
    exit 1
}

if (-not (Test-CommandExists "func")) {
    Write-Log "❌ Azure Functions Core Tools not found. Install with: npm install -g azure-functions-core-tools@4 --unsafe-perm true" "ERROR"
    exit 1
}

Write-Log "✅ Prerequisites validated"

# Step 2: Generate unique storage account name if not provided
if ([string]::IsNullOrEmpty($StorageAccountName)) {
    $StorageAccountName = "stockfunc" + (Get-Random -Minimum 1000 -Maximum 9999)
    Write-Log "📦 Generated storage account name: $StorageAccountName"
}

# Step 3: Check Azure login status
Write-Log "🔐 Checking Azure authentication..."
try {
    $account = az account show --query "user.name" -o tsv 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ Not logged in to Azure. Running 'az login'..." "WARN"
        az login
        if ($LASTEXITCODE -ne 0) {
            Write-Log "❌ Azure login failed" "ERROR"
            exit 1
        }
    }
    Write-Log "✅ Authenticated as: $account"
}
catch {
    Write-Log "❌ Azure authentication check failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Step 4: Create resource group
Write-Log "📁 Creating resource group '$ResourceGroup'..."
$rgResult = az group create --name $ResourceGroup --location $Location 2>&1
if ($LASTEXITCODE -ne 0) {
    if ($rgResult -like "*already exists*") {
        Write-Log "⚠️ Resource group already exists, continuing..." "WARN"
    } else {
        Write-Log "❌ Failed to create resource group: $rgResult" "ERROR"
        exit 1
    }
} else {
    Write-Log "✅ Resource group created successfully"
}

# Step 5: Create storage account
Write-Log "💾 Creating storage account '$StorageAccountName'..."
$storageResult = az storage account create `
    --name $StorageAccountName `
    --location $Location `
    --resource-group $ResourceGroup `
    --sku "Standard_LRS" `
    --query "provisioningState" -o tsv 2>&1

if ($LASTEXITCODE -ne 0) {
    if ($storageResult -like "*already exists*") {
        Write-Log "⚠️ Storage account already exists, continuing..." "WARN"
    } else {
        Write-Log "❌ Failed to create storage account: $storageResult" "ERROR"
        exit 1
    }
} else {
    Write-Log "✅ Storage account created successfully"
}

# Step 6: Create Function App
Write-Log "⚡ Creating Function App '$FunctionAppName'..."
$funcResult = az functionapp create `
    --resource-group $ResourceGroup `
    --consumption-plan-location $Location `
    --runtime "powershell" `
    --runtime-version "7.4" `
    --functions-version "4" `
    --name $FunctionAppName `
    --storage-account $StorageAccountName `
    --query "state" -o tsv 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Log "❌ Failed to create Function App: $funcResult" "ERROR"
    exit 1
}
Write-Log "✅ Function App created successfully"

# Step 7: Configure application settings
Write-Log "⚙️ Configuring application settings..."
$settingsResult = az functionapp config appsettings set `
    --name $FunctionAppName `
    --resource-group $ResourceGroup `
    --settings "ALPHAVANTAGE_API_KEY=$AlphaVantageApiKey" `
    --query "[?name=='ALPHAVANTAGE_API_KEY'].value" -o tsv 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Log "⚠️ Warning: Failed to set API key setting: $settingsResult" "WARN"
} else {
    Write-Log "✅ Application settings configured"
}

# Step 8: Deploy the function code
Write-Log "📦 Deploying function code..."
try {
    # Ensure we're in the correct directory
    $currentDir = Get-Location
    Write-Log "📂 Current directory: $currentDir"
    
    # Deploy using Azure Functions Core Tools
    func azure functionapp publish $FunctionAppName --powershell
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ Function deployment failed" "ERROR"
        exit 1
    }
    
    Write-Log "✅ Function code deployed successfully" "SUCCESS"
}
catch {
    Write-Log "❌ Deployment failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Step 9: Get function URL and key
Write-Log "🔗 Retrieving function URL and access key..."
try {
    # Get the default function key
    $functionKey = az functionapp keys list --name $FunctionAppName --resource-group $ResourceGroup --query "functionKeys.default" -o tsv
    
    # Construct the function URL
    $functionUrl = "https://$FunctionAppName.azurewebsites.net/api/GetStockQuote"
    
    Write-Log "✅ Deployment completed successfully!" "SUCCESS"
    Write-Log ""
    Write-Log "📋 DEPLOYMENT SUMMARY" "SUCCESS"
    Write-Log "===========================================" "SUCCESS"
    Write-Log "Function App Name: $FunctionAppName" "SUCCESS"
    Write-Log "Resource Group: $ResourceGroup" "SUCCESS"
    Write-Log "Storage Account: $StorageAccountName" "SUCCESS"
    Write-Log "Function URL: $functionUrl" "SUCCESS"
    Write-Log "Function Key: $functionKey" "SUCCESS"
    Write-Log ""
    Write-Log "🧪 TEST YOUR FUNCTION:" "SUCCESS"
    Write-Log "GET Request: $functionUrl" + "?symbol=AAPL&code=$functionKey" "SUCCESS"
    Write-Log ""
    Write-Log "📚 For more testing examples, see the README.md file" "SUCCESS"
}
catch {
    Write-Log "⚠️ Warning: Could not retrieve function key automatically. Check Azure portal." "WARN"
    Write-Log "Function URL: https://$FunctionAppName.azurewebsites.net/api/GetStockQuote" "SUCCESS"
}

Write-Log "🎉 Deployment completed! Your Stock Data Function App is ready to use." "SUCCESS"
