import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Service for monitoring network connectivity status
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  
  bool _isConnected = true;
  ConnectivityResult _lastResult = ConnectivityResult.none;

  /// Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    AppLogger.init('ConnectivityService: Initializing');

    // Check initial connectivity
    await _checkConnectivity();

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (error) {
        AppLogger.error('Connectivity stream error', error: error);
      },
    );

    AppLogger.success('ConnectivityService initialized');
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _handleConnectivityChange(result);
    } catch (e) {
      AppLogger.error('Failed to check connectivity', error: e);
      _isConnected = false;
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    _updateConnectionStatus(result);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _lastResult = result;
    final wasConnected = _isConnected;
    
    _isConnected = result != ConnectivityResult.none;

    if (wasConnected != _isConnected) {
      AppLogger.info(
        'Connectivity changed',
        data: {'isConnected': _isConnected, 'type': result.toString()},
      );
      _connectivityController.add(_isConnected);
    }
  }

  /// Get current connection status
  bool get isConnected => _isConnected;

  /// Get connection type
  String get connectionType {
    switch (_lastResult) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  /// Check if connected via WiFi
  bool get isWiFi => _lastResult == ConnectivityResult.wifi;

  /// Check if connected via mobile data
  bool get isMobile => _lastResult == ConnectivityResult.mobile;

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
    AppLogger.info('ConnectivityService disposed');
  }
}
