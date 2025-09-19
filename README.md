# Metrc API Infrastructure

A PowerShell Azure Function App deployed with Terraform for stock market data APIs.

## Architecture

```
Azure Resource Group
├── Function App (PowerShell 7.4)
├── Storage Account 
├── Application Insights
└── App Service Plan (Consumption)
```

## Prerequisites

- Azure CLI (`az login`)
- Terraform >= 1.0
- Azure subscription with free tier

## Quick Deployment

### 1. Configure Variables

Edit `terraform/terraform.tfvars`:

```hcl
project_name = "your-project-name"
environment  = "dev"
location     = "East US"
owner_email  = "your-email@example.com"
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Deploy Function Code

```bash
# Navigate to function directory
cd ../GetStockQuote

# Deploy using Azure Functions Core Tools
func azure functionapp publish <function-app-name>
```

## Cost Information

**Free Tier Resources:**
- Function App: 1M executions/month
- Storage: 5 GB
- Application Insights: 5 GB data/month
- **Total Cost: $0** (within free tier limits)

## Environment Variables

The function app requires these settings (automatically configured):

- `ALPHAVANTAGE_API_KEY`: Stock API key (defaults to "demo")
- `API_TIMEOUT_SECONDS`: Request timeout (default: 30)
- `ENVIRONMENT`: Deployment environment

## API Usage

Once deployed, access the API at:

```
GET https://<function-app-name>.azurewebsites.net/api/GetStockQuote?symbol=MSFT
```

## Infrastructure Components

### Function App
- **Plan**: Consumption (Y1) - serverless
- **Runtime**: PowerShell 7.4
- **Authentication**: Anonymous for API endpoints

### Storage Account
- **Type**: Standard_LRS
- **Purpose**: Function app storage and logs
- **Security**: Private endpoints, TLS 1.2+

### Application Insights
- **Retention**: 90 days
- **Purpose**: Monitoring and telemetry
- **Integration**: Automatic function logging

## Troubleshooting

### Common Issues

**Error: "Backend initialization required"**
```bash
terraform init -reconfigure
```

**Error: "Dynamic VMs quota exceeded"**
- Request quota increase in Azure Portal
- Go to Support → Quotas → App Service → Dynamic VMs

**Error: "Storage account name already exists"**
- Storage names must be globally unique
- Edit `project_name` in `terraform.tfvars`

**Error: "Resource not found after deployment"**
```bash
# Check if resources were created
az resource list --resource-group <resource-group-name>

# Verify function app status
az functionapp show --name <function-app-name> --resource-group <resource-group-name>
```

**Function not responding**
```bash
# Check function app logs
az webapp log tail --name <function-app-name> --resource-group <resource-group-name>

# Restart function app
az functionapp restart --name <function-app-name> --resource-group <resource-group-name>
```

### State Management

**Local State (Default)**
- State stored in local `terraform.tfstate` file
- Suitable for single developer

**Azure Backend (Optional)**
- Uncomment backend block in `metrc-api-infrastructure.tf`
- Run `terraform init` to migrate state

### Cleanup

```bash
# Destroy all resources
terraform destroy

# Or destroy specific components
terraform destroy -target="module.function_app"
```

## Directory Structure

```
metrc-demo/
├── GetStockQuote/           # Function code
│   ├── function.json        # Function configuration
│   └── run.ps1             # PowerShell script
├── terraform/               # Infrastructure as Code
│   ├── metrc-api-infrastructure.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── modules/            # Reusable components
└── README.md               # This file
```

## Module Documentation

Each Terraform module includes:
- Input variables with validation
- Outputs for integration
- Lifecycle protection rules
- Comprehensive tagging

For detailed module documentation, see `terraform/modules/README.md`.