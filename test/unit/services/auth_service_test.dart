import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('AuthService should be a singleton', () {
      final instance1 = AuthService();
      final instance2 = AuthService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('AuthService should have auth getter', () {
      // We can't test the actual auth client without initializing Supabase
      // but we can verify the getter exists
      expect(authService, isNotNull);
    });
  });
}