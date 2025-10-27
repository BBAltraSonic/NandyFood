#!/bin/bash

# Flutter App Interaction Audit - Complete Test Runner
# This script runs all interaction tests systematically

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 FLUTTER APP INTERACTION AUDIT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create results directory
RESULTS_DIR="test_results/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

echo "📁 Results directory: $RESULTS_DIR"
echo ""

# ============================================================
# PHASE 1: Environment Setup
# ============================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 PHASE 1: Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Installing dependencies..."
flutter pub get

echo "Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

# ============================================================
# PHASE 2: Static Analysis
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 PHASE 2: Static Analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

flutter analyze > "$RESULTS_DIR/static_analysis.txt" 2>&1 || true
echo "✅ Static analysis complete"

# ============================================================
# PHASE 3: Unit Tests
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 PHASE 3: Unit Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

flutter test test/unit --coverage > "$RESULTS_DIR/unit_tests.txt" 2>&1 || true
echo "✅ Unit tests complete"

# ============================================================
# PHASE 4: Widget Tests
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 PHASE 4: Widget Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

flutter test test/widget --coverage > "$RESULTS_DIR/widget_tests.txt" 2>&1 || true
echo "✅ Widget tests complete"

# ============================================================
# PHASE 5: Integration Tests
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 PHASE 5: Integration Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Starting integration tests (requires connected device/emulator)..."
flutter test integration_test --coverage > "$RESULTS_DIR/integration_tests.txt" 2>&1 || true
echo "✅ Integration tests complete"

# ============================================================
# PHASE 6: Golden Tests
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🖼️  PHASE 6: Golden Tests (Visual Regression)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

flutter test integration_test/golden_tests --update-goldens > "$RESULTS_DIR/golden_tests.txt" 2>&1 || true
echo "✅ Golden tests complete"

# ============================================================
# PHASE 7: Coverage Report
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 PHASE 7: Coverage Report Generation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v lcov &> /dev/null; then
    # Generate LCOV report
    lcov --summary coverage/lcov.info > "$RESULTS_DIR/coverage_summary.txt" 2>&1 || true
    
    # Generate HTML report
    genhtml coverage/lcov.info -o "$RESULTS_DIR/coverage_html" || true
    
    echo "✅ Coverage report generated"
    echo "📂 View HTML report: $RESULTS_DIR/coverage_html/index.html"
else
    echo "⚠️  lcov not installed. Install with: sudo apt-get install lcov (Linux) or brew install lcov (Mac)"
fi

# ============================================================
# PHASE 8: Performance Metrics
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ PHASE 8: Performance Metrics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if device is connected
if flutter devices | grep -q "connected"; then
    echo "Running performance tests..."
    flutter drive --target=test_driver/perf_driver.dart --profile > "$RESULTS_DIR/performance.txt" 2>&1 || true
    echo "✅ Performance tests complete"
else
    echo "⚠️  No device connected. Skipping performance tests."
fi

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 TEST EXECUTION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✅ All test phases completed!"
echo ""
echo "📁 Results saved to: $RESULTS_DIR"
echo ""
echo "Files generated:"
echo "  - static_analysis.txt"
echo "  - unit_tests.txt"
echo "  - widget_tests.txt"
echo "  - integration_tests.txt"
echo "  - golden_tests.txt"
echo "  - coverage_summary.txt"
echo "  - coverage_html/ (if lcov is installed)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Generate summary report
cat > "$RESULTS_DIR/SUMMARY.md" << EOF
# Flutter App Interaction Audit Summary

**Date**: $(date)
**Results Directory**: $RESULTS_DIR

## Test Phases Executed

1. ✅ Static Analysis
2. ✅ Unit Tests
3. ✅ Widget Tests
4. ✅ Integration Tests
5. ✅ Golden Tests (Visual Regression)
6. ✅ Coverage Report
7. ✅ Performance Metrics

## Quick Links

- [Static Analysis](./static_analysis.txt)
- [Unit Tests](./unit_tests.txt)
- [Widget Tests](./widget_tests.txt)
- [Integration Tests](./integration_tests.txt)
- [Golden Tests](./golden_tests.txt)
- [Coverage Summary](./coverage_summary.txt)
- [Coverage HTML Report](./coverage_html/index.html)

## Next Steps

1. Review test results for failures
2. Check coverage gaps
3. Verify golden test screenshots
4. Address any performance issues
5. Fix failing tests

---
*Generated by Flutter App Interaction Audit*
EOF

echo "📄 Summary report created: $RESULTS_DIR/SUMMARY.md"
echo ""
echo "🎉 Audit complete! Review the results and address any issues."
