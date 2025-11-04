
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:food_delivery_app/core/config/map_config.dart';

/// Live tracking map widget
class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    required this.driverLocation,
    required this.destinationLocation,
    this.driverHeading,
    this.showRoute = true,
    this.animationDuration = const Duration(milliseconds: 800),
    super.key,
  });

  final LatLng driverLocation;
  final LatLng destinationLocation;
  final double? driverHeading;
  final bool showRoute;
  final Duration animationDuration;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _animationController;
  late Animation<double> _latAnimation;
  late Animation<double> _lngAnimation;

  LatLng? _currentAnimatedLocation;
  bool _isInitialized = false;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _currentAnimatedLocation = widget.driverLocation;

    // Build initial markers and polylines
    _buildMarkers();
    _buildPolylines();

    // Initial map position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
      _isInitialized = true;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate driver location change with small-movement gating
    if (oldWidget.driverLocation != widget.driverLocation) {
      final dist = _approxDistanceMeters(
        oldWidget.driverLocation.latitude,
        oldWidget.driverLocation.longitude,
        widget.driverLocation.latitude,
        widget.driverLocation.longitude,
      );

      // Skip tiny movements to reduce animation churn
      if (dist >= 5) {
        if (_animationController.isAnimating && dist < 20) {
          // If animating and movement is small, skip starting another animation
        } else {
          _animateDriverMovement(
            from: _currentAnimatedLocation ?? oldWidget.driverLocation,
            to: widget.driverLocation,
          );
        }
      }
    }

    // Update markers and polylines if locations changed
    if (oldWidget.driverLocation != widget.driverLocation ||
        oldWidget.destinationLocation != widget.destinationLocation ||
        oldWidget.driverHeading != widget.driverHeading) {
      _buildMarkers();
      _buildPolylines();
    }

    // Update map bounds if destination changed
    if (oldWidget.destinationLocation != widget.destinationLocation) {
      _fitBounds();
    }
  }

  void _animateDriverMovement({required LatLng from, required LatLng to}) {


    _latAnimation = Tween<double>(
      begin: from.latitude,
      end: to.latitude,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ))..addListener(() {
        setState(() {
          _currentAnimatedLocation = LatLng(
            _latAnimation.value,
            _lngAnimation.value,
          );
        });
      });

    _lngAnimation = Tween<double>(
      begin: from.longitude,
      end: to.longitude,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController
      ..reset()
      ..forward().then((_) {
        _currentAnimatedLocation = to;
      });
  }

  double _approxDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371000; // meters
    final phi1 = lat1 * (math.pi / 180);
    final phi2 = lat2 * (math.pi / 180);
    final dPhi = (lat2 - lat1) * (math.pi / 180);
    final dLambda = (lng2 - lng1) * (math.pi / 180);
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  Future<void> _fitBounds() async {
    if (!_isInitialized || _mapController == null) return;

    final bounds = MapConfig.createBoundsFromPoints([
      widget.driverLocation,
      widget.destinationLocation,
    ]);

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  void _buildMarkers() {
    final markers = <Marker>[];

    // Destination marker
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Delivery Destination'),
        visible: true,
        zIndexInt: 2,
      ),
    );

    // Driver marker (animated)
    if (_currentAnimatedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _currentAnimatedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Delivery Driver'),
          visible: true,
          rotation: widget.driverHeading ?? 0.0,
          flat: true,
          zIndexInt: 3,
        ),
      );
    }

    setState(() {
      _markers = markers.toSet();
    });
  }

  void _buildPolylines() {
    final polylines = <Polyline>[];

    // Route polyline
    if (widget.showRoute && _currentAnimatedLocation != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [
            _currentAnimatedLocation!,
            widget.destinationLocation,
          ],
          color: const Color(0xFF000000), // Black to match theme
          width: 6,
          patterns: [
            PatternItem.dash(20),
            PatternItem.gap(10),
          ],
          visible: true,
        ),
      );
    }

    setState(() {
      _polylines = polylines.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.driverLocation,
            zoom: 14,
          ),
          onMapCreated: _onMapCreated,
          markers: _markers,
          polylines: _polylines,
          style: MapConfig.darkMapStyle,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: false, // Disabled for live tracking
          tiltGesturesEnabled: false,  // Disabled for live tracking
          minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// Map controls widget
class MapControls extends StatelessWidget {
  const MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
    super.key,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: onZoomIn,
          heroTag: 'zoom_in',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onZoomOut,
          heroTag: 'zoom_out',
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onRecenter,
          heroTag: 'recenter',
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
