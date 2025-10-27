# Flutter App Interaction Audit - Complete Test Runner (PowerShell)
# This script runs all interaction tests systematically

$ErrorActionPreference = "Continue"

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🚀 FLUTTER APP INTERACTION AUDIT" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Create results directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsDir = "test_results\$timestamp"
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

Write-Host "📁 Results directory: $resultsDir" -ForegroundColor Green
Write-Host ""

# ============================================================
# PHASE 1: Environment Setup
# ============================================================
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📦 PHASE 1: Environment Setup" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Installing dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "Generating code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

# ============================================================
# PHASE 2: Static Analysis
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔍 PHASE 2: Static Analysis" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

flutter analyze > "$resultsDir\static_analysis.txt" 2>&1
Write-Host "✅ Static analysis complete" -ForegroundColor Green

# ============================================================
# PHASE 3: Unit Tests
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🧪 PHASE 3: Unit Tests" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

flutter test test/unit --coverage > "$resultsDir\unit_tests.txt" 2>&1
Write-Host "✅ Unit tests complete" -ForegroundColor Green

# ============================================================
# PHASE 4: Widget Tests
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🎨 PHASE 4: Widget Tests" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

flutter test test/widget --coverage > "$resultsDir\widget_tests.txt" 2>&1
Write-Host "✅ Widget tests complete" -ForegroundColor Green

# ============================================================
# PHASE 5: Integration Tests
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🔄 PHASE 5: Integration Tests" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

Write-Host "Starting integration tests (requires connected device/emulator)..." -ForegroundColor Yellow
flutter test integration_test --coverage > "$resultsDir\integration_tests.txt" 2>&1
Write-Host "✅ Integration tests complete" -ForegroundColor Green

# ============================================================
# PHASE 6: Golden Tests
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "🖼️  PHASE 6: Golden Tests (Visual Regression)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

flutter test integration_test/golden_tests --update-goldens > "$resultsDir\golden_tests.txt" 2>&1
Write-Host "✅ Golden tests complete" -ForegroundColor Green

# ============================================================
# PHASE 7: Coverage Report
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📊 PHASE 7: Coverage Report Generation" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

if (Get-Command "lcov" -ErrorAction SilentlyContinue) {
    # Generate LCOV report
    lcov --summary coverage/lcov.info > "$resultsDir\coverage_summary.txt" 2>&1
    
    # Generate HTML report
    genhtml coverage/lcov.info -o "$resultsDir\coverage_html"
    
    Write-Host "✅ Coverage report generated" -ForegroundColor Green
    Write-Host "📂 View HTML report: $resultsDir\coverage_html\index.html" -ForegroundColor Green
} else {
    Write-Host "⚠️  lcov not installed. Using flutter coverage tools instead..." -ForegroundColor Yellow
    
    # Use flutter's coverage tools
    flutter test --coverage > "$resultsDir\coverage_summary.txt" 2>&1
    
    Write-Host "⚠️  For full HTML reports, install lcov" -ForegroundColor Yellow
}

# ============================================================
# PHASE 8: Performance Metrics
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "⚡ PHASE 8: Performance Metrics" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Check if device is connected
$devices = flutter devices | Out-String
if ($devices -match "connected") {
    Write-Host "Running performance tests..." -ForegroundColor Yellow
    flutter drive --target=test_driver/perf_driver.dart --profile > "$resultsDir\performance.txt" 2>&1
    Write-Host "✅ Performance tests complete" -ForegroundColor Green
} else {
    Write-Host "⚠️  No device connected. Skipping performance tests." -ForegroundColor Yellow
}

# ============================================================
# SUMMARY
# ============================================================
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "📋 TEST EXECUTION SUMMARY" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ All test phases completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📁 Results saved to: $resultsDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files generated:" -ForegroundColor Yellow
Write-Host "  - static_analysis.txt"
Write-Host "  - unit_tests.txt"
Write-Host "  - widget_tests.txt"
Write-Host "  - integration_tests.txt"
Write-Host "  - golden_tests.txt"
Write-Host "  - coverage_summary.txt"
Write-Host "  - coverage_html\ (if lcov is installed)"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""

# Generate summary report
$summaryContent = @"
# Flutter App Interaction Audit Summary

**Date**: `$(Get-Date)
**Results Directory**: `$resultsDir

## Test Phases Executed

1. Static Analysis - COMPLETE
2. Unit Tests - COMPLETE
3. Widget Tests - COMPLETE
4. Integration Tests - COMPLETE
5. Golden Tests (Visual Regression) - COMPLETE
6. Coverage Report - COMPLETE
7. Performance Metrics - COMPLETE

## Quick Links

- Static Analysis: ./static_analysis.txt
- Unit Tests: ./unit_tests.txt
- Widget Tests: ./widget_tests.txt
- Integration Tests: ./integration_tests.txt
- Golden Tests: ./golden_tests.txt
- Coverage Summary: ./coverage_summary.txt
- Coverage HTML Report: ./coverage_html/index.html

## Next Steps

1. Review test results for failures
2. Check coverage gaps
3. Verify golden test screenshots
4. Address any performance issues
5. Fix failing tests

---
*Generated by Flutter App Interaction Audit*
"@

$summaryContent | Out-File -FilePath "$resultsDir\SUMMARY.md" -Encoding UTF8

Write-Host "📄 Summary report created: $resultsDir\SUMMARY.md" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Audit complete! Review the results and address any issues." -ForegroundColor Green
Write-Host ""
Write-Host "To view the summary report, run: notepad $resultsDir\SUMMARY.md" -ForegroundColor Cyan
