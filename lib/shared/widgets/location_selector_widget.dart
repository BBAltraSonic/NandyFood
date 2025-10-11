import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationSelectorWidget extends StatefulWidget {
  final Map<String, dynamic>? initialLocation;
  final ValueChanged<Map<String, dynamic>>? onLocationSelected;

  const LocationSelectorWidget({
    super.key,
    this.initialLocation,
    this.onLocationSelected,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  late TextEditingController _searchController;
  late Map<String, dynamic>? _selectedLocation;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();

      // Convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final location = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'street': placemark.street ?? '',
          'city': placemark.locality ?? '',
          'state': placemark.administrativeArea ?? '',
          'country': placemark.country ?? '',
          'postalCode': placemark.postalCode ?? '',
        };

        setState(() {
          _selectedLocation = location;
          _isLoading = false;
        });

        if (widget.onLocationSelected != null) {
          widget.onLocationSelected!(location);
        }
      } else {
        throw Exception('Unable to get address from location');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Search for location
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          final selectedLocation = {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'street': placemark.street ?? '',
            'city': placemark.locality ?? '',
            'state': placemark.administrativeArea ?? '',
            'country': placemark.country ?? '',
            'postalCode': placemark.postalCode ?? '',
          };

          setState(() {
            _selectedLocation = selectedLocation;
            _isLoading = false;
          });

          if (widget.onLocationSelected != null) {
            widget.onLocationSelected!(selectedLocation);
          }
        } else {
          throw Exception('Unable to get address from location');
        }
      } else {
        throw Exception('No locations found for "$query"');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for address',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _selectedLocation = null;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (value == _searchController.text && value.isNotEmpty) {
                _searchLocation(value);
              }
            });
          },
          onSubmitted: _searchLocation,
        ),
        const SizedBox(height: 16),

        // Current location button
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _getCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: const Text('Use Current Location'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Selected location display
        if (_selectedLocation != null) ...[
          Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedLocation!['street']}, ${_selectedLocation!['city']}, ${_selectedLocation!['state']}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_selectedLocation!['latitude'].toStringAsFixed(6)}, '
                    'Lng: ${_selectedLocation!['longitude'].toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Loading indicator
        if (_isLoading) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
        ],

        // Error message
        if (_errorMessage != null) ...[
          Card(
            margin: EdgeInsets.zero,
            color: Colors.red.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
