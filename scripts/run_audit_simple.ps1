# Simplified Flutter App Interaction Audit Runner
# Runs all test phases without complex formatting

$ErrorActionPreference = "Continue"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " FLUTTER APP INTERACTION AUDIT" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create results directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsDir = "test_results\$timestamp"
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

Write-Host "Results directory: $resultsDir" -ForegroundColor Green
Write-Host ""

# PHASE 1: Environment Setup
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PHASE 1: Environment Setup" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Fix ADB issues before running tests
Write-Host "Fixing ADB and device issues..." -ForegroundColor Yellow
$adbFixScript = Join-Path $PSScriptRoot "fix_adb_issues.ps1"
if (Test-Path $adbFixScript) {
    & $adbFixScript
    Write-Host "ADB setup complete" -ForegroundColor Green
} else {
    Write-Host "Warning: ADB fix script not found, continuing anyway..." -ForegroundColor Yellow
}

Write-Host "`nInstalling dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Generating code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

# PHASE 2: Static Analysis
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PHASE 2: Static Analysis" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

flutter analyze > "$resultsDir\static_analysis.txt" 2>&1
Write-Host "Static analysis complete" -ForegroundColor Green

# PHASE 3: Unit Tests
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PHASE 3: Unit Tests" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

flutter test test/unit --coverage > "$resultsDir\unit_tests.txt" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Unit tests completed with some failures" -ForegroundColor Yellow
} else {
    Write-Host "Unit tests complete" -ForegroundColor Green
}

# PHASE 4: Widget Tests
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PHASE 4: Widget Tests" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

flutter test test/widget --coverage > "$resultsDir\widget_tests.txt" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Widget tests completed with some failures" -ForegroundColor Yellow
} else {
    Write-Host "Widget tests complete" -ForegroundColor Green
}

# PHASE 5: Integration Tests
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PHASE 5: Integration Tests" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "Starting integration tests (requires connected device/emulator)..." -ForegroundColor Yellow
flutter test integration_test --coverage > "$resultsDir\integration_tests.txt" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Integration tests completed with some failures (may need device)" -ForegroundColor Yellow
} else {
    Write-Host "Integration tests complete" -ForegroundColor Green
}

# PHASE 6: Coverage Report
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "PHASE 6: Coverage Report Generation" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

if (Test-Path "coverage\lcov.info") {
    if (Get-Command "lcov" -ErrorAction SilentlyContinue) {
        lcov --summary coverage/lcov.info > "$resultsDir\coverage_summary.txt" 2>&1
        genhtml coverage/lcov.info -o "$resultsDir\coverage_html"
        Write-Host "Coverage report generated" -ForegroundColor Green
        Write-Host "View HTML report: $resultsDir\coverage_html\index.html" -ForegroundColor Green
    } else {
        Write-Host "lcov not installed. Skipping HTML report generation." -ForegroundColor Yellow
        Copy-Item "coverage\lcov.info" "$resultsDir\coverage.lcov"
    }
} else {
    Write-Host "No coverage data found" -ForegroundColor Yellow
}

# SUMMARY
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "TEST EXECUTION SUMMARY" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "All test phases completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Results saved to: $resultsDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files generated:" -ForegroundColor Yellow
Write-Host "  - static_analysis.txt"
Write-Host "  - unit_tests.txt"
Write-Host "  - widget_tests.txt"
Write-Host "  - integration_tests.txt"
Write-Host "  - coverage_summary.txt (if lcov available)"
Write-Host "  - coverage_html\ (if lcov available)"
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create simple summary
$summary = "Flutter App Interaction Audit Summary`r`n"
$summary += "========================================`r`n`r`n"
$summary += "Date: $(Get-Date)`r`n"
$summary += "Results Directory: $resultsDir`r`n`r`n"
$summary += "Test Phases Executed:`r`n"
$summary += "1. Static Analysis - COMPLETE`r`n"
$summary += "2. Unit Tests - COMPLETE`r`n"
$summary += "3. Widget Tests - COMPLETE`r`n"
$summary += "4. Integration Tests - COMPLETE`r`n"
$summary += "5. Coverage Report - COMPLETE`r`n`r`n"
$summary += "Review individual result files for details.`r`n"

$summary | Out-File -FilePath "$resultsDir\SUMMARY.txt" -Encoding UTF8

Write-Host "Summary report created: $resultsDir\SUMMARY.txt" -ForegroundColor Green
Write-Host ""
Write-Host "Audit complete! Review the results and address any issues." -ForegroundColor Green
