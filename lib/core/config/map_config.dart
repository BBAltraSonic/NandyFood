import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Configuration for flutter_map integration
class MapConfig {
  MapConfig._();

  /// OpenStreetMap tile layer URL
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Alternative tile providers
  static const String osmHotTileUrl =
      'https://tile-{s}.openstreetmap.fr/hot/{z}/{x}/{y}.png';
  static const String cartoTileUrl =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Default map center (New York City)
  static const LatLng defaultCenter = LatLng(40.7128, -74.0060);

  /// Default zoom level
  static const double defaultZoom = 13.0;

  /// Minimum and maximum zoom levels
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  /// User attribution text (required for OSM)
  static const String attribution = '© OpenStreetMap contributors';

  /// Custom marker icons
  static const double markerSize = 40.0;
  static const Color restaurantMarkerColor = Colors.red;
  static const Color userMarkerColor = Colors.blue;
  static const Color deliveryMarkerColor = Colors.green;

  /// Create default tile layer for OpenStreetMap
  static TileLayer get defaultTileLayer => TileLayer(
    urlTemplate: osmTileUrl,
    userAgentPackageName: 'com.nandyfood.app',
    maxZoom: maxZoom,
    minZoom: minZoom,
  );

  /// Create alternative tile layer (CartoDB)
  static TileLayer get cartoTileLayer => TileLayer(
    urlTemplate: cartoTileUrl,
    subdomains: const ['a', 'b', 'c', 'd'],
    userAgentPackageName: 'com.nandyfood.app',
    maxZoom: maxZoom,
    minZoom: minZoom,
  );

  /// Create default map options
  static MapOptions getDefaultMapOptions({
    LatLng? center,
    double? zoom,
    void Function(LatLng)? onTap,
    void Function(LatLng)? onLongPress,
  }) {
    return MapOptions(
      initialCenter: center ?? defaultCenter,
      initialZoom: zoom ?? defaultZoom,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onTap: (tapPosition, point) => onTap?.call(point),
      onLongPress: (tapPosition, point) => onLongPress?.call(point),
    );
  }

  /// Create a restaurant marker
  static Marker createRestaurantMarker({
    required LatLng position,
    required String restaurantId,
    required String restaurantName,
    required VoidCallback onTap,
  }) {
    return Marker(
      point: position,
      width: markerSize,
      height: markerSize,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: restaurantMarkerColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 20,
              ),
            ),
            Container(
              width: 0,
              height: 0,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.transparent, width: 4),
                  right: BorderSide(color: Colors.transparent, width: 4),
                  bottom: BorderSide(color: restaurantMarkerColor, width: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create a user location marker
  static Marker createUserMarker({required LatLng position}) {
    return Marker(
      point: position,
      width: markerSize,
      height: markerSize,
      child: Container(
        decoration: BoxDecoration(
          color: userMarkerColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }

  /// Create a delivery driver marker
  static Marker createDeliveryMarker({
    required LatLng position,
    double? rotation,
  }) {
    return Marker(
      point: position,
      width: markerSize,
      height: markerSize,
      rotate: true,
      child: Transform.rotate(
        angle: rotation ?? 0,
        child: Container(
          decoration: BoxDecoration(
            color: deliveryMarkerColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.delivery_dining,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Create a polyline for delivery route
  static Polyline createDeliveryRoute({
    required List<LatLng> points,
    Color? color,
    double? strokeWidth,
  }) {
    return Polyline(
      points: points,
      color: color ?? Colors.blue,
      strokeWidth: strokeWidth ?? 4.0,
      borderColor: Colors.white,
      borderStrokeWidth: 2.0,
    );
  }

  /// Create a circle marker for delivery radius
  static CircleMarker createDeliveryRadius({
    required LatLng center,
    required double radiusInMeters,
    Color? color,
  }) {
    return CircleMarker(
      point: center,
      radius: radiusInMeters,
      useRadiusInMeter: true,
      color: (color ?? Colors.blue).withOpacity(0.1),
      borderColor: color ?? Colors.blue,
      borderStrokeWidth: 2.0,
    );
  }

  /// Calculate distance between two points (in kilometers)
  static double calculateDistance(LatLng point1, LatLng point2) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Calculate bearing between two points (in degrees)
  static double calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitudeInRad;
    final lat2 = end.latitudeInRad;
    final dLon = end.longitudeInRad - start.longitudeInRad;

    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x);

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
}
