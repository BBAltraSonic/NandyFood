import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:geolocator/geolocator.dart';
import 'package:food_delivery_app/core/services/location_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/core/config/map_config.dart';

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
  GoogleMapController? mapController;
  Position? userPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    // Get user's current position
    _getUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _centerMapOnUser();
  }

  Future<void> _getUserLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      setState(() {
        userPosition = position;
      });

      // Build markers after getting user location
      _buildMarkers();

      // Center the map on user's location
      _centerMapOnUser();
    } catch (e) {
      print('Error getting user location: $e');
      // Still build markers even if location fails
      _buildMarkers();
    }
  }

  Future<void> _centerMapOnUser() async {
    if (mapController != null && userPosition != null) {
      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(userPosition!.latitude, userPosition!.longitude),
            zoom: 13.0,
          ),
        ),
      );
    }
  }

  void _buildMarkers() {
    final markers = <Marker>[];

    // Add user location marker if available
    if (userPosition != null) {
      markers.add(
        MapConfig.createUserMarker(
          position: LatLng(userPosition!.latitude, userPosition!.longitude),
        ),
      );
    }

    // Add restaurant markers
    for (final restaurant in widget.restaurants) {
      try {
        // Use restaurant latitude/longitude from the model
        if (restaurant.latitude != 0 && restaurant.longitude != 0) {
          markers.add(
            MapConfig.createRestaurantMarker(
              position: LatLng(restaurant.latitude, restaurant.longitude),
              restaurantId: restaurant.id,
              restaurantName: restaurant.name,
              rating: restaurant.rating.toString(),
              onTap: () => widget.onRestaurantTapped?.call(restaurant),
            ),
          );
        }
      } catch (e) {
        // Skip this restaurant if coordinates are invalid
        print('Error adding marker for restaurant: $e');
      }
    }

    setState(() {
      _markers = markers.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initial camera position
    LatLng initialPosition = const LatLng(40.7128, -74.0060); // Default to NYC

    // Use provided user coordinates if available
    if (widget.userLat != null && widget.userLng != null) {
      initialPosition = LatLng(widget.userLat!, widget.userLng!);
    }

    // Use current location if available
    if (userPosition != null) {
      initialPosition = LatLng(userPosition!.latitude, userPosition!.longitude);
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 13.0,
      ),
      onMapCreated: _onMapCreated,
      markers: _markers,
      style: MapConfig.darkMapStyle,
      compassEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: true,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      minMaxZoomPreference: const MinMaxZoomPreference(3.0, 18.0),
    );
  }
}
