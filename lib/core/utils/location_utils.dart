import 'dart:math' as math;

/// Utility class for location-based calculations
class LocationUtils {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  /// Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadius * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Format distance for display
  static String formatDistance(double distance) {
    if (distance < 1.0) {
      return '${(distance * 1000).round()}m';
    } else if (distance < 10.0) {
      return '${distance.toStringAsFixed(1)}km';
    } else {
      return '${distance.round()}km';
    }
  }

  /// Calculate distance with caching for performance
  static double calculateDistanceWithCache(
    double lat1,
    double lng1,
    double lat2,
    double lng2, {
    Map<String, double>? cache,
  }) {
    // Create a unique key for this coordinate pair
    final key = '${lat1.toStringAsFixed(6)},${lng1.toStringAsFixed(6)}-${lat2.toStringAsFixed(6)},${lng2.toStringAsFixed(6)}';

    if (cache != null && cache.containsKey(key)) {
      return cache[key]!;
    }

    final distance = calculateDistance(lat1, lng1, lat2, lng2);

    if (cache != null) {
      cache[key] = distance;
    }

    return distance;
  }

  /// Validate coordinate bounds
  static bool isValidCoordinate(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  /// Check if a point is within a certain radius of another point
  static bool isWithinRadius(
    double centerLat,
    double centerLng,
    double pointLat,
    double pointLng,
    double radiusKm,
  ) {
    final distance = calculateDistance(centerLat, centerLng, pointLat, pointLng);
    return distance <= radiusKm;
  }

  /// Get bearing between two points
  static double calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _toRadians(lng2 - lng1);
    lat1 = _toRadians(lat1);
    lat2 = _toRadians(lat2);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (bearing + 2 * math.pi) % (2 * math.pi);
  }

  /// Convert bearing to compass direction
  static String bearingToCompassDirection(double bearing) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];

    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}