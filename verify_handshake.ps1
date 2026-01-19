# verify_handshake.ps1
# Automates the SpookyID Admin Login Handshake for an autonomous AGENT.

Write-Host "🤖 Starting Autonomous Handshake Verification..." -ForegroundColor Cyan

# 1. Enable Ghost Mode
Write-Host "🕵️ Activating Ghost Mode on device..."
adb shell touch /sdcard/spooky_test_mode
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to set Diagnostic Flag"; exit 1 }

# 2. Re-install APK
Write-Host "📦 Installing Diagnostic Build..."
adb install -r android\app\build\outputs\apk\debug\app-debug.apk
if ($LASTEXITCODE -ne 0) { Write-Error "Installation failed"; exit 1 }

# 3. Inject Admin Credential (Ensures clean state)
Write-Host "🔑 Re-injecting Admin Credential..."
$json = Get-Content C:\spookyos\SpookyID\SpookyID_stack\backend\admin_credential.json -Raw -Encoding utf8
$base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
adb shell am start -n io.getspooky.multipass/io.getspooky.multipass.MainActivity --es "import_json_base64" "$base64"
Start-Sleep -Seconds 3

# 4. Navigate to Admin Login Screen
Write-Host "🚀 Launching Admin Login Flow via Deep Link..."
adb shell am start -n io.getspooky.multipass/io.getspooky.multipass.MainActivity --es "route" "/admin-login"
Start-Sleep -Seconds 3

# Find "ADMIN LOGIN" and tap
# Use uiautomator to find coordinates
Write-Host "🔍 Searching for 'ADMIN LOGIN' button..."
adb shell uiautomator dump /sdcard/view.xml
$xml = adb shell cat /sdcard/view.xml
# Search for any node containing "ADMIN LOGIN" or the resource-id of the button if known.
# Looking for text="ADMIN LOGIN" or content-desc="ADMIN LOGIN"
if ($xml -match 'text="ADMIN LOGIN".*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]' -or $xml -match 'content-desc="ADMIN LOGIN".*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
    $x = ([int]$matches[1] + [int]$matches[3]) / 2
    $y = ([int]$matches[2] + [int]$matches[4]) / 2
    Write-Host "🎯 Tapping ADMIN LOGIN at ($x, $y)"
    adb shell input tap $x $y
}
else {
    # Fallback to a common button area for the Wallet Screen layout
    Write-Warning "Could not find 'ADMIN LOGIN' button in XML. Tapping likely location (540, 2400)..."
    adb shell input tap 540 2400
}

# 5. Monitor Results
Write-Host "📡 Monitoring Logcat for Success..."
$success = $false
$timeout = 20 # seconds
$startTime = Get-Date

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    $logs = adb logcat -d -v time *:S flutter:V
    if ($logs -match "✅ ACCESS GRANTED") {
        $success = $true
        break
    }
    if ($logs -match "❌") {
        Write-Error "Handshake Failed in App Logs!"
        break
    }
    Start-Sleep -Seconds 1
}

if ($success) {
    Write-Host "🟢 SUCCESS: Autonomous Handshake Verified!" -ForegroundColor Green
}
else {
    Write-Host "🔴 FAIL: Handshake verification timed out." -ForegroundColor Red
    exit 1
}
