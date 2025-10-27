# Fix ADB and emulator issues for integration tests
# This script handles common ADB errors and prepares the device for testing

Write-Host "🔧 Fixing ADB and Device Issues..." -ForegroundColor Cyan

# Step 1: Kill any running ADB server
Write-Host "`n1️⃣ Restarting ADB server..." -ForegroundColor Yellow
adb kill-server
Start-Sleep -Seconds 2
adb start-server
Start-Sleep -Seconds 3

# Step 2: Get connected devices
Write-Host "`n2️⃣ Checking connected devices..." -ForegroundColor Yellow
$devices = adb devices | Select-String -Pattern "emulator-\d+" | ForEach-Object { $_.Matches.Value }

if ($devices.Count -eq 0) {
    Write-Host "❌ No emulator connected. Please start an emulator first." -ForegroundColor Red
    exit 1
}

# Use first available device
$deviceId = $devices[0]
Write-Host "✅ Using device: $deviceId" -ForegroundColor Green

# Step 3: Clear app data (if app exists)
Write-Host "`n3️⃣ Clearing app data..." -ForegroundColor Yellow
adb -s $deviceId shell pm clear com.example.food_delivery_app 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ App data cleared successfully" -ForegroundColor Green
} else {
    Write-Host "ℹ️ App not installed yet (this is normal)" -ForegroundColor Gray
}

# Step 4: Force uninstall if needed
Write-Host "`n4️⃣ Force uninstalling app (if exists)..." -ForegroundColor Yellow
adb -s $deviceId uninstall com.example.food_delivery_app 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ App uninstalled successfully" -ForegroundColor Green
} else {
    Write-Host "ℹ️ App was not installed (this is normal)" -ForegroundColor Gray
}

# Step 5: Clear temporary files
Write-Host "`n5️⃣ Clearing temporary cache..." -ForegroundColor Yellow
adb -s $deviceId shell pm trim-caches 1000G 2>$null

# Step 6: Verify device is ready
Write-Host "`n6️⃣ Verifying device state..." -ForegroundColor Yellow
$bootComplete = adb -s $deviceId shell getprop sys.boot_completed
if ($bootComplete -eq "1") {
    Write-Host "✅ Device is ready for testing" -ForegroundColor Green
} else {
    Write-Host "⚠️ Device may not be fully booted" -ForegroundColor Yellow
}

Write-Host "`n✅ ADB cleanup completed successfully!" -ForegroundColor Green
Write-Host "You can now run integration tests." -ForegroundColor Cyan
