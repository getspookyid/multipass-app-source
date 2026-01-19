$ErrorActionPreference = "Stop"
Write-Host "🚀 SpookyID Multipass Installer" -ForegroundColor Cyan

$ApkPath = "build\app\outputs\flutter-apk\app-debug.apk"
$GradlePath = "android\app\build\outputs\apk\debug\app-debug.apk"

# Check Flutter Path
if (-not (Test-Path $ApkPath)) {
    # Check Gradle Path
    if (Test-Path $GradlePath) {
        $ApkPath = $GradlePath
    }
    else {
        # Attempt build if APK missing
        Write-Host "🔨 APK not found. Attempting build..." -ForegroundColor Yellow
        python build.py build
    }
}

if (-not (Test-Path $ApkPath)) {
    # Re-check both
    if (Test-Path $GradlePath) { $ApkPath = $GradlePath }
}

if (-not (Test-Path $ApkPath)) {
    Write-Error "❌ Build failed. Please check logs."
}

Write-Host "📦 Installing to Device..." -ForegroundColor Cyan
adb install -r $ApkPath
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ SUCESS: SpookyID Multipass Installed!" -ForegroundColor Green
    Write-Host "   - Hardware Anchor: REQUIRED"
    Write-Host "   - Admin Credential: IMPORT NEEDED"
}
else {
    Write-Error "❌ Install Failed. Check USB connection."
}
