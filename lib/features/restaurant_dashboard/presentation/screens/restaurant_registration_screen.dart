import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class RestaurantRegistrationScreen extends ConsumerStatefulWidget {
  final bool fromSignup;

  const RestaurantRegistrationScreen({
    super.key,
    this.fromSignup = false,
  });

  @override
  ConsumerState<RestaurantRegistrationScreen> createState() =>
      _RestaurantRegistrationScreenState();
}

class _RestaurantRegistrationScreenState
    extends ConsumerState<RestaurantRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form fields
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  String _selectedCuisine = 'Italian';
  double _deliveryRadius = 5.0;
  int _estimatedDeliveryTime = 30;

  final List<String> _selectedDietaryOptions = [];
  final Map<String, Map<String, String>> _operatingHours = {};

  final List<String> _cuisineTypes = [
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'Japanese',
    'American',
    'Thai',
    'Mediterranean',
    'Fast Food',
    'Other',
  ];

  final List<String> _dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Halal',
    'Kosher',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Restaurant'),
        elevation: 0,
        automaticallyImplyLeading: !widget.fromSignup,
      ),
      body: Column(
        children: [
          if (widget.fromSignup) _buildWelcomeBanner(),
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildLocationStep(),
                _buildDetailsStep(),
                _buildOperatingHoursStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(5, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your restaurant',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name',
                hintText: 'Enter restaurant name',
                prefixIcon: Icon(Icons.store_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your restaurant',
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCuisine,
              decoration: const InputDecoration(
                labelText: 'Cuisine Type',
                prefixIcon: Icon(Icons.restaurant_menu_rounded),
              ),
              items: _cuisineTypes.map((cuisine) {
                return DropdownMenuItem(
                  value: cuisine,
                  child: Text(cuisine),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCuisine = value!);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '(555) 123-4567',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'restaurant@example.com',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location & Contact',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Where is your restaurant located?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Street Address',
              hintText: '123 Main Street',
              prefixIcon: Icon(Icons.location_on_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(
                    labelText: 'State',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _zipController,
            decoration: const InputDecoration(
              labelText: 'ZIP Code',
              prefixIcon: Icon(Icons.markunread_mailbox_rounded),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter ZIP code';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your delivery settings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            'Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _deliveryRadius,
            min: 1,
            max: 20,
            divisions: 19,
            label: '${_deliveryRadius.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() => _deliveryRadius = value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Estimated Delivery Time: $_estimatedDeliveryTime minutes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _estimatedDeliveryTime.toDouble(),
            min: 15,
            max: 90,
            divisions: 15,
            label: '$_estimatedDeliveryTime min',
            onChanged: (value) {
              setState(() => _estimatedDeliveryTime = value.toInt());
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Dietary Options',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietaryOptions.map((option) {
              final isSelected = _selectedDietaryOptions.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDietaryOptions.add(option);
                    } else {
                      _selectedDietaryOptions.remove(option);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursStep() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operating Hours',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'When is your restaurant open?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),
          ...days.map((day) {
            final hours = _operatingHours[day] ?? {'open': '09:00', 'close': '22:00'};
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(hours['open'] ?? '09:00'),
                            onPressed: () => _selectTime(context, day, 'open'),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('to'),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(hours['close'] ?? '22:00'),
                            onPressed: () => _selectTime(context, day, 'close'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your information',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          _buildReviewSection('Basic Information', [
            _buildReviewItem('Name', _nameController.text),
            _buildReviewItem('Cuisine', _selectedCuisine),
            _buildReviewItem('Phone', _phoneController.text),
            _buildReviewItem('Email', _emailController.text),
          ]),
          const SizedBox(height: 16),
          _buildReviewSection('Location', [
            _buildReviewItem('Address', _addressController.text),
            _buildReviewItem(
              'City, State',
              '${_cityController.text}, ${_stateController.text} ${_zipController.text}',
            ),
          ]),
          const SizedBox(height: 16),
          _buildReviewSection('Service Details', [
            _buildReviewItem('Delivery Radius', '${_deliveryRadius.toStringAsFixed(1)} km'),
            _buildReviewItem('Delivery Time', '$_estimatedDeliveryTime minutes'),
            if (_selectedDietaryOptions.isNotEmpty)
              _buildReviewItem('Dietary Options', _selectedDietaryOptions.join(', ')),
          ]),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<Widget> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentStep == 4 ? 'Submit' : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, String day, String type) async {
    final currentHours = _operatingHours[day] ?? {'open': '09:00', 'close': '22:00'};
    final currentTime = TimeOfDay(
      hour: int.parse(currentHours[type]!.split(':')[0]),
      minute: int.parse(currentHours[type]!.split(':')[1]),
    );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (pickedTime != null) {
      setState(() {
        _operatingHours[day] = {
          ...currentHours,
          type: '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}',
        };
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 4) {
      // Validate current step
      if (_currentStep == 0 && !_formKey.currentState!.validate()) {
        return;
      }

      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Submit registration
      await _submitRegistration();
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Geocode the address to get latitude and longitude
      double latitude = 0.0;
      double longitude = 0.0;

      try {
        final fullAddress = '${_addressController.text}, ${_cityController.text}, ${_stateController.text} ${_zipController.text}';
        AppLogger.info('Geocoding address: $fullAddress');

        final locations = await locationFromAddress(fullAddress);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
          AppLogger.success('Geocoded coordinates: ($latitude, $longitude)');
        } else {
          AppLogger.warning('No geocoding results found for address');
        }
      } catch (e) {
        AppLogger.error('Geocoding failed, using default coordinates', error: e);
        // Continue with 0,0 coordinates if geocoding fails
      }

      // Create restaurant record
      final response = await DatabaseService().client.from('restaurants').insert({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'cuisine_type': _selectedCuisine,
        'address': {
          'street': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'zip': _zipController.text,
          'latitude': latitude,
          'longitude': longitude,
        },
        'phone_number': _phoneController.text,
        'email': _emailController.text,
        'opening_hours': _operatingHours,
        'rating': 0.0,
        'delivery_radius': _deliveryRadius,
        'estimated_delivery_time': _estimatedDeliveryTime,
        'is_active': false, // Needs approval
        'dietary_options': _selectedDietaryOptions,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      final restaurantId = response['id'] as String;

      // Create restaurant owner record
      await DatabaseService().client.from('restaurant_owners').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
        'owner_type': 'primary',
        'permissions': {
          'manage_menu': true,
          'manage_orders': true,
          'manage_staff': true,
          'view_analytics': true,
          'manage_settings': true,
        },
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Show success and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/restaurant/dashboard');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, color: Colors.green.shade700, size: 32),
          const SizedBox(height: 8),
          Text(
            'Welcome to NandyFood! 🎉',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Let\'s get your restaurant set up in just 5 easy steps',
            style: TextStyle(color: Colors.green.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
