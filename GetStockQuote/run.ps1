# Azure PowerShell Function: GetStockQuote
# 
# This function provides real-time stock market data by calling a public API
# and returning the data to clients via HTTP trigger.
#
# Author: Azure Functions Template
# Version: 1.0
# Last Updated: September 2025

using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# ==============================================================================
# FUNCTION: Get-StockQuote
# PURPOSE: Main function to retrieve stock data from public API
# PARAMETERS: 
#   - Symbol: Stock ticker symbol (e.g., "AAPL", "MSFT")
#   - ApiKey: API key for the stock data service (optional for demo API)
# RETURNS: Formatted stock data object
# ==============================================================================

function Get-StockQuote {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Symbol,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = "demo"
    )
    
    Write-Host "📊 Starting stock data retrieval for symbol: $Symbol"
    
    try {
        # Step 1: Validate the stock symbol format
        # Stock symbols are typically 1-5 alphabetic characters
        if (-not (Test-StockSymbol -Symbol $Symbol)) {
            throw "Invalid stock symbol format. Symbol must be 1-5 alphabetic characters."
        }
        
        # Step 2: Construct the API URL
        # Using Alpha Vantage API (free tier available)
        # API Documentation: https://www.alphavantage.co/documentation/
        $baseUrl = "https://www.alphavantage.co/query"
        $function = "GLOBAL_QUOTE"  # Function to get real-time quote
        
        # Build query parameters
        $queryParams = @{
            "function" = $function
            "symbol" = $Symbol.ToUpper()
            "apikey" = $ApiKey
        }
        
        # Convert parameters to query string
        $queryString = ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
        $apiUrl = "$baseUrl?$queryString"
        
        Write-Host "🌐 API URL constructed: $apiUrl"
        
        # Step 3: Make the HTTP request to the stock API
        # Using Invoke-RestMethod for JSON response handling
        Write-Host "📡 Making API request to Alpha Vantage..."
        
        $headers = @{
            'User-Agent' = 'Azure-Functions-PowerShell/1.0'
            'Accept' = 'application/json'
        }
        
        # Execute the API call with timeout and error handling
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers -TimeoutSec 30
        
        Write-Host "✅ API response received successfully"
        
        # Step 4: Parse and validate the API response
        # Alpha Vantage returns data in "Global Quote" wrapper
        if ($response -and $response.'Global Quote') {
            $quote = $response.'Global Quote'
            
            # Extract key stock information
            $stockData = @{
                symbol = $quote.'01. symbol'
                price = [decimal]$quote.'05. price'
                change = [decimal]$quote.'09. change'
                changePercent = $quote.'10. change percent'.Replace('%', '').Replace('+', '')
                previousClose = [decimal]$quote.'08. previous close'
                open = [decimal]$quote.'02. open'
                high = [decimal]$quote.'03. high'
                low = [decimal]$quote.'04. low'
                volume = [long]$quote.'06. volume'
                latestTradingDay = $quote.'07. latest trading day'
            }
            
            Write-Host "📈 Stock data parsed successfully for $($stockData.symbol)"
            return $stockData
        }
        elseif ($response -and $response.'Error Message') {
            throw "API Error: $($response.'Error Message')"
        }
        elseif ($response -and $response.'Note') {
            throw "API Limit: $($response.'Note')"
        }
        else {
            throw "Invalid response format from API. Response: $($response | ConvertTo-Json -Depth 2)"
        }
    }
    catch {
        Write-Host "❌ Error in Get-StockQuote: $($_.Exception.Message)"
        throw $_
    }
}

# ==============================================================================
# MAIN EXECUTION BLOCK
# This block handles the HTTP request and orchestrates the response
# ==============================================================================

Write-Host "🚀 Azure Function 'GetStockQuote' triggered"
Write-Host "📝 Request Method: $($Request.Method)"
Write-Host "🔗 Request URL: $($Request.Url)"

try {
    # Step 1: Extract stock symbol from request
    # Support both GET (query parameter) and POST (JSON body) requests
    $stockSymbol = $null
    $apiKey = "demo"  # Default demo key
    
    if ($Request.Method -eq "GET") {
        # Extract from query parameters: ?symbol=AAPL&apikey=yourkey
        $stockSymbol = $Request.Query.symbol
        if ($Request.Query.apikey) {
            $apiKey = $Request.Query.apikey
        }
        Write-Host "📥 GET request - Symbol from query: $stockSymbol"
    }
    elseif ($Request.Method -eq "POST") {
        # Extract from JSON body: {"symbol": "AAPL", "apikey": "yourkey"}
        if ($Request.Body) {
            $requestBody = $Request.Body | ConvertFrom-Json
            $stockSymbol = $requestBody.symbol
            if ($requestBody.apikey) {
                $apiKey = $requestBody.apikey
            }
        }
        Write-Host "📥 POST request - Symbol from body: $stockSymbol"
    }
    
    # Step 2: Validate required parameters
    if (-not $stockSymbol) {
        $errorResponse = @{
            status = "error"
            message = "Missing required parameter: 'symbol'. Provide via query parameter (?symbol=AAPL) or JSON body {'symbol': 'AAPL'}"
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            examples = @{
                get_request = "GET /api/GetStockQuote?symbol=AAPL"
                post_request = "POST /api/GetStockQuote with body: {'symbol': 'AAPL'}"
            }
        }
        
        Write-Host "⚠️ Missing stock symbol parameter"
        
        # Return HTTP 400 Bad Request
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::BadRequest
            Headers = @{ 'Content-Type' = 'application/json' }
            Body = ($errorResponse | ConvertTo-Json -Depth 3)
        })
        return
    }
    
    # Step 3: Call the stock quote function
    Write-Host "🔄 Processing stock quote request for: $stockSymbol"
    $stockData = Get-StockQuote -Symbol $stockSymbol -ApiKey $apiKey
    
    # Step 4: Format successful response
    $successResponse = Format-StockResponse -Data $stockData -Symbol $stockSymbol -Status "success"
    
    Write-Host "✅ Stock quote retrieved successfully"
    Write-Host "💰 Price: $($stockData.price) | Change: $($stockData.change) ($($stockData.changePercent)%)"
    
    # Return HTTP 200 OK with stock data
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Headers = @{ 
            'Content-Type' = 'application/json'
            'Cache-Control' = 'no-cache'
            'Access-Control-Allow-Origin' = '*'
        }
        Body = ($successResponse | ConvertTo-Json -Depth 3)
    })
    
    Write-Host "📤 Response sent successfully"
}
catch {
    # Step 5: Handle any errors that occurred during processing
    $errorMessage = $_.Exception.Message
    Write-Host "💥 Function execution failed: $errorMessage"
    
    # Log the full error for debugging
    Write-Host "🔍 Full error details:"
    Write-Host $_.Exception.ToString()
    
    # Format error response
    $errorResponse = @{
        status = "error"
        message = $errorMessage
        symbol = $stockSymbol
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        requestId = $TriggerMetadata.sys.MethodName + "-" + (Get-Date).Ticks
    }
    
    # Determine appropriate HTTP status code based on error type
    $statusCode = [HttpStatusCode]::InternalServerError
    if ($errorMessage -like "*Invalid stock symbol*") {
        $statusCode = [HttpStatusCode]::BadRequest
    }
    elseif ($errorMessage -like "*API Limit*" -or $errorMessage -like "*API Error*") {
        $statusCode = [HttpStatusCode]::ServiceUnavailable
    }
    
    # Return appropriate error response
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $statusCode
        Headers = @{ 
            'Content-Type' = 'application/json'
            'Access-Control-Allow-Origin' = '*'
        }
        Body = ($errorResponse | ConvertTo-Json -Depth 3)
    })
}

Write-Host "🏁 Function execution completed"

# ==============================================================================
# USAGE EXAMPLES AND DOCUMENTATION
# ==============================================================================

<#
.SYNOPSIS
    Azure PowerShell Function to retrieve real-time stock market data

.DESCRIPTION
    This function calls the Alpha Vantage public API to retrieve stock quotes
    and returns formatted JSON data to HTTP clients. It supports both GET and
    POST requests and includes comprehensive error handling.

.PARAMETER symbol
    Stock ticker symbol (e.g., "AAPL", "MSFT", "GOOGL")
    Required parameter that can be passed via query string or JSON body

.PARAMETER apikey
    Alpha Vantage API key (optional, defaults to "demo" for testing)
    For production use, obtain a free API key from https://www.alphavantage.co/support/#api-key

.EXAMPLE
    GET Request:
    https://your-function-app.azurewebsites.net/api/GetStockQuote?symbol=AAPL

.EXAMPLE
    POST Request:
    URL: https://your-function-app.azurewebsites.net/api/GetStockQuote
    Body: {"symbol": "MSFT", "apikey": "your-api-key"}

.EXAMPLE
    Response Format:
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

.NOTES
    - Function requires internet connectivity to call Alpha Vantage API
    - Demo API key has rate limits (5 calls per minute, 500 calls per day)
    - For production use, register for a free API key at Alpha Vantage
    - Function includes CORS headers for web client compatibility
    - All errors are logged to Azure Functions logs for monitoring

.LINK
    Alpha Vantage API Documentation: https://www.alphavantage.co/documentation/
    Azure Functions PowerShell Guide: https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell
#>
