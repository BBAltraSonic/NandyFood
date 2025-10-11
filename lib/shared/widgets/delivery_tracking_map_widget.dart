import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:food_delivery_app/shared/models/delivery.dart';
import 'package:food_delivery_app/shared/models/order.dart';

class DeliveryTrackingMapWidget extends StatefulWidget {
  final Order order;
  final Delivery? delivery;

  const DeliveryTrackingMapWidget({
    Key? key,
    required this.order,
    this.delivery,
  }) : super(key: key);

  @override
  State<DeliveryTrackingMapWidget> createState() =>
      _DeliveryTrackingMapWidgetState();
}

class _DeliveryTrackingMapWidgetState extends State<DeliveryTrackingMapWidget> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // Center the map on the estimated delivery location or restaurant
    _centerMap();
  }

  void _centerMap() {
    // In a real implementation, we would use actual coordinates
    // For now, using placeholder coordinates
    double lat = 40.7128; // Default to New York coordinates
    double lng = -74.0060;

    // Try to get restaurant location if available
    if (orderHasRestaurantLocation()) {
      // Use restaurant coordinates
      lat = 40.7228; // Placeholder
      lng = -74.0160; // Placeholder
    }

    // If delivery has location, center on that
    if (widget.delivery?.currentLocation != null) {
      lat = widget.delivery!.currentLocation!['lat'] ?? lat;
      lng = widget.delivery!.currentLocation!['lng'] ?? lng;
    }

    mapController.move(
      LatLng(lat, lng),
      13.0, // Zoom level
    );
  }

  bool orderHasRestaurantLocation() {
    // Check if we have restaurant location data
    // This would be implemented based on your Restaurant model
    return true; // Placeholder
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> markers = [];

    // Add restaurant marker
    markers.add(
      Marker(
        width: 60,
        height: 60,
        point: LatLng(40.7228, -74.0160), // Placeholder restaurant coordinates
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
        ),
      ),
    );

    // Add delivery/driver marker if available
    if (widget.delivery?.currentLocation != null) {
      markers.add(
        Marker(
          width: 60,
          height: 60,
          point: LatLng(
            widget.delivery!.currentLocation!['lat'],
            widget.delivery!.currentLocation!['lng'],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Add destination/user marker
    markers.add(
      Marker(
        width: 60,
        height: 60,
        point: LatLng(40.7028, -74.0060), // Placeholder destination coordinates
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.home, color: Colors.white, size: 20),
        ),
      ),
    );

    return Container(
      height: 200, // Fixed height for the map
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: LatLng(40.7128, -74.0060), // Default center
          initialZoom: 13.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.food_delivery_app',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
