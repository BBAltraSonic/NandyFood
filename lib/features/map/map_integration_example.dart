import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:food_delivery_app/core/config/map_config.dart';

/// Example implementation of map integration for NandyFood
///
/// This file demonstrates:
/// - Basic map setup with OpenStreetMap
/// - Restaurant markers
/// - User location marker
/// - Delivery route visualization
/// - Real-time driver tracking
class MapIntegrationExample extends StatefulWidget {
  const MapIntegrationExample({super.key});

  @override
  State<MapIntegrationExample> createState() => _MapIntegrationExampleState();
}

class _MapIntegrationExampleState extends State<MapIntegrationExample> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  LatLng? _deliveryDriverLocation;
  List<LatLng> _deliveryRoute = [];

  // Sample restaurant locations
  final List<RestaurantMapData> _restaurants = [
    RestaurantMapData(
      id: '1',
      name: 'Pizza Palace',
      position: LatLng(40.7589, -73.9851),
    ),
    RestaurantMapData(
      id: '2',
      name: 'Burger Haven',
      position: LatLng(40.7614, -73.9776),
    ),
    RestaurantMapData(
      id: '3',
      name: 'Sushi Station',
      position: LatLng(40.7549, -73.9840),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    // In production, use geolocator package to get actual location
    // For demo, using Times Square as user location
    setState(() {
      _userLocation = LatLng(40.7580, -73.9855);
    });

    // Center map on user location
    if (_userLocation != null) {
      _mapController.move(_userLocation!, MapConfig.defaultZoom);
    }
  }

  void _onRestaurantTapped(RestaurantMapData restaurant) {
    // Show restaurant details or navigate to restaurant page
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tapped: ${restaurant.name}')));
  }

  void _simulateDeliveryTracking() {
    // Simulate delivery tracking by updating driver location
    setState(() {
      _deliveryDriverLocation = LatLng(40.7600, -73.9800);
      _deliveryRoute = [
        LatLng(40.7589, -73.9851), // Restaurant
        LatLng(40.7600, -73.9820),
        LatLng(40.7600, -73.9800), // Current
        LatLng(40.7580, -73.9855), // User location
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Integration Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_userLocation != null) {
                _mapController.move(_userLocation!, MapConfig.defaultZoom);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapConfig.getDefaultMapOptions(
              center: _userLocation ?? MapConfig.defaultCenter,
              onTap: (point) {
                print('Map tapped at: $point');
              },
            ),
            children: [
              // Tile layer (OpenStreetMap)
              MapConfig.defaultTileLayer,

              // Delivery route polyline (if tracking active)
              if (_deliveryRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    MapConfig.createDeliveryRoute(
                      points: _deliveryRoute,
                      color: Colors.blue,
                    ),
                  ],
                ),

              // Restaurant markers
              MarkerLayer(
                markers: _restaurants.map((restaurant) {
                  return MapConfig.createRestaurantMarker(
                    position: restaurant.position,
                    restaurantId: restaurant.id,
                    restaurantName: restaurant.name,
                    onTap: () => _onRestaurantTapped(restaurant),
                  );
                }).toList(),
              ),

              // User location marker
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    MapConfig.createUserMarker(position: _userLocation!),
                  ],
                ),

              // Delivery driver marker
              if (_deliveryDriverLocation != null)
                MarkerLayer(
                  markers: [
                    MapConfig.createDeliveryMarker(
                      position: _deliveryDriverLocation!,
                      rotation: _calculateDriverRotation(),
                    ),
                  ],
                ),

              // Delivery radius circle (example: 5km)
              if (_userLocation != null)
                CircleLayer(
                  circles: [
                    MapConfig.createDeliveryRadius(
                      center: _userLocation!,
                      radiusInMeters: 5000, // 5km
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ],
                ),

              // Attribution layer (required for OSM)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    MapConfig.attribution,
                    onTap: () {
                      // Open OSM website
                    },
                  ),
                ],
              ),
            ],
          ),

          // Controls overlay
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                // Zoom in button
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_in',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),

                // Zoom out button
                FloatingActionButton(
                  mini: true,
                  heroTag: 'zoom_out',
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),

                // Simulate delivery button
                FloatingActionButton(
                  mini: true,
                  heroTag: 'delivery',
                  onPressed: _simulateDeliveryTracking,
                  child: const Icon(Icons.delivery_dining),
                ),
              ],
            ),
          ),

          // Info card at top
          if (_deliveryDriverLocation != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery in Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Distance to you: ${_calculateDistanceToUser().toStringAsFixed(2)} km',
                      ),
                      Text('Estimated time: ${_calculateEstimatedTime()} min'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateDriverRotation() {
    if (_deliveryRoute.length < 2 || _deliveryDriverLocation == null) {
      return 0;
    }

    // Calculate bearing to next point
    final currentIndex = _deliveryRoute.indexWhere(
      (point) => point == _deliveryDriverLocation,
    );

    if (currentIndex >= 0 && currentIndex < _deliveryRoute.length - 1) {
      return MapConfig.calculateBearing(
        _deliveryRoute[currentIndex],
        _deliveryRoute[currentIndex + 1],
      );
    }

    return 0;
  }

  double _calculateDistanceToUser() {
    if (_userLocation == null || _deliveryDriverLocation == null) {
      return 0;
    }

    return MapConfig.calculateDistance(
      _deliveryDriverLocation!,
      _userLocation!,
    );
  }

  int _calculateEstimatedTime() {
    // Simple estimation: 1 km = 3 minutes
    final distance = _calculateDistanceToUser();
    return (distance * 3).round();
  }
}

/// Data model for restaurant on map
class RestaurantMapData {
  final String id;
  final String name;
  final LatLng position;

  RestaurantMapData({
    required this.id,
    required this.name,
    required this.position,
  });
}
