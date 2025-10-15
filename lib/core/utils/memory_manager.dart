import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Memory management utilities for optimizing app performance
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._();
  MemoryManager._();
  factory MemoryManager() => _instance;

  /// Clear image cache to free memory
  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache(''); // Clear all
      AppLogger.info('MemoryManager: Image cache cleared');
    } catch (e) {
      AppLogger.error('MemoryManager: Failed to clear image cache - $e');
    }
  }

  /// Clear image cache when memory is low
  static Future<void> handleLowMemory() async {
    AppLogger.warning('MemoryManager: Low memory detected, clearing caches...');
    
    try {
      // Clear image cache
      await clearImageCache();
      
      // Force garbage collection
      // Note: Can't force GC in Dart, but can help by clearing references
      
      AppLogger.success('MemoryManager: Caches cleared successfully');
    } catch (e) {
      AppLogger.error('MemoryManager: Failed to handle low memory - $e');
    }
  }

  /// Monitor app lifecycle and clear caches when app is paused
  static void setupLifecycleObserver(WidgetsBinding binding) {
    binding.addObserver(_AppLifecycleObserver());
    AppLogger.info('MemoryManager: Lifecycle observer registered');
  }
}

/// Observer for app lifecycle events
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App is in background - clear caches
        AppLogger.info('App paused - clearing image cache');
        MemoryManager.clearImageCache();
        break;
      case AppLifecycleState.resumed:
        AppLogger.info('App resumed');
        break;
      case AppLifecycleState.inactive:
        AppLogger.info('App inactive');
        break;
      case AppLifecycleState.detached:
        AppLogger.info('App detached');
        break;
      case AppLifecycleState.hidden:
        AppLogger.info('App hidden');
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    AppLogger.warning('Memory pressure detected!');
    MemoryManager.handleLowMemory();
  }
}

/// Mixin for StatefulWidgets to properly dispose resources
mixin DisposableMixin<T extends StatefulWidget> on State<T> {
  final List<void Function()> _disposers = [];

  /// Register a disposer function
  void addDisposer(void Function() disposer) {
    _disposers.add(disposer);
  }

  /// Register a controller for automatic disposal
  void registerController(ChangeNotifier controller) {
    addDisposer(() => controller.dispose());
  }

  @override
  void dispose() {
    for (final disposer in _disposers) {
      try {
        disposer();
      } catch (e) {
        AppLogger.error('DisposableMixin: Error during disposal - $e');
      }
    }
    _disposers.clear();
    super.dispose();
  }
}
