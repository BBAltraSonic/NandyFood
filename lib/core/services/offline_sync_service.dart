import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing offline actions and syncing when online
/// 
/// Queues actions performed offline and syncs them when connection
/// is restored.
class OfflineSyncService {
  static const String _syncQueueKey = 'offline_sync_queue';
  
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance {
    _instance ??= OfflineSyncService._();
    return _instance!;
  }

  OfflineSyncService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  final List<OfflineAction> _syncQueue = [];

  /// Initialize the service and start listening to connectivity changes
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      await _checkConnectivity();
      
      // Load queued actions from storage
      await _loadQueueFromStorage();
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );
      
      AppLogger.info('OfflineSyncService: Initialized successfully');
    } catch (e) {
      AppLogger.error('OfflineSyncService: Failed to initialize - $e');
    }
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
      AppLogger.info('OfflineSyncService: Connectivity status - ${_isOnline ? "Online" : "Offline"}');
    } catch (e) {
      AppLogger.error('OfflineSyncService: Error checking connectivity', e);
      _isOnline = true; // Assume online if check fails
    }
  }

  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOffline = !_isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);
    
    AppLogger.info('OfflineSyncService: Connectivity changed - ${_isOnline ? "Online" : "Offline"}');
    
    // If we just came back online, sync queued actions
    if (wasOffline && _isOnline) {
      AppLogger.info('OfflineSyncService: Back online, starting sync...');
      await syncQueuedActions();
    }
  }

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Queue an action to be performed when online
  Future<void> queueAction(OfflineAction action) async {
    try {
      _syncQueue.add(action);
      await _saveQueueToStorage();
      
      AppLogger.info('OfflineSyncService: Queued action - ${action.type}');
      
      // If online, sync immediately
      if (_isOnline) {
        await syncQueuedActions();
      }
    } catch (e) {
      AppLogger.error('OfflineSyncService: Failed to queue action - $e');
    }
  }

  /// Sync all queued actions
  Future<void> syncQueuedActions() async {
    if (_syncQueue.isEmpty) {
      AppLogger.info('OfflineSyncService: No actions to sync');
      return;
    }

    if (!_isOnline) {
      AppLogger.info('OfflineSyncService: Cannot sync - offline');
      return;
    }

    AppLogger.info('OfflineSyncService: Syncing ${_syncQueue.length} queued actions...');
    
    final actionsToSync = List<OfflineAction>.from(_syncQueue);
    _syncQueue.clear();

    int successCount = 0;
    int failureCount = 0;

    for (final action in actionsToSync) {
      try {
        await _executeAction(action);
        successCount++;
      } catch (e) {
        AppLogger.error('OfflineSyncService: Failed to sync action ${action.type} - $e');
        failureCount++;
        
        // Re-queue failed action
        _syncQueue.add(action);
      }
    }

    await _saveQueueToStorage();
    
    AppLogger.info('OfflineSyncService: Sync complete - $successCount succeeded, $failureCount failed');
  }

  /// Execute a specific action
  Future<void> _executeAction(OfflineAction action) async {
    // This would be implemented based on action type
    // For now, just log the action
    AppLogger.info('OfflineSyncService: Executing action - ${action.type}');
    
    switch (action.type) {
      case OfflineActionType.addToCart:
        // Implement cart sync
        break;
      case OfflineActionType.updateProfile:
        // Implement profile sync
        break;
      case OfflineActionType.writeReview:
        // Implement review sync
        break;
      default:
        AppLogger.warning('OfflineSyncService: Unknown action type - ${action.type}');
    }
  }

  /// Load queued actions from persistent storage
  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList(_syncQueueKey) ?? [];
      
      _syncQueue.clear();
      for (final json in queueJson) {
        try {
          final action = OfflineAction.fromJson(json);
          _syncQueue.add(action);
        } catch (e) {
          AppLogger.error('OfflineSyncService: Failed to parse queued action', e);
        }
      }
      
      AppLogger.info('OfflineSyncService: Loaded ${_syncQueue.length} queued actions');
    } catch (e) {
      AppLogger.error('OfflineSyncService: Failed to load queue from storage - $e');
    }
  }

  /// Save queued actions to persistent storage
  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _syncQueue.map((action) => action.toJson()).toList();
      await prefs.setStringList(_syncQueueKey, queueJson);
      
      AppLogger.info('OfflineSyncService: Saved ${_syncQueue.length} queued actions');
    } catch (e) {
      AppLogger.error('OfflineSyncService: Failed to save queue to storage - $e');
    }
  }

  /// Clear all queued actions
  Future<void> clearQueue() async {
    try {
      _syncQueue.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_syncQueueKey);
      
      AppLogger.info('OfflineSyncService: Cleared sync queue');
    } catch (e) {
      AppLogger.error('OfflineSyncService: Failed to clear queue - $e');
    }
  }

  /// Get number of queued actions
  int get queuedActionsCount => _syncQueue.length;

  /// Dispose the service
  void dispose() {
    _connectivitySubscription?.cancel();
    AppLogger.info('OfflineSyncService: Disposed');
  }
}

/// Enum for different types of offline actions
enum OfflineActionType {
  addToCart,
  updateProfile,
  writeReview,
  updateAddress,
  other,
}

/// Represents an action performed offline
class OfflineAction {
  final OfflineActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  OfflineAction({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON string for storage
  String toJson() {
    return '${type.name}|${timestamp.toIso8601String()}|${data.toString()}';
  }

  /// Create from JSON string
  factory OfflineAction.fromJson(String json) {
    final parts = json.split('|');
    return OfflineAction(
      type: OfflineActionType.values.firstWhere(
        (e) => e.name == parts[0],
        orElse: () => OfflineActionType.other,
      ),
      timestamp: DateTime.parse(parts[1]),
      data: {}, // Simplified for now
    );
  }
}
