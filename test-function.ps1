# Test script for the Stock Data Function App
# This script helps test the function locally before deployment
#
# Prerequisites:
# - Azure Functions Core Tools installed
# - PowerShell 7+ recommended
#
# Usage: .\test-function.ps1

Write-Host "🧪 Stock Data Function App - Local Testing Script" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Function to test API endpoint
function Test-StockFunction {
    param(
        [string]$BaseUrl = "http://localhost:7071/api/GetStockQuote",
        [string]$Symbol = "AAPL"
    )
    
    try {
        Write-Host "📊 Testing GET request for symbol: $Symbol" -ForegroundColor Yellow
        
        # Test GET request
        $getUrl = "$BaseUrl" + "?symbol=$Symbol"
        Write-Host "🌐 URL: $getUrl"
        
        $response = Invoke-RestMethod -Uri $getUrl -Method Get -TimeoutSec 30
        
        Write-Host "✅ GET Request Successful!" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Cyan
        $response | ConvertTo-Json -Depth 3 | Write-Host
        
        Write-Host "`n" -ForegroundColor White
        
        # Test POST request
        Write-Host "📊 Testing POST request for symbol: $Symbol" -ForegroundColor Yellow
        
        $postBody = @{
            symbol = $Symbol
        } | ConvertTo-Json
        
        $postResponse = Invoke-RestMethod -Uri $BaseUrl -Method Post -Body $postBody -ContentType "application/json" -TimeoutSec 30
        
        Write-Host "✅ POST Request Successful!" -ForegroundColor Green
        Write-Host "Response:" -ForegroundColor Cyan
        $postResponse | ConvertTo-Json -Depth 3 | Write-Host
        
        return $true
    }
    catch {
        Write-Host "❌ Test Failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to check if function app is running locally
function Test-LocalFunctionApp {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:7071/admin/host/status" -Method Get -TimeoutSec 5
        return $response.StatusCode -eq 200
    }
    catch {
        return $false
    }
}

# Main testing logic
Write-Host "🔍 Checking if Azure Functions Core Tools is running locally..."

if (Test-LocalFunctionApp) {
    Write-Host "✅ Local function app detected!" -ForegroundColor Green
    
    # Test multiple stock symbols
    $symbols = @("AAPL", "MSFT", "GOOGL", "TSLA")
    
    foreach ($symbol in $symbols) {
        Write-Host "`n===========================================" -ForegroundColor Blue
        $success = Test-StockFunction -Symbol $symbol
        if (-not $success) {
            Write-Host "❌ Test failed for symbol: $symbol" -ForegroundColor Red
        }
        Start-Sleep -Seconds 2  # Rate limiting
    }
    
    Write-Host "`n🎉 Testing completed!" -ForegroundColor Green
    Write-Host "📝 Check the function logs for detailed execution information." -ForegroundColor Yellow
}
else {
    Write-Host "❌ Local function app not running!" -ForegroundColor Red
    Write-Host "To start the function app locally:" -ForegroundColor Yellow
    Write-Host "1. Open PowerShell in the project directory" -ForegroundColor White
    Write-Host "2. Run: func start" -ForegroundColor White
    Write-Host "3. Wait for the function to initialize" -ForegroundColor White
    Write-Host "4. Run this test script again" -ForegroundColor White
}

Write-Host "`n📚 For more testing options, see the README.md file" -ForegroundColor Cyan
