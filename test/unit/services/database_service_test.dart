import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
      // Initialize the database service
      await databaseService.initialize();
    });

    test('DatabaseService should be a singleton', () {
      final instance1 = DatabaseService();
      final instance2 = DatabaseService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('DatabaseService should initialize without errors', () async {
      // Verify that initialize method can be called without throwing
      final dbService = DatabaseService();
      expect(() => dbService.initialize(), returnsNormally);
    });

    test('DatabaseService should have client getter', () async {
      // Verify the client getter exists and is not null after initialization
      expect(databaseService.client, isNotNull);
    });

    test('DatabaseService should have auth getter', () async {
      // Verify the auth getter exists and is not null after initialization
      expect(databaseService.auth, isNotNull);
    });
  });
}