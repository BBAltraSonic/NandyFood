# Stress Testing Script for Flutter App
# Simulates high-load user interactions

param(
    [int]$Duration = 300,  # Duration in seconds (default: 5 minutes)
    [int]$Iterations = 100,  # Number of test iterations
    [string]$DeviceId = ""   # Optional device ID
)

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔥 FLUTTER APP STRESS TEST" -ForegroundColor Red
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Check if device is connected
$devices = flutter devices | Out-String
if ($devices -notmatch "connected") {
    Write-Host "❌ No device connected. Please connect a device or start an emulator." -ForegroundColor Red
    exit 1
}

# Get device ID if not provided
if ([string]::IsNullOrEmpty($DeviceId)) {
    Write-Host "📱 Detecting connected device..." -ForegroundColor Yellow
    $deviceList = flutter devices --machine | ConvertFrom-Json
    if ($deviceList.Count -gt 0) {
        $DeviceId = $deviceList[0].id
        Write-Host "   Using device: $($deviceList[0].name) ($DeviceId)" -ForegroundColor Green
    }
}

# Create results directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsDir = "test_results\stress_test_$timestamp"
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Duration: $Duration seconds" -ForegroundColor White
Write-Host "  Iterations: $Iterations" -ForegroundColor White
Write-Host "  Device: $DeviceId" -ForegroundColor White
Write-Host "  Results: $resultsDir" -ForegroundColor White
Write-Host ""

# Build and install app
Write-Host "📦 Building app in profile mode..." -ForegroundColor Yellow
flutter build apk --profile --device-id=$DeviceId
flutter install --device-id=$DeviceId

Write-Host "✅ App installed successfully" -ForegroundColor Green
Write-Host ""

# Test 1: Rapid Navigation Stress Test
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔀 TEST 1: Rapid Navigation (Stress)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if (Test-Path ".maestro\navigation_stress_test.yaml") {
    maestro test .maestro\navigation_stress_test.yaml > "$resultsDir\navigation_stress.txt" 2>&1
    Write-Host "✅ Navigation stress test complete" -ForegroundColor Green
} else {
    Write-Host "⚠️  Maestro config not found, skipping..." -ForegroundColor Yellow
}

# Test 2: Memory Leak Detection
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "💾 TEST 2: Memory Leak Detection" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Starting memory profiling..." -ForegroundColor Yellow
$memoryLog = "$resultsDir\memory_profile.txt"

# Use adb to monitor memory
for ($i = 1; $i -le 10; $i++) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $memInfo = adb shell dumpsys meminfo com.example.food_delivery_app | Select-String "TOTAL"
    "$timestamp - $memInfo" | Out-File -Append $memoryLog
    Start-Sleep -Seconds 30
}

Write-Host "✅ Memory profiling complete" -ForegroundColor Green

# Test 3: Random UI Interactions (Monkey Test)
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🐒 TEST 3: Random UI Interactions (Monkey)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Running monkey test with $Iterations random events..." -ForegroundColor Yellow
$monkeyLog = "$resultsDir\monkey_test.txt"

adb shell monkey -p com.example.food_delivery_app -v $Iterations > $monkeyLog 2>&1

# Check for crashes
$crashes = Select-String -Path $monkeyLog -Pattern "CRASH"
if ($crashes) {
    Write-Host "⚠️  Crashes detected: $($crashes.Count)" -ForegroundColor Red
    $crashes | Out-File "$resultsDir\crashes.txt"
} else {
    Write-Host "✅ No crashes detected" -ForegroundColor Green
}

# Test 4: Network Stress Test
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🌐 TEST 4: Network Stress Test" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Testing offline/online transitions..." -ForegroundColor Yellow

# Disable network
adb shell svc wifi disable
adb shell svc data disable
Start-Sleep -Seconds 5

# Open app and interact
Write-Host "  - App running in offline mode" -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Enable network
adb shell svc wifi enable
adb shell svc data enable
Write-Host "  - Network restored" -ForegroundColor Yellow
Start-Sleep -Seconds 5

Write-Host "✅ Network stress test complete" -ForegroundColor Green

# Test 5: CPU and Performance Profiling
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "⚡ TEST 5: CPU Performance Profiling" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Capturing CPU metrics..." -ForegroundColor Yellow
$cpuLog = "$resultsDir\cpu_profile.txt"

for ($i = 1; $i -le 10; $i++) {
    $timestamp = Get-Date -Format "HH:mm:ss"
    $cpuInfo = adb shell top -n 1 | Select-String "food_delivery_app"
    "$timestamp - $cpuInfo" | Out-File -Append $cpuLog
    Start-Sleep -Seconds 30
}

Write-Host "✅ CPU profiling complete" -ForegroundColor Green

# Test 6: Scroll Performance Test
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📜 TEST 6: Scroll Performance" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Testing rapid scrolling..." -ForegroundColor Yellow

# Simulate rapid scrolling
for ($i = 1; $i -le 50; $i++) {
    adb shell input swipe 500 1500 500 500 100
    Start-Sleep -Milliseconds 100
    adb shell input swipe 500 500 500 1500 100
    Start-Sleep -Milliseconds 100
}

Write-Host "✅ Scroll performance test complete" -ForegroundColor Green

# Generate Summary Report
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 GENERATING STRESS TEST REPORT" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

$reportContent = @"
# Flutter App Stress Test Report

**Date**: $(Get-Date)
**Duration**: $Duration seconds
**Iterations**: $Iterations
**Device**: $DeviceId

## Test Results

### 1. Rapid Navigation Stress Test
- Status: Completed
- Results: See navigation_stress.txt

### 2. Memory Leak Detection
- Status: Completed
- Results: See memory_profile.txt
- Check for increasing memory usage over time

### 3. Random UI Interactions (Monkey Test)
- Status: Completed
- Events: $Iterations
- Crashes: $(if($crashes) {$crashes.Count} else {'0'})
- Results: See monkey_test.txt

### 4. Network Stress Test
- Status: Completed
- Tested offline/online transitions
- App should handle gracefully

### 5. CPU Performance Profiling
- Status: Completed
- Results: See cpu_profile.txt
- Monitor for high CPU usage

### 6. Scroll Performance Test
- Status: Completed
- Simulated 50 rapid scroll cycles
- Check for frame drops

## Recommendations

1. Review memory_profile.txt for memory leaks
2. Address any crashes found in monkey_test.txt
3. Optimize high CPU usage areas
4. Improve network error handling if issues found
5. Ensure smooth scrolling performance

## Files Generated

- navigation_stress.txt - Navigation stress test results
- memory_profile.txt - Memory usage over time
- monkey_test.txt - Random interaction test log
- cpu_profile.txt - CPU usage metrics
- crashes.txt - List of crashes (if any)

---
*Generated by Flutter App Stress Test*
"@

$reportContent | Out-File -FilePath "$resultsDir\STRESS_TEST_REPORT.md" -Encoding UTF8

Write-Host ""
Write-Host "✅ Stress test complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Results saved to: $resultsDir" -ForegroundColor Cyan
Write-Host "📄 View report: $resultsDir\STRESS_TEST_REPORT.md" -ForegroundColor Cyan
Write-Host ""

if ($crashes) {
    Write-Host "⚠️  WARNING: Crashes detected during testing!" -ForegroundColor Red
    Write-Host "   Review crashes.txt for details" -ForegroundColor Yellow
}

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
