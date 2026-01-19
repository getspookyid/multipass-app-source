$ErrorActionPreference = "Stop"
Write-Host "🚀 Launching SpookyID Multipass..." -ForegroundColor Cyan

# Use absolute path found in environment
$FlutterParams = @("run")
& "C:\flutter\bin\flutter.bat" $FlutterParams

if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Run failed. Ensure Developer Mode is enabled in Windows Settings."
}
