# NandyFood - Run with Runtime Logs
# This script runs the app and captures detailed terminal logs

Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "        🚀 NANDYFOOD - RUNTIME LOGS VIEWER            " -ForegroundColor Cyan  
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is installed
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Flutter found" -ForegroundColor Green
Write-Host ""

# Show available devices
Write-Host "Available devices:" -ForegroundColor Yellow
flutter devices
Write-Host ""

# Ask user for device choice
Write-Host "Choose device:" -ForegroundColor Cyan
Write-Host "  1. Chrome (fastest, recommended)" -ForegroundColor White
Write-Host "  2. Android Emulator" -ForegroundColor White
Write-Host "  3. Windows Desktop" -ForegroundColor White
Write-Host ""
$choice = Read-Host "Enter choice (1-3)"

switch ($choice) {
    "1" { 
        $device = "chrome"
        Write-Host "✅ Selected: Chrome" -ForegroundColor Green
    }
    "2" { 
        $device = "emulator-5554"
        Write-Host "✅ Selected: Android Emulator" -ForegroundColor Green
        Write-Host "⚠️  Make sure emulator is running!" -ForegroundColor Yellow
    }
    "3" { 
        $device = "windows"
        Write-Host "✅ Selected: Windows Desktop" -ForegroundColor Green
    }
    default {
        $device = "chrome"
        Write-Host "⚠️  Invalid choice, defaulting to Chrome" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "             STARTING APP WITH LOGS                    " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Watch for these logs:" -ForegroundColor Yellow
Write-Host "   🔷 INIT    - Initialization steps" -ForegroundColor Cyan
Write-Host "   ✅ SUCCESS - Successful operations" -ForegroundColor Green
Write-Host "   ❌ ERROR   - Errors and failures" -ForegroundColor Red
Write-Host "   ⚠️  WARNING - Non-critical issues" -ForegroundColor Yellow
Write-Host "   📘 INFO    - General information" -ForegroundColor Blue
Write-Host "   🔍 DEBUG   - Detailed debug info" -ForegroundColor Magenta
Write-Host "   ⏱️  PERF    - Performance metrics" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the app" -ForegroundColor Yellow
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Run Flutter with logs
$logFile = "runtime_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Write-Host "💾 Logs will also be saved to: $logFile" -ForegroundColor Green
Write-Host ""

# Run the app and tee output to both console and file
flutter run -d $device 2>&1 | Tee-Object -FilePath $logFile

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "                   SESSION ENDED                       " -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 Logs saved to: $logFile" -ForegroundColor Green
Write-Host ""
