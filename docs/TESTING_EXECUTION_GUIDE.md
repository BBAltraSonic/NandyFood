# Flutter App Interaction Audit - Execution Guide

Complete guide for running the comprehensive interaction audit on the NandyFood Flutter app.

---

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK** (3.8.0 or higher)
   ```bash
   flutter --version
   ```

2. **Connected Device or Emulator**
   ```bash
   flutter devices
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Optional Tools**:
   - LCOV for coverage reports: `brew install lcov` (Mac) or `sudo apt-get install lcov` (Linux)
   - Maestro for UI automation: `curl -Ls https://get.mobile.dev | bash`
   - ADB for stress testing: Comes with Android SDK

---

## 📋 Complete Audit Execution

### Option 1: Run Everything (Recommended)

**Windows (PowerShell)**:
```powershell
.\scripts\run_interaction_audit.ps1
```

**Linux/Mac (Bash)**:
```bash
chmod +x scripts/run_interaction_audit.sh
./scripts/run_interaction_audit.sh
```

This runs:
1. Static analysis
2. Unit tests
3. Widget tests
4. Integration tests
5. Golden tests
6. Coverage report generation
7. Performance metrics

**Duration**: ~30-60 minutes  
**Output**: `test_results/[timestamp]/`

---

## 🧪 Individual Test Suites

### 1. Unit Tests

```bash
flutter test test/unit --coverage
```

**Duration**: ~2-5 minutes  
**Coverage**: Business logic, services, providers

### 2. Widget Tests

```bash
flutter test test/widget --coverage
```

**Duration**: ~5-10 minutes  
**Coverage**: UI components, shared widgets

### 3. Integration Tests

```bash
# All integration tests
flutter test integration_test

# Specific test file
flutter test integration_test/app_interaction_audit_test.dart

# Authentication flow only
flutter test integration_test/authentication_flow_test.dart
```

**Duration**: ~10-20 minutes  
**Requires**: Connected device/emulator

### 4. Golden Tests (Visual Regression)

```bash
# Update golden screenshots
flutter test integration_test/golden_tests --update-goldens

# Compare against goldens
flutter test integration_test/golden_tests
```

**Duration**: ~5-10 minutes  
**Output**: Screenshots in `integration_test/golden_tests/failures/`

### 5. BDD Tests (Gherkin)

```bash
# Run all BDD scenarios
flutter test integration_test/gherkin/

# Specific feature
flutter test integration_test/gherkin/features/user_authentication.feature
```

**Duration**: ~10-15 minutes  
**Human-readable**: Tests written in plain English

---

## 🎯 UI Automation Tests (Maestro)

### Installation

```bash
curl -Ls https://get.mobile.dev | bash
```

### Run Tests

```bash
# Complete user journey
maestro test .maestro/complete_user_journey.yaml

# Navigation stress test
maestro test .maestro/navigation_stress_test.yaml

# Form validation
maestro test .maestro/form_validation_test.yaml

# Gesture interactions
maestro test .maestro/gesture_interaction_test.yaml

# Run all Maestro tests
maestro test .maestro/
```

**Duration**: ~15-25 minutes  
**Advantages**: Fast, reliable, cross-platform

---

## 🔥 Stress Testing

```powershell
# Windows
.\scripts\stress_test.ps1 -Duration 300 -Iterations 100

# Linux/Mac
./scripts/stress_test.sh --duration 300 --iterations 100
```

**Tests Performed**:
1. Rapid navigation stress
2. Memory leak detection
3. Random UI interactions (Monkey)
4. Network stress (offline/online)
5. CPU performance profiling
6. Scroll performance

**Duration**: ~5-10 minutes  
**Output**: `test_results/stress_test_[timestamp]/`

---

## 📊 Coverage Report Generation

### Generate Coverage

```bash
flutter test --coverage
```

### Generate HTML Report (with LCOV)

```bash
# Linux/Mac
lcov --summary coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html  # Mac
xdg-open coverage/html/index.html  # Linux
```

### Windows (Manual)

```powershell
# View summary
type coverage\lcov.info

# For HTML report, install lcov for Windows or use online tools
```

---

## 🎨 Testing Specific Screens

### Authentication Screens

```bash
flutter test integration_test/authentication_flow_test.dart
```

### Restaurant Browsing

```bash
flutter test test/integration/restaurant_browsing_flow_test.dart
```

### Cart & Checkout

```bash
flutter test test/integration/day15_checkout_flow_test.dart
```

### Order Tracking

```bash
flutter test test/integration/order_tracking_flow_test.dart
```

---

## 🐛 Debug Mode Testing

### Run with Verbose Output

```bash
flutter test --verbose integration_test/app_interaction_audit_test.dart
```

### Run Specific Test

```bash
flutter test integration_test/app_interaction_audit_test.dart --name="Complete signup flow"
```

### Generate Timeline

```bash
flutter test --reporter json > test_results.json
```

---

## 📱 Device-Specific Testing

### Test on Specific Device

```bash
# List devices
flutter devices

# Run on specific device
flutter test integration_test --device-id=<device-id>
```

### Test Different Screen Sizes

Golden tests automatically test:
- Phone (375x667)
- iPhone 11 (414x896)
- Tablet Portrait (768x1024)
- Tablet Landscape (1024x768)

---

## 🌐 Network Conditions Testing

### Simulate Slow Network

```bash
# Using ADB (Android)
adb shell settings put global airplane_mode_on 0
adb shell svc data disable
adb shell svc wifi disable

# Re-enable
adb shell svc data enable
adb shell svc wifi enable
```

### Test Offline Mode

Run app, then toggle airplane mode manually or via ADB.

---

## 🎯 CI/CD Integration

### GitHub Actions Example

```yaml
name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test
      - uses: codecov/codecov-action@v2
        with:
          file: coverage/lcov.info
```

---

## 📈 Interpreting Results

### Test Status Indicators

- ✅ **PASSED**: Test completed successfully
- ❌ **FAILED**: Test failed, review logs
- ⚠️ **WARNING**: Test passed with warnings
- ⏭️ **SKIPPED**: Test skipped (conditional)

### Coverage Metrics

- **> 80%**: Excellent coverage
- **60-80%**: Good coverage
- **< 60%**: Needs improvement

### Performance Benchmarks

- **FPS**: Should be 55-60 FPS
- **Memory**: Should not grow >20% during normal use
- **CPU**: Should average <30%

---

## 🔍 Troubleshooting

### Common Issues

#### 1. "No connected devices"
```bash
# Check devices
flutter devices

# Start emulator
flutter emulators
flutter emulators --launch <emulator-id>
```

#### 2. "Golden test failures"
```bash
# Update goldens if UI changed intentionally
flutter test integration_test/golden_tests --update-goldens
```

#### 3. "Integration test timeout"
```bash
# Increase timeout
flutter test integration_test --timeout=5m
```

#### 4. "Supabase connection error"
- Check `.env` file has correct credentials
- Verify internet connection
- Check Supabase service status

#### 5. "Build errors"
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Test Execution Checklist

Before running audit:
- [ ] Flutter SDK installed and updated
- [ ] Device/emulator connected
- [ ] Dependencies installed (`flutter pub get`)
- [ ] `.env` file configured
- [ ] Code generation complete (`build_runner`)
- [ ] No existing build errors

During audit:
- [ ] Monitor test output for failures
- [ ] Check device doesn't sleep/disconnect
- [ ] Note any warnings or errors
- [ ] Watch for memory/performance issues

After audit:
- [ ] Review test results in `test_results/`
- [ ] Check coverage report
- [ ] Review golden test screenshots
- [ ] Address any failures
- [ ] Document issues found

---

## 📚 Additional Resources

### Documentation
- [Interaction Inventory](./INTERACTION_INVENTORY.md)
- [Audit Report Template](./FLUTTER_APP_INTERACTION_AUDIT_REPORT.md)
- [Test Helper Functions](../test/test_helper.dart)

### External Links
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Golden Toolkit](https://pub.dev/packages/golden_toolkit)
- [Patrol Testing](https://patrol.leancode.co/)
- [Maestro Mobile](https://maestro.mobile.dev/)

---

## 🎯 Best Practices

1. **Run tests frequently**: Don't wait for full audit, run tests during development
2. **Update goldens carefully**: Only update when UI changes are intentional
3. **Mock external services**: Use mocks for payment, social auth, etc.
4. **Test on real devices**: Emulators are good, but real devices are better
5. **Monitor coverage**: Aim for >80% overall coverage
6. **Automate in CI/CD**: Run tests on every commit
7. **Review failures carefully**: Understand why tests fail before fixing
8. **Keep tests maintainable**: Update tests when features change

---

## 🚀 Quick Commands Reference

```bash
# Full audit (all tests)
.\scripts\run_interaction_audit.ps1

# Quick smoke test (critical paths only)
flutter test test/integration/

# Update all goldens
flutter test --update-goldens

# Coverage report
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html

# Stress test
.\scripts\stress_test.ps1

# Maestro all flows
maestro test .maestro/

# Specific screen test
flutter test --name="Login"
```

---

**Last Updated**: 2025-10-25  
**Flutter Version**: 3.8.0  
**Maintained By**: Development Team
