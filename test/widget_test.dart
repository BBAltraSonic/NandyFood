// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

import 'package:food_delivery_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Enable test mode for DatabaseService to avoid pending timers
    DatabaseService.enableTestMode();
    
    // Initialize the DatabaseService before running the test
    final dbService = DatabaseService();
    await dbService.initialize();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(ProviderScope(child: const FoodDeliveryApp()));

    // Verify that the app loads without errors
    expect(find.byType(Scaffold), findsOneWidget);
    
    // Dispose of the DatabaseService after the test
    await dbService.dispose();
    
    // Disable test mode after the test
    DatabaseService.disableTestMode();
  });
}