import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  setUp(() {
    DatabaseService.enableTestMode();
  });

  tearDown(() {
    DatabaseService.disableTestMode();
  });

  test('skipAuthentication enables guest mode', () {
    final notifier = AuthStateNotifier();

    notifier.skipAuthentication();

    final state = notifier.state;
    expect(state.isGuest, isTrue);
    expect(state.isAuthenticated, isFalse);
    expect(state.user, isNull);
  });

  test('clearErrorMessage keeps guest mode', () {
    final notifier = AuthStateNotifier();

    notifier.skipAuthentication();
    notifier.clearErrorMessage();

    final state = notifier.state;
    expect(state.isGuest, isTrue);
    expect(state.errorMessage, isNull);
  });
}
