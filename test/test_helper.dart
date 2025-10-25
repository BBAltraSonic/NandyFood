import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Setup test environment with mocks and test mode enabled
Future<void> setupTestEnvironment() async {
  // Enable test mode for DatabaseService to bypass initialization
  DatabaseService.enableTestMode();
  
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  
  // Initialize Supabase for testing
  // Note: Supabase can be re-initialized in tests
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key-for-testing',
    );
  } catch (e) {
    // Supabase might already be initialized, which is fine
    // No action needed
  }
}

/// Clean up test environment
void teardownTestEnvironment() {
  DatabaseService.disableTestMode();
}

/// Create a test ProviderScope with overrides
ProviderScope createTestProviderScope({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: child,
  );
}

/// Pump a widget in test environment
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await setupTestEnvironment();
  await tester.pumpWidget(
    createTestProviderScope(
      overrides: overrides,
      child: MaterialApp(home: widget),
    ),
  );
}
