import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class for all providers in the application
abstract class BaseProvider<T> {
  /// The provider instance
  final ProviderBase<T> provider;

  /// Constructor
  const BaseProvider(this.provider);
}

/// Base class for async providers
abstract class AsyncBaseProvider<T> {
  /// The async provider instance
  final FutureProvider<T> provider;

  /// Constructor
  const AsyncBaseProvider(this.provider);
}

/// Base class for state notifier providers
abstract class StateNotifierBaseProvider<T> {
  /// The state notifier provider instance
  final StateNotifierProvider<StateNotifier<T>, T> provider;

  /// Constructor
  const StateNotifierBaseProvider(this.provider);
}
