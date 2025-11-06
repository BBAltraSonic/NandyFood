
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TempMapScreen extends StatefulWidget {
  const TempMapScreen({super.key});

  @override
  State<TempMapScreen> createState() => _TempMapScreenState();
}

class _TempMapScreenState extends State<TempMapScreen> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(-33.9249, 18.4241); // Cape Town

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 11.0,
        ),
      ),
    );
  }
}
