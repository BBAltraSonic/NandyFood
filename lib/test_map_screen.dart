import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:food_delivery_app/core/config/map_config.dart';

/// Test widget to verify Google Maps functionality
class TestMapScreen extends StatefulWidget {
  const TestMapScreen({super.key});

  @override
  State<TestMapScreen> createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    debugPrint('TestMapScreen: Building widget...');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Test'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: GoogleMap(
        initialCameraPosition: MapConfig.getDefaultCameraPosition(
          center: const LatLng(40.7128, -74.0060), // NYC
          zoom: 13.0,
        ),
        onMapCreated: (GoogleMapController controller) {
          debugPrint('TestMapScreen: GoogleMap created!');
          _mapController = controller;
        },
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
        markers: {
          // Add a test marker
          Marker(
            markerId: const MarkerId('test_marker'),
            position: const LatLng(40.7128, -74.0060),
            infoWindow: const InfoWindow(
              title: 'Test Location',
              snippet: 'Google Maps is working!',
            ),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('TestMapScreen: FAB pressed - animating camera');
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(
                target: LatLng(40.7580, -73.9855), // Times Square
                zoom: 15.0,
              ),
            ),
          );
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.location_city, color: Colors.white),
      ),
    );
  }
}