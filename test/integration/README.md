# Integration Tests Documentation

## Overview

This directory contains comprehensive integration tests for the NandyFood app. These tests verify that different components of the app work together correctly, ensuring a smooth user experience across all major flows.

## Test Structure

```
test/integration/
├── README.md                              # This file
├── integration_test_helpers.dart          # Test utilities and mock data
├── integration_test_runner.dart           # Test runner and configuration
├── auth_flow_integration_test.dart        # Authentication flow tests
├── order_flow_integration_test.dart       # Order and cart flow tests
├── restaurant_owner_flow_integration_test.dart # Restaurant owner dashboard tests
└── payment_integration_test.dart          # Payment system tests
```

## Test Coverage Areas

### ✅ Authentication Flow (`auth_flow_integration_test.dart`)
- User signup process
- User login process
- Password reset flow
- Logout functionality
- Navigation between auth screens
- Error handling for invalid credentials
- Role-based access control

### ✅ Order Flow (`order_flow_integration_test.dart`)
- Restaurant browsing
- Menu item selection
- Cart management (add, remove, update quantities)
- Item customization options
- Checkout process
- Order validation
- Price calculations
- State management

### ✅ Restaurant Owner Flow (`restaurant_owner_flow_integration_test.dart`)
- Dashboard access and display
- Analytics screen functionality
- Notification management
- Role-based access enforcement
- Navigation between owner screens
- Real-time updates
- Error handling

### ✅ Payment Integration (`payment_integration_test.dart`)
- Cash on payment processing
- PayFast integration (sandbox mode)
- Payment configuration validation
- Payment method validation
- Amount validation
- Error handling

## Running Tests

### Run All Integration Tests
```bash
flutter test test/integration/
```

### Run Specific Test File
```bash
flutter test test/integration/auth_flow_integration_test.dart
flutter test test/integration/order_flow_integration_test.dart
flutter test test/integration/restaurant_owner_flow_integration_test.dart
flutter test test/integration/payment_integration_test.dart
```

### Run with Coverage
```bash
flutter test --coverage test/integration/
```

### Run with Verbose Output
```bash
flutter test --verbose test/integration/
```

## Test Environment Setup

### Prerequisites
1. Ensure `.env` file is properly configured
2. Run `flutter pub get` to install dependencies
3. Run `dart run build_runner build` to generate required files

### Environment Variables
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` for database connectivity
- `PAYFAST_MERCHANT_ID`, `PAYFAST_MERCHANT_KEY`, `PAYFAST_PASSPHRASE` for payment testing
- `ENABLE_PAYFAST=true` for payment integration tests

## Test Data and Mocks

The `integration_test_helpers.dart` file provides:
- Mock user profiles (consumer and restaurant owner)
- Mock restaurant and menu data
- Mock order data
- Test utility functions
- Custom matchers and assertions

## Best Practices

### Test Structure
1. **Arrange**: Set up test data and initial state
2. **Act**: Perform user interactions or actions
3. **Assert**: Verify expected outcomes

### Test Isolation
- Each test should be independent
- Use proper `setUp` and `tearDown` methods
- Clean up state between tests
- Avoid sharing state between tests

### Mocking Strategy
- Mock external dependencies (database, APIs)
- Use controlled test data
- Simulate different scenarios (success, error, edge cases)

### Assertions
- Verify UI states and elements
- Check navigation flows
- Validate data transformations
- Test error conditions

## Performance Considerations

### Test Execution
- Use `pumpAndSettle()` for async operations
- Add delays for animations and transitions
- Handle timeout scenarios gracefully

### Memory Management
- Dispose providers and containers properly
- Clean up resources in `tearDown`
- Avoid memory leaks in long-running tests

## Troubleshooting

### Common Issues

#### Test Timeouts
- Increase timeout duration with `--timeout` flag
- Check for infinite loops or blocking operations
- Verify async operations complete properly

#### Widget Not Found
- Ensure proper widget pumping with `pumpAndSettle()`
- Check for navigation completion
- Verify widget keys and text match exactly

#### Provider State Issues
- Initialize providers correctly in test setup
- Use proper container scoping
- Dispose providers after tests

#### Network Dependencies
- Mock network calls in test environment
- Use test-specific configuration
- Handle connection errors gracefully

### Debug Tips

#### Enable Verbose Logging
```bash
flutter test --verbose test/integration/
```

#### Run Single Test for Debugging
```bash
flutter test test/integration/auth_flow_integration_test.dart --plain-name="specific_test_name"
```

#### Use Debug Prints
```dart
print('Debug: Current state = $someState');
```

#### Inspect Widget Tree
```dart
debugDumpApp();
```

## Continuous Integration

### GitHub Actions Integration
The tests are designed to run in CI/CD environments:
- Use headless test execution
- Configure proper environment variables
- Set up test database for CI
- Generate coverage reports

### Coverage Goals
- Target >80% code coverage for critical flows
- Focus on user-facing functionality
- Include edge cases and error scenarios

## Contributing

### Adding New Tests
1. Create test file following naming convention: `*_integration_test.dart`
2. Use `IntegrationTestHelpers` for common utilities
3. Include both positive and negative test cases
4. Add comprehensive assertions
5. Update this README with new test coverage

### Test Review Checklist
- [ ] Test is independent and isolated
- [ ] Proper setup and teardown
- [ ] Comprehensive assertions
- [ ] Error scenarios covered
- [ ] Documentation updated
- [ ] Tests pass locally and in CI

## Future Enhancements

### Planned Additions
- [ ] API integration tests
- [ ] Performance testing
- [ ] Accessibility testing
- [ ] Localization testing
- [ ] End-to-end testing with real devices

### Test Automation
- [ ] Automated test execution on PR
- [ ] Coverage reporting
- [ ] Performance regression testing
- [ ] Visual regression testing