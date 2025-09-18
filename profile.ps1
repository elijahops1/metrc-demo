# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper methods, run commands, or specify environment variable logic here.

# Authenticate with Azure PowerShell using MSI (Managed Service Identity).
# Remove this if you are not planning on using MSI or Azure PowerShell.
if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    Connect-AzAccount -Identity
}

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.

# Function to validate stock symbols
function Test-StockSymbol {
    param([string]$Symbol)
    
    # Basic validation: alphanumeric, 1-5 characters
    return $Symbol -match '^[A-Za-z]{1,5}$'
}

# Function to format API response consistently
function Format-StockResponse {
    param(
        [hashtable]$Data,
        [string]$Symbol,
        [string]$Status = "success"
    )
    
    return @{
        status = $Status
        symbol = $Symbol.ToUpper()
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        data = $Data
    }
}
