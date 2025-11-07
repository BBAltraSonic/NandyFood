import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/core/config/map_config.dart';

class HomeMapViewWidget extends StatefulWidget {
  final List<Restaurant> restaurants;
  final LatLng? userLocation;
  final Function(Restaurant)? onRestaurantTapped;
  final double? height;
  final bool showRestaurantPreview;
  final bool showPickupMarkers;

  const HomeMapViewWidget({
    super.key,
    required this.restaurants,
    this.userLocation,
    this.onRestaurantTapped,
    this.height,
    this.showRestaurantPreview = true,
    this.showPickupMarkers = false,
  });

  @override
  State<HomeMapViewWidget> createState() => _HomeMapViewWidgetState();
}

class _HomeMapViewWidgetState extends State<HomeMapViewWidget>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  Restaurant? _selectedRestaurant;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  double _currentZoom = 13.0;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for preview card
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    // Build initial markers
    _buildMarkers();

    // Center map on user after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerMapOnUser();
    });
  }

  @override
  void didUpdateWidget(HomeMapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild markers if restaurant list changes
    if (oldWidget.restaurants != widget.restaurants ||
        oldWidget.userLocation != widget.userLocation ||
        oldWidget.showPickupMarkers != widget.showPickupMarkers) {
      _buildMarkers();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _centerMapOnUser();
  }

  Future<void> _centerMapOnUser() async {
    if (_mapController != null && widget.userLocation != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: widget.userLocation!,
            zoom: _currentZoom,
          ),
        ),
      );
    }
  }

  void _onMarkerTapped(Restaurant restaurant) {
    setState(() {
      _selectedRestaurant = restaurant;
    });

    // Trigger animation for preview card
    _animationController.reset();
    _animationController.forward();

    // Smoothly move map to center on restaurant with slight offset for preview card
    if (_mapController != null &&
        restaurant.latitude != null && restaurant.latitude != 0 &&
        restaurant.longitude != null && restaurant.longitude != 0) {
      final targetZoom = _currentZoom < 14 ? 15.0 : _currentZoom;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(restaurant.latitude!, restaurant.longitude!),
            zoom: targetZoom,
          ),
        ),
      );
    }
  }

  void _closePreviewCard() {
    setState(() {
      _selectedRestaurant = null;
    });
    _animationController.reverse();
  }

  Future<void> _onZoomIn() async {
    if (_currentZoom < 18.0 && _mapController != null) {
      setState(() {
        _currentZoom += 1;
      });
      await _mapController!.animateCamera(
        CameraUpdate.zoomTo(_currentZoom),
      );
    }
  }

  Future<void> _onZoomOut() async {
    if (_currentZoom > 10.0 && _mapController != null) {
      setState(() {
        _currentZoom -= 1;
      });
      await _mapController!.animateCamera(
        CameraUpdate.zoomTo(_currentZoom),
      );
    }
  }

  void _buildMarkers() {
    final markers = <Marker>[];

    // Add restaurant markers using MapConfig
    for (final restaurant in widget.restaurants) {
      if (restaurant.latitude != 0 && restaurant.longitude != 0) {
        final isSelected = _selectedRestaurant?.id == restaurant.id;

        // Use different colors for selected restaurants
        final markerColor = widget.showPickupMarkers
            ? BitmapDescriptor.hueYellow
            : isSelected
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueRed;

        markers.add(
          Marker(
            markerId: MarkerId('restaurant_${restaurant.id}'),
            position: LatLng(restaurant.latitude ?? 0.0, restaurant.longitude ?? 0.0),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            infoWindow: InfoWindow(
              title: restaurant.name,
              snippet: widget.showPickupMarkers
                  ? 'Pickup Available • ${restaurant.cuisineType}'
                  : 'Delivery Available • ${restaurant.cuisineType}',
            ),
            onTap: () => _onMarkerTapped(restaurant),
            visible: true,
            zIndexInt: isSelected ? 3 : 2,
          ),
        );

        // Add rating indicator for highly rated restaurants
        if (restaurant.rating >= 4.5 && !isSelected) {
          markers.add(
            Marker(
              markerId: MarkerId('rating_${restaurant.id}'),
              position: LatLng(
                (restaurant.latitude ?? 0.0) + 0.0005, // Slight offset for visibility
                (restaurant.longitude ?? 0.0) + 0.0005,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              infoWindow: InfoWindow(
                title: '⭐ ${restaurant.rating.toStringAsFixed(1)}',
                snippet: 'Highly Rated',
              ),
              visible: true,
              zIndexInt: 1,
            ),
          );
        }
      }
    }

    // Add user location marker
    if (widget.userLocation != null) {
      markers.add(
        MapConfig.createUserMarker(position: widget.userLocation!),
      );
    }

    setState(() {
      _markers = markers.toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mapWidget = Stack(
      children: [
        // Google Map with dark mode style
        GoogleMap(
          initialCameraPosition: MapConfig.getDefaultCameraPosition(
            center: widget.userLocation ?? const LatLng(40.7128, -74.0060),
            zoom: _currentZoom,
          ),
          onMapCreated: _onMapCreated,
          markers: _markers,
          style: MapConfig.darkMapStyle,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false, // Using custom controls
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Using custom recenter button
          zoomGesturesEnabled: true,
          scrollGesturesEnabled: true,
          rotateGesturesEnabled: true,
          tiltGesturesEnabled: true,
          minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
          onCameraMove: (CameraPosition position) {
            if (_currentZoom != position.zoom) {
              setState(() {
                _currentZoom = position.zoom;
              });
            }
          },
          onTap: (LatLng position) {
            // Close preview card when tapping on map
            if (_selectedRestaurant != null) {
              _closePreviewCard();
            }
          },
        ),

        // Map controls cluster (right side) - Black theme
        Positioned(
          top: 16,
          right: 32, // Increased to 32px for better clearance from Categories
          child: Material(
            elevation: 8, // Add elevation for proper z-index layering
            color: Colors.transparent,
            child: Column(
            children: [
              // Zoom in button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onZoomIn,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Zoom out button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onZoomOut,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),

        // Recenter button (bottom right) - Black theme
        Positioned(
          bottom: _selectedRestaurant != null ? 120 : 16,
          right: 32, // Increased to 32px to match zoom controls
          child: Material(
            elevation: 8, // Add elevation for proper z-index layering
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _centerMapOnUser,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              ),
            ),
          ),
        ),

        // Restaurant preview card (animated)
        if (_selectedRestaurant != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 80, // Reduced to prevent overlap with recenter button
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildRestaurantPreviewCard(_selectedRestaurant!),
            ),
          ),
      ],
    );

    // If height is provided, wrap with Container (for compatibility with existing usage)
    if (widget.height != null) {
      return Container(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: mapWidget,
        ),
      );
    }

    // Otherwise return full map widget
    return mapWidget;
  }

  Widget _buildRestaurantPreviewCard(Restaurant restaurant) {
    final theme = Theme.of(context);

    return Card(
      elevation: 12,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              widget.onRestaurantTapped?.call(restaurant);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Restaurant image/logo
                  Hero(
                    tag: 'restaurant_${restaurant.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                              theme.colorScheme.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Restaurant details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          restaurant.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                restaurant.cuisineType,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Rating
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black87.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.black87,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    restaurant.rating.toStringAsFixed(1),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delivery time
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.estimatedDeliveryTime} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _closePreviewCard,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
