import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for Google Maps integration
class MapConfig {
  MapConfig._();

  /// Google Maps API key (loaded from .env file)
  static String get googleMapsApiKey {
    debugPrint('MapConfig: googleMapsApiKey getter called');
    // Load from .env file with fallback for safety
    String? apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      // Fallback to the hardcoded key as backup
      apiKey = 'AIzaSyBYiFP4Y-Hi9d-JboqXCcDDP5Kc94iL1ZY';
      debugPrint('MapConfig: Using fallback API key');
    } else {
      debugPrint('MapConfig: Using API key from .env file');
    }
    debugPrint('MapConfig: API key length: ${apiKey.length}');
    return apiKey;
  }

  /// Default map center (New York City)
  static const LatLng defaultCenter = LatLng(40.7128, -74.0060);

  /// Default zoom level
  static const double defaultZoom = 13.0;

  /// Minimum and maximum zoom levels
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  /// Custom marker icons (updated for black/white theme)
  static const double markerSize = 40.0;
  static const Color restaurantMarkerColor = Color(0xFF000000); // Pure black
  static const Color userMarkerColor = Color(0xFF000000); // Pure black
  static const Color deliveryMarkerColor = Color(0xFF000000); // Pure black

  /// Sophisticated dark mode map style JSON
  /// This style creates a minimalist black and white map that matches the app theme
  static const String _darkMapStyleJson = '''
  [
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#000000"
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#ffffff"
        },
        {
          "lightness": 40
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative.country",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#333333"
        },
        {
          "lightness": 20
        }
      ]
    },
    {
      "featureType": "landscape",
      "elementType": "all",
      "stylers": [
        {
          "color": "#000000"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "all",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "all",
      "stylers": [
        {
          "visibility": "on"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#1a1a1a"
        },
        {
          "lightness": 10
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#333333"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#2a2a2a"
        },
        {
          "lightness": 15
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#444444"
        }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#222222"
        },
        {
          "lightness": 12
        }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "all",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#0a0a0a"
        },
        {
          "lightness": 5
        }
      ]
    }
  ]
  ''';

  /// Get the dark mode map style for Google Maps
  static String get darkMapStyle {
    debugPrint('MapConfig: darkMapStyle getter called');
    return _darkMapStyleJson;
  }

  /// Create default camera position
  static CameraPosition getDefaultCameraPosition({
    LatLng? center,
    double? zoom,
  }) {
    return CameraPosition(
      target: center ?? defaultCenter,
      zoom: zoom ?? defaultZoom,
      bearing: 0.0,
      tilt: 0.0,
    );
  }

  /// Create GoogleMap configuration
  static GoogleMap createGoogleMap({
    required CameraPosition initialCameraPosition,
    Set<Marker>? markers,
    Set<Polyline>? polylines,
    Set<Circle>? circles,
    void Function(LatLng)? onTap,
    void Function(LatLng)? onLongPress,
    Function(GoogleMapController)? onMapCreated,
    MapType? mapType,
    bool? myLocationEnabled,
    bool? myLocationButtonEnabled,
    bool? zoomControlsEnabled,
    bool? zoomGesturesEnabled,
    bool? scrollGesturesEnabled,
    bool? rotateGesturesEnabled,
    bool? tiltGesturesEnabled,
    MinMaxZoomPreference? minMaxZoomPreference,
    String? style,
  }) {
    return GoogleMap(
      initialCameraPosition: initialCameraPosition,
      onMapCreated: onMapCreated,
      markers: markers ?? const <Marker>{},
      polylines: polylines ?? const <Polyline>{},
      circles: circles ?? const <Circle>{},
      onTap: onTap,
      onLongPress: onLongPress,
      mapType: mapType ?? MapType.normal,
      myLocationEnabled: myLocationEnabled ?? false,
      myLocationButtonEnabled: myLocationButtonEnabled ?? true,
      zoomControlsEnabled: zoomControlsEnabled ?? false, // Custom controls will be used
      zoomGesturesEnabled: zoomGesturesEnabled ?? true,
      scrollGesturesEnabled: scrollGesturesEnabled ?? true,
      rotateGesturesEnabled: rotateGesturesEnabled ?? true,
      tiltGesturesEnabled: tiltGesturesEnabled ?? true,
      minMaxZoomPreference: minMaxZoomPreference ??
          const MinMaxZoomPreference(minZoom, maxZoom),
      style: style ?? darkMapStyle,
      compassEnabled: true,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      trafficEnabled: false,
      indoorViewEnabled: false,
      layoutDirection: TextDirection.ltr,
      padding: EdgeInsets.zero,
    );
  }

  /// Create a restaurant marker for Google Maps
  static Marker createRestaurantMarker({
    required LatLng position,
    required String restaurantId,
    required String restaurantName,
    required VoidCallback onTap,
    String? rating,
    bool isDelivery = false,
  }) {
    return Marker(
      markerId: MarkerId('restaurant_$restaurantId'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        isDelivery ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueRed,
      ),
      infoWindow: InfoWindow(
        title: restaurantName,
        snippet: isDelivery ? 'Delivery Available' : 'Pickup Only',
      ),
      onTap: onTap,
      visible: true,
      zIndexInt: 2,
    );
  }

  /// Create a user location marker for Google Maps
  static Marker createUserMarker({required LatLng position}) {
    return Marker(
      markerId: const MarkerId('user_location'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Your Location'),
      visible: true,
      zIndexInt: 3,
    );
  }

  /// Create a delivery driver marker for Google Maps
  static Marker createDeliveryMarker({
    required LatLng position,
    double? rotation,
    String? driverId,
  }) {
    return Marker(
      markerId: MarkerId('delivery_driver_${driverId ?? 'active'}'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Delivery Driver'),
      visible: true,
      rotation: rotation ?? 0.0,
      flat: true,
      zIndexInt: 4,
    );
  }

  /// Create a polyline for delivery route (Google Maps)
  static Polyline createDeliveryRoute({
    required List<LatLng> points,
    Color? color,
    double? width,
    String? routeId,
  }) {
    return Polyline(
      polylineId: PolylineId('delivery_route_${routeId ?? 'main'}'),
      points: points,
      color: color ?? const Color(0xFF000000), // Black to match theme
      width: width?.toInt() ?? 6,
      visible: true,
      patterns: [
        PatternItem.dash(20),
        PatternItem.gap(10),
      ],
    );
  }

  /// Create a circle for delivery radius (Google Maps)
  static Circle createDeliveryRadius({
    required LatLng center,
    required double radiusInMeters,
    Color? color,
    String? radiusId,
  }) {
    return Circle(
      circleId: CircleId('delivery_radius_${radiusId ?? 'main'}'),
      center: center,
      radius: radiusInMeters,
      fillColor: (color ?? const Color(0xFF000000)).withValues(alpha: 0.1),
      strokeColor: color ?? const Color(0xFF000000),
      strokeWidth: 2,
      visible: true,
    );
  }

  /// Create custom marker icon for restaurants
  static Future<BitmapDescriptor> createRestaurantIcon({
    bool isDelivery = false,
    String? rating,
  }) async {
    // This would create a custom marker icon based on the app design
    // For now, using default markers with different colors
    return BitmapDescriptor.defaultMarkerWithHue(
      isDelivery ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueRed,
    );
  }

  /// Calculate distance between two points (in kilometers)
  /// Using Haversine formula for accurate distance calculation
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLonRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLonRad / 2) * math.sin(deltaLonRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate bearing between two points (in degrees)
  static double calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * math.pi / 180;
    final double lat2 = end.latitude * math.pi / 180;
    final double deltaLon = (end.longitude - start.longitude) * math.pi / 180;

    final double y = math.sin(deltaLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLon);
    final double bearing = math.atan2(y, x);

    return (bearing * 180 / math.pi + 360) % 360;
  }

  /// Check if point is within radius
  static bool isWithinRadius({
    required LatLng center,
    required LatLng point,
    required double radiusInKm,
  }) {
    final distance = calculateDistance(center, point);
    return distance <= radiusInKm;
  }

  /// Convert latlong2 LatLng to Google Maps LatLng (they are compatible)
  static LatLng convertLatLng(ll.LatLng latLng) {
    return LatLng(latLng.latitude, latLng.longitude);
  }

  /// Create bounds for multiple points
  static LatLngBounds createBoundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
