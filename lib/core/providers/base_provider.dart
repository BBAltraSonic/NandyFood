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

/// Base class for stream providers
abstract class StreamBaseProvider<T> {
  /// The stream provider instance
  final StreamProvider<T> provider;

  /// Constructor
  const StreamBaseProvider(this.provider);
}

/// Base class for future providers
abstract class FutureBaseProvider<T> {
  /// The future provider instance
  final FutureProvider<T> provider;

  /// Constructor
  const FutureBaseProvider(this.provider);
}

/// Provider dependency manager to handle provider dependencies and avoid circular references
class ProviderDependencyManager {
  /// A map of provider dependencies to ensure proper initialization order
  static final Map<String, List<String>> _dependencies = {};

  /// Register a provider and its dependencies
  static void registerProvider(String providerName, List<String> dependencies) {
    _dependencies[providerName] = dependencies;
  }

  /// Check if there are circular dependencies
  static bool hasCircularDependency(String providerName, String dependencyName) {
    // Check if adding this dependency would create a circular dependency
    final dependencyChain = _buildDependencyChain(dependencyName);
    return dependencyChain.contains(providerName);
  }

  /// Build a dependency chain for debugging
  static List<String> _buildDependencyChain(String providerName, [Set<String>? visited]) {
    visited ??= <String>{};
    
    if (visited.contains(providerName)) {
      return [providerName]; // Circular dependency detected
    }
    
    visited.add(providerName);
    
    final dependencies = _dependencies[providerName] ?? [];
    final chain = <String>[];
    
    for (final dependency in dependencies) {
      chain.addAll(_buildDependencyChain(dependency, Set.from(visited)));
    }
    
    return chain;
  }
}

/// Mixin for providers that need to initialize data when the provider is first accessed
mixin InitializeOnAccess<T> on StateNotifier<T> {
  bool _isInitialized = false;
  
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (!_isInitialized) {
      await onInitialize();
      _isInitialized = true;
    }
  }
  
  /// Override this method to perform initialization logic
  Future<void> onInitialize();
}

/// Mixin for providers that need to dispose resources properly
mixin DisposableProvider<T> on StateNotifier<T> {
  final List<void Function()> _disposers = [];
  
  /// Add a function to be called when the provider is disposed
  void addDisposer(void Function() disposer) {
    _disposers.add(disposer);
  }
  
  void dispose() {
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }
}
