# How to Run Flutter App Interaction Audit

## 🚀 Quick Command

```powershell
.\scripts\run_audit_simple.ps1
```

## 📋 What It Does

The audit automatically runs:

1. **Static Analysis** - Checks code quality (50 issues found)
2. **Unit Tests** - Tests business logic
3. **Widget Tests** - Tests UI components
4. **Integration Tests** - Tests end-to-end flows
5. **Coverage Report** - Generates HTML coverage report

## ⏱️ Expected Duration

- **Quick run**: ~5-10 minutes (without integration tests)
- **Full audit**: ~15-30 minutes (with all tests)
- **With device**: Add 10-15 minutes for integration tests

## 📁 Results Location

Results are saved with timestamp:
```
test_results/YYYYMMDD_HHMMSS/
├── static_analysis.txt
├── unit_tests.txt
├── widget_tests.txt
├── integration_tests.txt
├── coverage_summary.txt
├── coverage_html/          (if lcov installed)
└── SUMMARY.txt
```

## 📊 Current Audit Status

**Last Run**: 2025-10-25 18:32:55

✅ Phase 1: Environment Setup - COMPLETE  
✅ Phase 2: Static Analysis - COMPLETE (50 issues)  
✅ Phase 3: Unit Tests - COMPLETE (some failures)  
✅ Phase 4: Widget Tests - COMPLETE (some failures)  
🔄 Phase 5: Integration Tests - RUNNING (needs device)  

## 🔍 View Results

### View Summary
```powershell
notepad test_results\20251025_183255\SUMMARY.txt
```

### View Specific Results
```powershell
# Static analysis
notepad test_results\20251025_183255\static_analysis.txt

# Unit tests
notepad test_results\20251025_183255\unit_tests.txt

# Widget tests
notepad test_results\20251025_183255\widget_tests.txt

# Coverage (if available)
start test_results\20251025_183255\coverage_html\index.html
```

## 📱 Integration Tests

Integration tests require a connected device or emulator.

### Check if Device is Connected
```bash
flutter devices
```

### Start Emulator (if needed)
```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

### Run Integration Tests Separately
```bash
flutter test integration_test
```

## 🔄 Re-run Anytime

You can run the audit as many times as needed:

```powershell
# Full audit
.\scripts\run_audit_simple.ps1

# Only specific tests
flutter test test/unit
flutter test test/widget
flutter test integration_test
flutter analyze
```

## 📈 Understanding Results

### Static Analysis
- **50 issues found**: Warnings and info about code quality
- Most are minor (prefer_null_aware_method_calls, etc.)
- Review: `test_results\[timestamp]\static_analysis.txt`

### Test Results
- **PASSED**: All tests passed ✅
- **FAILED**: Some tests failed ❌
- **SKIPPED**: Tests were skipped ⏭️

### Coverage
- Target: **>80% coverage**
- View HTML report for line-by-line coverage
- Identify untested areas

## 🐛 Common Issues

### "No device connected"
**Solution**: Start an emulator or connect a physical device

### "lcov not installed"
**Solution**: Coverage report saved as LCOV file (coverage.lcov)
- Install lcov for HTML reports (optional)

### "Tests failing"
**Solution**: Check individual test logs for details
- Unit test failures: Business logic issues
- Widget test failures: UI component issues
- Integration test failures: Often need device/mocks

## 📚 Full Documentation

See detailed guides:
- **[AUDIT_COMPLETE.md](./AUDIT_COMPLETE.md)** - Complete summary
- **[QUICK_START_TESTING.md](./QUICK_START_TESTING.md)** - Quick reference
- **[docs/TESTING_EXECUTION_GUIDE.md](./docs/TESTING_EXECUTION_GUIDE.md)** - Detailed guide
- **[docs/INTERACTION_INVENTORY.md](./docs/INTERACTION_INVENTORY.md)** - All screens/flows

## ✨ Quick Tips

1. **Run often**: Don't wait for big changes
2. **Check coverage**: Aim for >80%
3. **Fix warnings**: Address static analysis issues
4. **Monitor trends**: Track improvement over time
5. **Automate**: Add to CI/CD pipeline

## 🎯 Next Steps After Audit

1. ✅ Review `SUMMARY.txt` in results folder
2. 📊 Check coverage report
3. 🐛 Fix failing tests
4. 📈 Improve low-coverage areas
5. 🔁 Re-run to verify fixes

---

**Last Updated**: 2025-10-25  
**Audit Tool**: Flutter App Interaction Audit Suite  
**Version**: 1.0.0
