import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_delivery_app/core/services/location_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

class LocationMapWidget extends StatefulWidget {
  final List<Restaurant> restaurants;
  final Function(Restaurant)? onRestaurantTapped;
  final double? userLat;
  final double? userLng;

  const LocationMapWidget({
    Key? key,
    required this.restaurants,
    this.onRestaurantTapped,
    this.userLat,
    this.userLng,
  }) : super(key: key);

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  late MapController mapController;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    
    // Get user's current position
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      
      setState(() {
        userPosition = position;
      });
      
      // Center the map on user's location
      mapController.move(
        LatLng(position.latitude, position.longitude),
        13.0, // Zoom level
      );
    } catch (e) {
      print('Error getting user location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create map markers for restaurants
    List<Marker> markers = [];

    // Add user location marker if available
    if (userPosition != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: LatLng(userPosition!.latitude, userPosition!.longitude),
          child: const Icon(
            Icons.person_pin,
            size: 30,
            color: Colors.blue,
          ),
        ),
      );
    }

    // Add restaurant markers
    for (Restaurant restaurant in widget.restaurants) {
      try {
        // Assuming restaurant address contains lat/lng coordinates
        // This is a simplified approach - in real app, we'd geocode the address
        if (restaurant.address['lat'] != null && restaurant.address['lng'] != null) {
          double lat = restaurant.address['lat'];
          double lng = restaurant.address['lng'];

          markers.add(
            Marker(
              width: 60,
              height: 60,
              point: LatLng(lat, lng),
              child: GestureDetector(
                onTap: () {
                  // Find the restaurant that corresponds to this marker
                  final tappedRestaurant = widget.restaurants.firstWhere(
                    (r) => r.address['lat'] == lat && r.address['lng'] == lng,
                    orElse: () => widget.restaurants.first,
                  );
                  widget.onRestaurantTapped?.call(tappedRestaurant);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }
      } catch (e) {
        // Skip this restaurant if coordinates are invalid
        print('Error adding marker for restaurant: $e');
      }
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: widget.userLat != null && widget.userLng != null
            ? LatLng(widget.userLat!, widget.userLng!)
            : LatLng(0, 0), // Default to 0,0 if no location is provided
        initialZoom: 13.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.food_delivery_app',
        ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }
}