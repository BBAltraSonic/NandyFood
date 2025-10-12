import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/realtime_service.dart';

/// Driver location state
class DriverLocationState {
  const DriverLocationState({
    this.driverId,
    this.currentLocation,
    this.previousLocation,
    this.destinationLocation,
    this.distanceToDestination,
    this.estimatedTimeOfArrival,
    this.isMoving = false,
    this.speed,
    this.heading,
    this.lastUpdated,
    this.error,
    this.isLoading = false,
  });

  final String? driverId;
  final LatLng? currentLocation;
  final LatLng? previousLocation;
  final LatLng? destinationLocation;
  final double? distanceToDestination; // in kilometers
  final Duration? estimatedTimeOfArrival;
  final bool isMoving;
  final double? speed; // in km/h
  final double? heading; // in degrees
  final DateTime? lastUpdated;
  final String? error;
  final bool isLoading;

  DriverLocationState copyWith({
    String? driverId,
    LatLng? currentLocation,
    LatLng? previousLocation,
    LatLng? destinationLocation,
    double? distanceToDestination,
    Duration? estimatedTimeOfArrival,
    bool? isMoving,
    double? speed,
    double? heading,
    DateTime? lastUpdated,
    String? error,
    bool? isLoading,
  }) {
    return DriverLocationState(
      driverId: driverId ?? this.driverId,
      currentLocation: currentLocation ?? this.currentLocation,
      previousLocation: previousLocation ?? this.previousLocation,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      distanceToDestination: distanceToDestination ?? this.distanceToDestination,
      estimatedTimeOfArrival: estimatedTimeOfArrival ?? this.estimatedTimeOfArrival,
      isMoving: isMoving ?? this.isMoving,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Driver location notifier
class DriverLocationNotifier extends StateNotifier<DriverLocationState> {
  DriverLocationNotifier({
    required this.realtimeService,
    required this.destinationLocation,
    String? driverId,
  }) : super(const DriverLocationState(isLoading: true)) {
    if (driverId != null) {
      _initialize(driverId);
    }
  }

  final RealtimeService realtimeService;
  final LatLng destinationLocation;
  
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  Timer? _etaUpdateTimer;

  /// Initialize tracking for a driver
  Future<void> _initialize(String driverId) async {
    try {
      state = state.copyWith(
        driverId: driverId,
        destinationLocation: destinationLocation,
        isLoading: true,
      );

      // Subscribe to driver location updates
      _locationSubscription = realtimeService
          .subscribeToDriverLocation(driverId)
          .listen(
            _handleLocationUpdate,
            onError: _handleError,
          );

      // Start periodic ETA updates
      _etaUpdateTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _updateETA(),
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error initializing driver location tracking: $e');
      state = state.copyWith(
        error: 'Failed to start tracking driver',
        isLoading: false,
      );
    }
  }

  /// Start tracking a new driver
  void startTracking(String driverId) {
    _dispose();
    _initialize(driverId);
  }

  /// Handle location updates from Supabase
  void _handleLocationUpdate(Map<String, dynamic> data) {
    try {
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        debugPrint('Invalid location data received');
        return;
      }

      final newLocation = LatLng(lat, lng);
      final previousLoc = state.currentLocation;

      // Calculate speed and heading if we have a previous location
      double? speed;
      double? heading;
      bool isMoving = false;

      if (previousLoc != null) {
        // Calculate distance moved (in meters)
        final distanceMoved = Geolocator.distanceBetween(
          previousLoc.latitude,
          previousLoc.longitude,
          newLocation.latitude,
          newLocation.longitude,
        );

        // Calculate time elapsed
        final timeElapsed = state.lastUpdated != null
            ? DateTime.now().difference(state.lastUpdated!).inSeconds
            : 0;

        // Calculate speed (km/h)
        if (timeElapsed > 0) {
          speed = (distanceMoved / timeElapsed) * 3.6; // m/s to km/h
        }

        // Calculate heading
        heading = _calculateBearing(previousLoc, newLocation);

        // Consider moving if distance > 10 meters
        isMoving = distanceMoved > 10;
      }

      // Calculate distance to destination
      final distanceToDestination = Geolocator.distanceBetween(
        newLocation.latitude,
        newLocation.longitude,
        destinationLocation.latitude,
        destinationLocation.longitude,
      ) / 1000; // Convert to kilometers

      // Calculate ETA
      final eta = _calculateETA(distanceToDestination, speed);

      state = state.copyWith(
        currentLocation: newLocation,
        previousLocation: previousLoc,
        distanceToDestination: distanceToDestination,
        estimatedTimeOfArrival: eta,
        isMoving: isMoving,
        speed: speed,
        heading: heading,
        lastUpdated: DateTime.now(),
        error: null,
      );

      debugPrint('Driver location updated: $newLocation, Distance: ${distanceToDestination.toStringAsFixed(2)} km, ETA: ${eta?.inMinutes ?? 0} min');
    } catch (e) {
      debugPrint('Error handling location update: $e');
    }
  }

  /// Calculate estimated time of arrival
  Duration? _calculateETA(double distanceKm, double? currentSpeed) {
    if (distanceKm <= 0) return Duration.zero;

    // Use current speed if available, otherwise assume average speed
    double avgSpeed = currentSpeed ?? 30.0; // Default to 30 km/h

    // Apply traffic factor (could be enhanced with real traffic data)
    const trafficFactor = 1.2;
    avgSpeed = avgSpeed / trafficFactor;

    // Ensure minimum speed to avoid unrealistic ETAs
    if (avgSpeed < 10) avgSpeed = 10;

    // Calculate time in hours, then convert to duration
    final timeHours = distanceKm / avgSpeed;
    final timeMinutes = (timeHours * 60).round();

    return Duration(minutes: timeMinutes);
  }

  /// Update ETA periodically
  void _updateETA() {
    if (state.currentLocation != null && state.distanceToDestination != null) {
      final eta = _calculateETA(state.distanceToDestination!, state.speed);
      state = state.copyWith(estimatedTimeOfArrival: eta);
    }
  }

  /// Calculate bearing between two points
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = _degreesToRadians(start.latitude);
    final lat2 = _degreesToRadians(end.latitude);
    final dLon = _degreesToRadians(end.longitude - start.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return _radiansToDegrees(bearing);
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _radiansToDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  /// Handle errors
  void _handleError(Object error) {
    debugPrint('Driver location tracking error: $error');
    state = state.copyWith(
      error: 'Connection error. Retrying...',
    );

    // Retry connection after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && state.driverId != null) {
        _initialize(state.driverId!);
      }
    });
  }

  /// Cleanup subscriptions
  void _dispose() {
    _locationSubscription?.cancel();
    _etaUpdateTimer?.cancel();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}

/// Provider family for driver location tracking
final driverLocationProvider = StateNotifierProvider.family<
    DriverLocationNotifier,
    DriverLocationState,
    DriverLocationParams>(
  (ref, params) {
    final realtimeService = ref.watch(realtimeServiceProvider);

    return DriverLocationNotifier(
      realtimeService: realtimeService,
      destinationLocation: params.destinationLocation,
      driverId: params.driverId,
    );
  },
);

/// Parameters for driver location provider
class DriverLocationParams {
  const DriverLocationParams({
    required this.destinationLocation,
    this.driverId,
  });

  final LatLng destinationLocation;
  final String? driverId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriverLocationParams &&
          runtimeType == other.runtimeType &&
          destinationLocation == other.destinationLocation &&
          driverId == other.driverId;

  @override
  int get hashCode => destinationLocation.hashCode ^ driverId.hashCode;
}
