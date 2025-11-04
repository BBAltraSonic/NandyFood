import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

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
  late MapController _mapController;
  Restaurant? _selectedRestaurant;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Initialize animation controller for preview card
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _centerMapOnUser();
  }

  void _centerMapOnUser() {
    if (widget.userLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.userLocation!, 13.0);
      });
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
    if (restaurant.latitude != 0 && restaurant.longitude != 0) {
      final targetZoom = _currentZoom < 14 ? 15.0 : _currentZoom;
      _mapController.move(
        LatLng(restaurant.latitude, restaurant.longitude),
        targetZoom,
      );
    }
  }

  void _closePreviewCard() {
    setState(() {
      _selectedRestaurant = null;
    });
    _animationController.reverse();
  }

  void _onZoomIn() {
    if (_currentZoom < 18.0) {
      setState(() {
        _currentZoom += 1;
      });
      _mapController.move(_mapController.camera.center, _currentZoom);
    }
  }

  void _onZoomOut() {
    if (_currentZoom > 10.0) {
      setState(() {
        _currentZoom -= 1;
      });
      _mapController.move(_mapController.camera.center, _currentZoom);
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Add restaurant markers with custom styling
    for (final restaurant in widget.restaurants) {
      if (restaurant.latitude != 0 && restaurant.longitude != 0) {
        final isSelected = _selectedRestaurant?.id == restaurant.id;

        // Different styling for pickup markers
        if (widget.showPickupMarkers) {
          markers.add(
            Marker(
              width: isSelected ? 70 : 60,
              height: isSelected ? 70 : 60,
              point: LatLng(restaurant.latitude, restaurant.longitude),
              child: GestureDetector(
                onTap: () => _onMarkerTapped(restaurant),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: isSelected ? 4 : 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        blurRadius: isSelected ? 12 : 8,
                        offset: const Offset(0, 3),
                        spreadRadius: isSelected ? 2 : 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.takeout_dining,
                        color: Colors.white,
                        size: isSelected ? 32 : 28,
                      ),
                      // Pickup badge
                      if (!isSelected)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_bag,
                              color: Theme.of(context).colorScheme.primary,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          markers.add(
            Marker(
              width: isSelected ? 60 : 50,
              height: isSelected ? 60 : 50,
              point: LatLng(restaurant.latitude, restaurant.longitude),
              child: GestureDetector(
                onTap: () => _onMarkerTapped(restaurant),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                        spreadRadius: isSelected ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.restaurant,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        size: isSelected ? 28 : 24,
                      ),
                      // Rating badge for highly rated restaurants
                      if (restaurant.rating >= 4.5 && !isSelected)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // Add user location marker
    if (widget.userLocation != null) {
      markers.add(
        Marker(
          width: 60,
          height: 60,
          point: widget.userLocation!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black87.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 3),
            ),
            child: const Icon(Icons.person_pin, color: Colors.black87, size: 30),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final mapWidget = Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                widget.userLocation ?? const LatLng(40.7128, -74.0060),
            initialZoom: _currentZoom,
            minZoom: 10.0,
            maxZoom: 18.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.food_delivery_app',
            ),
            MarkerLayer(markers: _buildMarkers()),
          ],
        ),

        // Map controls cluster (right side)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Zoom in button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                      child: Icon(
                        Icons.add,
                        color: theme.colorScheme.primary,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                      child: Icon(
                        Icons.remove,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Recenter button (bottom right)
        Positioned(
          bottom: _selectedRestaurant != null ? 100 : 16,
          right: 16,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                    size: 24,
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
            right: 80,
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
    _mapController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
