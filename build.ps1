$ErrorActionPreference = "Stop"
Write-Host "🔨 Building SpookyID Multipass APK..." -ForegroundColor Cyan

# Use absolute path found in environment
$FlutterParams = @("build", "apk", "--debug")
& "C:\flutter\bin\flutter.bat" $FlutterParams

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build Success!" -ForegroundColor Green
    Write-Host "📦 APK: build\app\outputs\flutter-apk\app-debug.apk"
} else {
    Write-Error "❌ Build failed. Ensure Developer Mode is enabled in Windows Settings."
}
