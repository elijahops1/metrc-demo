# Metrc API App - Azure Function with Terraform & GitHub Actions

## 🎯 Overview

This project deploys a PowerShell Azure Function App that provides real-time stock market data via REST API. The infrastructure is managed using Terraform (Infrastructure as Code) and deployed via GitHub Actions (CI/CD) optimized for Azure's free tier.

## 🏗️ Architecture

```
GitHub Repository
    ├── PowerShell Function Code (GetStockQuote/)
    ├── Terraform Infrastructure (terraform/)
    └── GitHub Actions Pipeline (.github/workflows/)
         ↓
Azure Resource Group
    ├── Function App (PowerShell 7.4) [PROTECTED]
    ├── Storage Account [PROTECTED]
    ├── Application Insights [PROTECTED]
    └── App Service Plan (Consumption)
         ↓
HTTPS API Endpoint
         ↓
Alpha Vantage Stock API
```

## 📋 Prerequisites

### Required Tools
- **Azure Account**: Active subscription with credits
- **Azure CLI**: `az --version` (Install: [Azure CLI Installation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- **Terraform**: `terraform --version` >= 1.0 (Install: [Terraform Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **Git**: For repository management
- **GitHub Account**: With Actions enabled

### Required Accounts
- **Azure Subscription**: With sufficient credits for free tier resources
- **Alpha Vantage API**: Free API key from [Alpha Vantage](https://www.alphavantage.co/support/#api-key) (optional, defaults to "demo")

## 🚀 Quick Start Deployment

### Step 1: Clone and Setup Repository

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/metrc-api-app.git
cd metrc-api-app

# Verify project structure
ls -la
# Should see: GetStockQuote/, terraform/, .github/, profile.ps1, etc.
```

### Step 2: Create Azure Service Principal for GitHub Actions

```bash
# Login to Azure
az login

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "github-actions-metrc-api" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth
```

**Important**: Copy the entire JSON output - you'll need it for GitHub secrets.

### Step 3: Configure GitHub Repository Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these **Repository secrets**:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AZURE_CREDENTIALS` | JSON from Step 2 | Azure authentication for GitHub Actions |
| `ALPHAVANTAGE_API_KEY` | Your API key | Stock data API key (optional, defaults to "demo") |

**Example AZURE_CREDENTIALS format:**
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "your-client-secret",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

### Step 4: Customize Configuration (Optional)

Edit `terraform/terraform.tfvars` to customize your deployment:

```hcl
# Project configuration
project_name = "metrc-api-app"
environment  = "dev"
location     = "East US"
owner_email  = "elijah.ops1@gmail.com"

# Application Insights retention (free tier: 90 days max recommended)
app_insights_retention_days = 90

# CORS configuration - adjust for your domain requirements
cors_allowed_origins = ["*"]

# API configuration
api_timeout_seconds = 30
time_zone          = "UTC"

# Deployment features
enable_staging_slot = false  # Set to true if you want blue-green deployments
enable_deletion_protection = true  # Protect critical resources from deletion
```

### Step 5: Deploy via GitHub Actions (Automated)

```bash
# Commit any changes
git add .
git commit -m "Configure deployment for metrc-api-app"

# Push to main branch to trigger deployment
git push origin main
```

**What happens next:**
1. GitHub Actions triggers automatically
2. Tests PowerShell function code
3. Deploys infrastructure with Terraform
4. Deploys function code to Azure
5. Tests the deployed API

### Step 6: Manual Terraform Deployment (Alternative)

If you prefer manual deployment:

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment (review changes)
terraform plan

# Apply the infrastructure
terraform apply

# Get deployment outputs
terraform output function_app_url
terraform output api_endpoint_url
```

## 📚 API Documentation

### Base URL
After deployment, your API will be available at:
```
https://metrc-api-app-dev-func-XXXX.azurewebsites.net
```

### Authentication
All API calls require a function key. Get it from:
- **Azure Portal**: Function App → Functions → GetStockQuote → Function Keys
- **Terraform Output**: `terraform output function_app_default_key`

### Endpoints

#### Get Stock Quote
```http
GET /api/GetStockQuote?symbol=AAPL&code=YOUR_FUNCTION_KEY
```

**Parameters:**
- `symbol` (required): Stock ticker symbol (e.g., "AAPL", "MSFT", "GOOGL")
- `code` (required): Function access key

**Example Request:**
```bash
curl "https://metrc-api-app-dev-func-1234.azurewebsites.net/api/GetStockQuote?symbol=AAPL&code=your-function-key"
```

#### POST Request Alternative
```http
POST /api/GetStockQuote?code=YOUR_FUNCTION_KEY
Content-Type: application/json

{
  "symbol": "AAPL",
  "apikey": "your-alphavantage-key"
}
```

### Response Format

#### Success Response (HTTP 200)
```json
{
  "status": "success",
  "symbol": "AAPL",
  "timestamp": "2024-01-15T10:30:00Z",
  "data": {
    "symbol": "AAPL",
    "price": 150.25,
    "change": 2.50,
    "changePercent": "1.69",
    "previousClose": 147.75,
    "open": 148.00,
    "high": 151.00,
    "low": 147.50,
    "volume": 50000000,
    "latestTradingDay": "2024-01-15"
  }
}
```

#### Error Response (HTTP 4xx/5xx)
```json
{
  "status": "error",
  "message": "Invalid stock symbol format. Symbol must be 1-5 alphabetic characters.",
  "symbol": "INVALID123",
  "timestamp": "2024-01-15T10:30:00Z",
  "requestId": "GetStockQuote-637849234567890123"
}
```

## 🔧 Local Development & Testing

### Test Locally with Azure Functions Core Tools

```bash
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Start local function host
func start

# Test endpoints in another terminal
curl "http://localhost:7071/api/GetStockQuote?symbol=AAPL"

# Test with PowerShell
.\test-function.ps1
```

### Validate Terraform Code

```bash
cd terraform

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Plan changes
terraform plan
```

## 🔄 CI/CD Pipeline Details

### Pipeline Stages

The GitHub Actions workflow (`.github/workflows/ci-cd.yaml`) includes:

#### 1. **Test Stage** (All branches)
- Validates PowerShell syntax and logic
- Tests stock symbol validation functions
- Validates JSON configuration files

#### 2. **Infrastructure Stage** (Main branch only)
- Runs Terraform to create/update Azure resources
- Outputs function app details for deployment

#### 3. **Deploy Stage** (Main branch only)
- Packages function code
- Deploys to Azure Function App
- Tests deployed function

#### 4. **Staging Deploy** (Develop branch only)
- Deploys to staging slot for testing
- Enables blue-green deployments

### Pipeline Triggers
- **Push to `main`**: Full deployment to production
- **Push to `develop`**: Deployment to staging slot (if enabled)
- **Pull Request**: Tests only, no deployment

### Monitoring Pipeline

View pipeline status:
1. Go to your GitHub repository
2. Click **Actions** tab
3. View recent workflow runs

## 🛡️ Deletion Protection

Critical resources are protected from accidental deletion using Terraform's `prevent_destroy` lifecycle rule:

### Protected Resources
- **Storage Account**: Contains function code and runtime data
- **Application Insights**: Contains monitoring data and dashboards  
- **Function App**: The main application service

### Disabling Protection

**Temporary disable:**
```bash
# Modify terraform.tfvars
enable_deletion_protection = false

# Or override via command line
terraform destroy -var="enable_deletion_protection=false"
```

**Target specific resource:**
```bash
terraform destroy -target=azurerm_storage_account.function_storage -var="enable_deletion_protection=false"
```

## 📊 Monitoring & Observability

### Application Insights

Access monitoring via:
- **Azure Portal**: Function App → Application Insights
- **Direct URL**: Available in Terraform outputs

### Useful Queries

```kusto
// Recent function executions
requests
| where cloud_RoleName contains "metrc-api"
| where timestamp > ago(1h)
| order by timestamp desc

// Error rate analysis
requests
| where cloud_RoleName contains "metrc-api"
| summarize 
    Total = count(),
    Errors = countif(success == false),
    ErrorRate = round(countif(success == false) * 100.0 / count(), 2)
| extend ErrorPercentage = strcat(ErrorRate, "%")
```

### Health Monitoring

```bash
# Check function app status
az functionapp show --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP --query "state"

# Test function health
curl "https://YOUR_FUNCTION_APP_NAME.azurewebsites.net/api/GetStockQuote?symbol=AAPL&code=YOUR_FUNCTION_KEY"

# View logs
az functionapp log tail --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP
```

## 🔐 Security Configuration

### Function Keys Management

```bash
# List function keys
az functionapp keys list --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP

# Regenerate function key
az functionapp keys renew --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP --key-name default

# Create new function key
az functionapp keys set --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP --key-name "client-key" --key-value "your-secure-key"
```

### Update API Key

```bash
# Update Alpha Vantage API key
az functionapp config appsettings set \
  --name YOUR_FUNCTION_APP_NAME \
  --resource-group YOUR_RESOURCE_GROUP \
  --settings "ALPHAVANTAGE_API_KEY=new-api-key"
```

### Network Security (Optional)

```bash
# Add IP restrictions
az functionapp config access-restriction add \
  --name YOUR_FUNCTION_APP_NAME \
  --resource-group YOUR_RESOURCE_GROUP \
  --rule-name "AllowOffice" \
  --action Allow \
  --ip-address "203.0.113.0/24"
```

## 💰 Cost Analysis

### Azure Free Tier Resources
- **Function App**: 1 million requests/month + 400,000 GB-seconds compute
- **Storage Account**: 5GB locally redundant storage
- **Application Insights**: 5GB data ingestion/month

### Estimated Monthly Costs (beyond free tier)
- **Function App**: $0.20 per million executions + $0.000016/GB-second
- **Storage**: $0.045/GB/month
- **Application Insights**: $2.30/GB after 5GB free
- **Total Estimate**: $0-20/month for typical usage

### Cost Monitoring

```bash
# View consumption
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31

# Set up budget alerts
az consumption budget create \
  --budget-name "MetrcApiBudget" \
  --amount 50 \
  --time-grain Monthly \
  --resource-group YOUR_RESOURCE_GROUP
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Function App Won't Start
```bash
# Check function app status
az functionapp show --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP

# Check logs
az functionapp log tail --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP

# Check application settings
az functionapp config appsettings list --name YOUR_FUNCTION_APP_NAME --resource-group YOUR_RESOURCE_GROUP
```

#### 2. API Returns 500 Errors
- Check Application Insights for detailed error logs
- Verify PowerShell syntax in `GetStockQuote/run.ps1`
- Test function locally with `func start`

#### 3. GitHub Actions Fails
- Verify `AZURE_CREDENTIALS` secret format
- Check service principal permissions
- Review workflow logs in GitHub Actions tab

#### 4. Terraform Deployment Fails
```bash
# Check state
terraform show

# Refresh state
terraform refresh

# Import existing resources if needed
terraform import azurerm_resource_group.main /subscriptions/YOUR_SUB_ID/resourceGroups/YOUR_RG_NAME
```

#### 5. API Rate Limiting
- Get your own Alpha Vantage API key (free 500 calls/day)
- Implement client-side caching
- Consider upgrading to paid Alpha Vantage plan

### Debug Mode

Enable detailed logging by updating function app settings:
```bash
az functionapp config appsettings set \
  --name YOUR_FUNCTION_APP_NAME \
  --resource-group YOUR_RESOURCE_GROUP \
  --settings "AzureFunctionsJobHost__logging__logLevel__default=Information"
```

## 🔄 Maintenance & Updates

### Regular Tasks

#### Update Function Code
1. Modify PowerShell code in `GetStockQuote/`
2. Commit and push to `main` branch
3. GitHub Actions will automatically deploy

#### Update Infrastructure
1. Modify `terraform/` files
2. Commit and push to `main` branch
3. GitHub Actions will run Terraform

#### Manual Updates
```bash
# Update Terraform providers
cd terraform
terraform init -upgrade

# Update Azure CLI
az upgrade

# Update Function Core Tools
npm update -g azure-functions-core-tools@4
```

### Backup and Recovery

```bash
# Download function app content
az functionapp deployment source download \
  --name YOUR_FUNCTION_APP_NAME \
  --resource-group YOUR_RESOURCE_GROUP

# Export Terraform state
terraform show > terraform-state-backup.txt
```

## 🔄 Cleanup and Removal

### Destroy All Resources

**Option 1: Using Terraform (Recommended)**
```bash
cd terraform

# Disable deletion protection first
terraform apply -var="enable_deletion_protection=false"

# Destroy all resources
terraform destroy -auto-approve
```

**Option 2: Delete Resource Group**
```bash
# Get resource group name
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

# Delete everything
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

### Cleanup GitHub
1. Remove repository secrets (`AZURE_CREDENTIALS`, `ALPHAVANTAGE_API_KEY`)
2. Delete Azure service principal:
   ```bash
   az ad sp delete --id CLIENT_ID_FROM_CREDENTIALS
   ```

## 📞 Quick Reference Commands

### Deployment Status
```bash
# Check function app
az functionapp show --name metrc-api-app-dev-func-XXXX --resource-group metrc-api-app-dev-rg --query "state"

# Get function URL
terraform output api_endpoint_url

# Test API
curl "$(terraform output -raw function_app_url)/api/GetStockQuote?symbol=AAPL&code=YOUR_KEY"
```

### Logs and Monitoring
```bash
# Live logs
az functionapp log tail --name metrc-api-app-dev-func-XXXX --resource-group metrc-api-app-dev-rg

# Function keys
az functionapp keys list --name metrc-api-app-dev-func-XXXX --resource-group metrc-api-app-dev-rg
```

## 📚 Additional Resources

### Documentation Links
- [Azure Functions PowerShell Developer Guide](https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions for Azure](https://docs.microsoft.com/en-us/azure/developer/github/)
- [Alpha Vantage API Documentation](https://www.alphavantage.co/documentation/)

### Support Channels
- **Azure Support**: [Azure Support Plans](https://azure.microsoft.com/en-us/support/plans/)
- **Terraform Community**: [Terraform Discuss](https://discuss.hashicorp.com/c/terraform-core/27)
- **GitHub Actions**: [GitHub Community](https://github.community/)

## 🎉 Success Criteria

Your deployment is successful when:

✅ **Infrastructure**: Terraform creates all Azure resources without errors  
✅ **Pipeline**: GitHub Actions completes successfully  
✅ **Function**: Function App shows "Running" status in Azure Portal  
✅ **API**: Endpoint returns valid stock data for test symbols  
✅ **Monitoring**: Application Insights shows telemetry data  
✅ **Security**: Function keys work and deletion protection is active  

**Final Test:**
```bash
curl "https://metrc-api-app-dev-func-XXXX.azurewebsites.net/api/GetStockQuote?symbol=AAPL&code=YOUR_FUNCTION_KEY"
```

Expected response: JSON with Apple stock data and `"status": "success"`

---

## 📝 Project Structure

```
metrc-api-app/
├── .github/workflows/
│   └── ci-cd.yaml              # GitHub Actions CI/CD pipeline
├── GetStockQuote/
│   ├── function.json           # Function binding configuration
│   └── run.ps1                 # Main PowerShell function logic
├── terraform/
│   ├── modules/                # Reusable Terraform modules
│   │   ├── resource-group/     # Resource group module
│   │   │   ├── resource-group.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── storage-account/    # Storage account module
│   │   │   ├── storage-account.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── application-insights/ # Application Insights module
│   │   │   ├── application-insights.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── function-app/       # Function App module
│   │   │   ├── function-app-with-service-plan.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── README.md           # Module documentation
│   ├── metrc-api-infrastructure.tf  # Main infrastructure (uses modules)
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   └── terraform.tfvars        # Configuration values
├── host.json                   # Function app configuration
├── profile.ps1                 # Shared PowerShell functions
├── requirements.psd1           # PowerShell dependencies
├── test-function.ps1           # Local testing script
├── deploy.ps1                  # Manual deployment script (alternative)
├── local.settings.json         # Local development settings
└── README.md                   # This documentation
```

This completes your comprehensive deployment guide for the Metrc API app!
