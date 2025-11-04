
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  late final MapController _mapController;
  late AnimationController _animationController;
  late Animation<double> _latAnimation;
  late Animation<double> _lngAnimation;


  LatLng? _currentAnimatedLocation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );


    _currentAnimatedLocation = widget.driverLocation;

    // Initial map position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
      _isInitialized = true;
    });
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

  void _fitBounds() {
    if (!_isInitialized) return;

    final bounds = LatLngBounds(
      widget.driverLocation,
      widget.destinationLocation,
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.driverLocation,
            initialZoom: 14,
            minZoom: 10,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Map tiles
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.food_delivery_app',
              tileProvider: NetworkTileProvider(),
              keepBuffer: 2,
            ),

            // Route polyline
            if (widget.showRoute && _currentAnimatedLocation != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [
                      _currentAnimatedLocation!,
                      widget.destinationLocation,
                    ],
                    strokeWidth: 4,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    isDotted: true,
                  ),
                ],
              ),

            // Markers
            MarkerLayer(
              markers: [
                // Destination marker
                Marker(
                  point: widget.destinationLocation,
                  width: 40,
                  height: 40,
                  child: _buildDestinationMarker(),
                ),

                // Driver marker (animated)
                if (_currentAnimatedLocation != null)
                  Marker(
                    point: _currentAnimatedLocation!,
                    width: 50,
                    height: 50,
                    child: _buildDriverMarker(),
                  ),
              ],
            ),

            // Attribution
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {}, // You can add a link to OSM if needed
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverMarker() {
    return Transform.rotate(
      angle: widget.driverHeading != null
          ? (widget.driverHeading! * 3.14159 / 180) // Convert to radians
          : 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black87.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.delivery_dining,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildDestinationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black87.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
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
