import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

enum LocationFlowResult {
  granted,
  denied,
  deniedForever,
  servicesDisabled,
  cancelled,
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Show location permission explanation dialog (rationale)
  Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission'),
            content: const Text(
              'We need your location to show nearby restaurants and accurate delivery times. '
              'Your location is only used while you are using the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Allow'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show a dialog guiding user to enable services or permissions in Settings
  Future<void> showSettingsDialog(BuildContext context, {
    required String title,
    required String message,
    required bool openAppSettings,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              if (openAppSettings) {
                await Geolocator.openAppSettings();
              } else {
                await Geolocator.openLocationSettings();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    return serviceEnabled;
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission;
  }

  /// Request location permission (system prompt)
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission;
  }

  /// Request location permission with custom rationale dialog before system prompt
  Future<LocationPermission> requestPermissionWithDialog(
    BuildContext context,
  ) async {
    final userAgreed = await showPermissionDialog(context);
    if (!userAgreed) {
      return LocationPermission.denied;
    }
    return await Geolocator.requestPermission();
  }

  /// Ensure services and permissions with rationale + denied/forever-denied fallbacks
  Future<LocationFlowResult> ensureServiceAndPermission(
    BuildContext context,
  ) async {
    // Services disabled
    final servicesEnabled = await isLocationServiceEnabled();
    if (!servicesEnabled) {
      await showSettingsDialog(
        context,
        title: 'Turn On Location Services',
        message:
            'Location services are disabled. Please turn them on in Settings to use location features.',
        openAppSettings: false,
      );
      return LocationFlowResult.servicesDisabled;
    }

    // Current permission
    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      // App-level rationale before system prompt
      permission = await requestPermissionWithDialog(context);
    }

    if (permission == LocationPermission.denied) {
      return LocationFlowResult.denied;
    }

    if (permission == LocationPermission.deniedForever) {
      await showSettingsDialog(
        context,
        title: 'Location Permission Required',
        message:
            'You have permanently denied location permission. Open app settings to allow access.',
        openAppSettings: true,
      );
      return LocationFlowResult.deniedForever;
    }

    return LocationFlowResult.granted;
  }

  /// Get current position (throws on service/permission issues)
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Get address from coordinates
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      } else {
        return 'Address not found';
      }
    } catch (e) {
      return 'Unable to get address';
    }
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000;
  }

  /// Get nearby restaurants based on current location
  /// This would typically call the database service to get restaurants near the user
  /// For now, this is a placeholder method that would be implemented with database integration
  Future<List<Map<String, dynamic>>> getNearbyRestaurants({
    double? radiusInKm,
  }) async {
    // In a real implementation, this would call the database service
    // with the current coordinates to find nearby restaurants

    // First get current position
    await getCurrentPosition();

    // This is where you would pass the coordinates to the database service
    // to get restaurants within the specified radius
    // For now, returning an empty list as a placeholder
    return [];
  }
}
