import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as storage;

class RestaurantInfoScreen extends ConsumerStatefulWidget {
  const RestaurantInfoScreen({super.key});

  @override
  ConsumerState<RestaurantInfoScreen> createState() =>
      _RestaurantInfoScreenState();
}

class _RestaurantInfoScreenState extends ConsumerState<RestaurantInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  String? _restaurantId;
  Restaurant? _restaurant;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedCuisineType = 'Italian';
  List<String> _selectedDietaryOptions = [];
  List<String> _selectedFeatures = [];

  File? _selectedLogo;
  File? _selectedCoverImage;
  String? _existingLogoUrl;
  String? _existingCoverImageUrl;

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
    'Korean',
    'Vietnamese',
    'Greek',
    'French',
    'Spanish',
    'African',
    'Middle Eastern',
  ];

  final List<String> _dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Halal',
    'Kosher',
    'Nut-Free',
  ];

  final List<String> _features = [
    'Outdoor Seating',
    'WiFi',
    'Parking',
    'Wheelchair Accessible',
    'Pet Friendly',
    'Live Music',
    'Takeaway',
    'Reservations',
    'Catering',
  ];

  final _restaurantService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);
      if (restaurants.isEmpty) return;

      _restaurantId = restaurants.first;
      _restaurant = await _restaurantService.getRestaurant(_restaurantId!);

      _populateForm();
      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Failed to load restaurant: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateForm() {
    if (_restaurant == null) return;

    _nameController.text = _restaurant!.name;
    _descriptionController.text = _restaurant!.description ?? '';
    _phoneController.text = _restaurant!.phoneNumber ?? '';
    _emailController.text = _restaurant!.email ?? '';
    _websiteController.text = _restaurant!.websiteUrl ?? '';
    _addressLine1Controller.text = _restaurant!.addressLine1 ?? '';
    _addressLine2Controller.text = _restaurant!.addressLine2 ?? '';
    _cityController.text = _restaurant!.city ?? '';
    _stateController.text = _restaurant!.state ?? '';
    _postalCodeController.text = _restaurant!.postalCode ?? '';

    _selectedCuisineType = _restaurant!.cuisineType;
    _selectedDietaryOptions = List<String>.from(_restaurant!.dietaryOptions ?? []);
    _selectedFeatures = List<String>.from(_restaurant!.features ?? []);

    _existingLogoUrl = _restaurant!.logoUrl;
    _existingCoverImageUrl = _restaurant!.coverImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Information'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMediaSection(),
            const SizedBox(height: 24),
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildContactSection(),
            const SizedBox(height: 24),
            _buildAddressSection(),
            const SizedBox(height: 24),
            _buildCuisineSection(),
            const SizedBox(height: 24),
            _buildDietaryOptionsSection(),
            const SizedBox(height: 24),
            _buildFeaturesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Images',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Logo
            Text(
              'Logo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage(isLogo: true),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedLogo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedLogo!, fit: BoxFit.cover),
                      )
                    : _existingLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _existingLogoUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text('Add Logo',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
              ),
            ),
            if (_selectedLogo != null || _existingLogoUrl != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedLogo = null;
                    _existingLogoUrl = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove Logo', style: TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            // Cover Image
            Text(
              'Cover Image',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage(isLogo: false),
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedCoverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedCoverImage!, fit: BoxFit.cover),
                      )
                    : _existingCoverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _existingCoverImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text('Add Cover Image',
                                  style: TextStyle(color: Colors.grey.shade600)),
                            ],
                          ),
              ),
            ),
            if (_selectedCoverImage != null || _existingCoverImageUrl != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCoverImage = null;
                    _existingCoverImageUrl = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove Cover', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name *',
                prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(),
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
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                hintText: 'Tell customers about your restaurant',
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                prefixIcon: Icon(Icons.language),
                border: OutlineInputBorder(),
                hintText: 'https://yourrestaurant.com',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: const InputDecoration(
                labelText: 'Street Address *',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter street address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: const InputDecoration(
                labelText: 'Apartment, suite, etc. (optional)',
                prefixIcon: Icon(Icons.apartment),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
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
                      labelText: 'Province *',
                      border: OutlineInputBorder(),
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
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Postal Code *',
                prefixIcon: Icon(Icons.mail),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter postal code';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cuisine Type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCuisineType,
              decoration: const InputDecoration(
                labelText: 'Primary Cuisine',
                prefixIcon: Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(),
              ),
              items: _cuisineTypes.map((cuisine) {
                return DropdownMenuItem(value: cuisine, child: Text(cuisine));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCuisineType = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dietary Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restaurant Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select amenities and features',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _features.map((feature) {
                final isSelected = _selectedFeatures.contains(feature);
                return FilterChip(
                  label: Text(feature),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFeatures.add(feature);
                      } else {
                        _selectedFeatures.remove(feature);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool isLogo}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: isLogo ? 512 : 1920,
      maxHeight: isLogo ? 512 : 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        if (isLogo) {
          _selectedLogo = File(image.path);
        } else {
          _selectedCoverImage = File(image.path);
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? logoUrl = _existingLogoUrl;
      String? coverImageUrl = _existingCoverImageUrl;

      // Upload new images if selected
      if (_selectedLogo != null) {
        logoUrl = await _uploadImage(_selectedLogo!, 'logo');
      }
      if (_selectedCoverImage != null) {
        coverImageUrl = await _uploadImage(_selectedCoverImage!, 'cover');
      }

      final updates = {
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'phone_number': _phoneController.text.isEmpty ? null : _phoneController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,
        'website_url':
            _websiteController.text.isEmpty ? null : _websiteController.text,
        'address_line1': _addressLine1Controller.text,
        'address_line2': _addressLine2Controller.text.isEmpty
            ? null
            : _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'postal_code': _postalCodeController.text,
        'cuisine_type': _selectedCuisineType,
        'dietary_options': _selectedDietaryOptions,
        'features': _selectedFeatures,
        'logo_url': logoUrl,
        'cover_image_url': coverImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _restaurantService.updateRestaurant(_restaurantId!, updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant information updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      _showError('Failed to save changes: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<String> _uploadImage(File image, String type) async {
    try {
      final bytes = await image.readAsBytes();
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$_restaurantId/$fileName';

      await DatabaseService()
          .client
          .storage
          .from('restaurant-images')
          .uploadBinary(path, bytes, fileOptions: const storage.FileOptions(upsert: true));

      return DatabaseService()
          .client
          .storage
          .from('restaurant-images')
          .getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
