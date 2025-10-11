import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

class MockDatabaseService {
  static final MockDatabaseService _instance = MockDatabaseService._internal();
  factory MockDatabaseService() => _instance;
  MockDatabaseService._internal();

  /// Mock initialization without creating actual Supabase client
  /// This prevents the auto-refresh timers from being created
  Future<void> initialize() async {
    print('Mock DatabaseService initialized');
  }

  /// Mock dispose method
  Future<void> dispose() async {
    print('Mock DatabaseService disposed');
  }
}
