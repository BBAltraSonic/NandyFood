import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

class AddEditMenuItemScreen extends ConsumerStatefulWidget {
  final String? itemId;
  final MenuItem? existingItem;
  final String restaurantId;

  const AddEditMenuItemScreen({
    super.key,
    this.itemId,
    this.existingItem,
    required this.restaurantId,
  });

  @override
  ConsumerState<AddEditMenuItemScreen> createState() =>
      _AddEditMenuItemScreenState();
}

class _AddEditMenuItemScreenState
    extends ConsumerState<AddEditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _stockQuantityController = TextEditingController();

  String _selectedCategory = 'Main Course';
  int _spiceLevel = 0;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isPopular = false;

  final List<String> _selectedDietaryTags = [];
  final List<String> _selectedAllergens = [];
  List<Map<String, dynamic>> _customizationOptions = [];

  File? _selectedImage;
  String? _existingImageUrl;

  final List<String> _categories = [
    'Appetizer',
    'Main Course',
    'Dessert',
    'Drinks',
    'Sides',
    'Salads',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
  ];

  final List<String> _dietaryTags = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Halal',
    'Kosher',
    'Keto',
    'Low-Carb',
    'High-Protein',
  ];

  final List<String> _allergens = [
    'Peanuts',
    'Tree Nuts',
    'Milk',
    'Eggs',
    'Fish',
    'Shellfish',
    'Soy',
    'Wheat',
    'Sesame',
  ];

  final _restaurantService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _populateExistingData();
    }
  }

  void _populateExistingData() {
    final item = widget.existingItem!;
    _nameController.text = item.name;
    _descriptionController.text = item.description ?? '';
    _priceController.text = item.price.toString();
    // TODO: Add these fields to MenuItem model
    // _originalPriceController.text = item.originalPrice?.toString() ?? '';
    _prepTimeController.text = item.preparationTime.toString();
    // _caloriesController.text = item.calories?.toString() ?? '';
    // _stockQuantityController.text = item.stockQuantity?.toString() ?? '';

    _selectedCategory = item.category;
    // _spiceLevel = item.spiceLevel ?? 0;
    _isAvailable = item.isAvailable;
    // _isFeatured = item.isFeatured ?? false;
    // _isPopular = item.isPopular ?? false;

    _selectedDietaryTags.addAll(item.dietaryRestrictions);
    // _selectedAllergens.addAll(item.allergens ?? []);
    // _customizationOptions = List<Map<String, dynamic>>.from(
    //   item.customizationOptions ?? [],
    // );

    _existingImageUrl = item.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _prepTimeController.dispose();
    _caloriesController.dispose();
    _stockQuantityController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem == null ? 'Add Menu Item' : 'Edit Menu Item'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoStep(),
                _buildPricingDetailsStep(),
                _buildDietaryInfoStep(),
                _buildCustomizationStep(),
                _buildImageStep(),
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
        children: List.generate(6, (index) {
          final isCompleted = index < _currentStep;
          final isCurrent = index == _currentStep;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
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
              'Tell us about your dish',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g., Margherita Pizza',
                prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your dish',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prepTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Prep Time (min)',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories (optional)',
                      prefixIcon: Icon(Icons.local_fire_department),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your pricing and availability',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: 'R ',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Invalid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _originalPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Original Price',
                    prefixText: 'R ',
                    prefixIcon: Icon(Icons.discount),
                    border: OutlineInputBorder(),
                    hintText: 'For discounts',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _stockQuantityController,
            decoration: const InputDecoration(
              labelText: 'Stock Quantity (optional)',
              hintText: 'Leave empty for unlimited',
              prefixIcon: Icon(Icons.inventory),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Available for Order'),
            subtitle: const Text('Customers can order this item'),
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value),
          ),
          SwitchListTile(
            title: const Text('Featured Item'),
            subtitle: const Text('Show in featured section'),
            value: _isFeatured,
            onChanged: (value) => setState(() => _isFeatured = value),
          ),
          SwitchListTile(
            title: const Text('Popular Item'),
            subtitle: const Text('Mark as customer favorite'),
            value: _isPopular,
            onChanged: (value) => setState(() => _isPopular = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help customers make informed choices',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            'Spice Level',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _spiceLevel.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: _spiceLevel == 0
                ? 'Not Spicy'
                : '🌶️' * _spiceLevel,
            onChanged: (value) {
              setState(() => _spiceLevel = value.toInt());
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Dietary Tags',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietaryTags.map((tag) {
              final isSelected = _selectedDietaryTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedDietaryTags.add(tag);
                    } else {
                      _selectedDietaryTags.remove(tag);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            'Allergens',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergens.map((allergen) {
              final isSelected = _selectedAllergens.contains(allergen);
              return FilterChip(
                label: Text(allergen),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAllergens.add(allergen);
                    } else {
                      _selectedAllergens.remove(allergen);
                    }
                  });
                },
                selectedColor: Colors.red.shade100,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomizationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customization Options',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add toppings, sizes, or other options',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          if (_customizationOptions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.tune, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No customization options yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add options like size, toppings, etc.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customizationOptions.length,
              itemBuilder: (context, index) {
                final option = _customizationOptions[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(option['name'] ?? 'Option'),
                    subtitle: Text(
                      '${option['options']?.length ?? 0} choices',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _customizationOptions.removeAt(index);
                        });
                      },
                    ),
                    onTap: () => _editCustomizationOption(index),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addCustomizationOption,
              icon: const Icon(Icons.add),
              label: const Text('Add Customization Option'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item Image',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a mouth-watering photo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : _existingImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _existingImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tap to add photo',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
              ),
            ),
          ),
          if (_selectedImage != null || _existingImageUrl != null)
            const SizedBox(height: 16),
          if (_selectedImage != null || _existingImageUrl != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _existingImageUrl = null;
                  });
                },
                icon: const Icon(Icons.delete),
                label: const Text('Remove Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
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
            'Review & Save',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check everything before saving',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewRow('Name', _nameController.text),
                  if (_descriptionController.text.isNotEmpty)
                    _buildReviewRow('Description', _descriptionController.text),
                  _buildReviewRow('Category', _selectedCategory),
                  _buildReviewRow(
                    'Price',
                    'R ${double.tryParse(_priceController.text)?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  if (_originalPriceController.text.isNotEmpty)
                    _buildReviewRow(
                      'Original Price',
                      'R ${double.tryParse(_originalPriceController.text)?.toStringAsFixed(2) ?? '0.00'}',
                    ),
                  if (_prepTimeController.text.isNotEmpty)
                    _buildReviewRow('Prep Time', '${_prepTimeController.text} min'),
                  _buildReviewRow('Available', _isAvailable ? 'Yes' : 'No'),
                  if (_selectedDietaryTags.isNotEmpty)
                    _buildReviewRow('Dietary', _selectedDietaryTags.join(', ')),
                  if (_selectedAllergens.isNotEmpty)
                    _buildReviewRow('Allergens', _selectedAllergens.join(', ')),
                  if (_customizationOptions.isNotEmpty)
                    _buildReviewRow(
                      'Customizations',
                      '${_customizationOptions.length} options',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_currentStep < 5 ? 'Next' : 'Save Item'),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _nextStep() {
    if (_currentStep < 5) {
      // Validate current step
      if (_currentStep == 0 && !_formKey.currentState!.validate()) {
        return;
      }
      if (_currentStep == 1 && !_validatePricingStep()) {
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _saveMenuItem();
    }
  }

  bool _validatePricingStep() {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price')),
      );
      return false;
    }
    if (double.tryParse(_priceController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid price format')),
      );
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _addCustomizationOption() {
    // TODO: Show dialog to add customization option
    // For now, add a simple example
    setState(() {
      _customizationOptions.add({
        'id': 'option_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'New Option',
        'required': false,
        'max_selections': 1,
        'options': [],
      });
    });
  }

  void _editCustomizationOption(int index) {
    // TODO: Show dialog to edit customization option
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customization editing coming soon')),
    );
  }

  Future<void> _saveMenuItem() async {
    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Upload image if new one selected
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!);
      }

      final itemData = {
        'restaurant_id': widget.restaurantId,
        'name': _nameController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'category': _selectedCategory,
        'price': double.parse(_priceController.text),
        'original_price': _originalPriceController.text.isEmpty
            ? null
            : double.parse(_originalPriceController.text),
        'prep_time': _prepTimeController.text.isEmpty
            ? 15
            : int.parse(_prepTimeController.text),
        'calories': _caloriesController.text.isEmpty
            ? null
            : int.parse(_caloriesController.text),
        'stock_quantity': _stockQuantityController.text.isEmpty
            ? null
            : int.parse(_stockQuantityController.text),
        'dietary_tags': _selectedDietaryTags,
        'allergens': _selectedAllergens,
        'spice_level': _spiceLevel,
        'customization_options': _customizationOptions,
        'image_url': imageUrl,
        'is_available': _isAvailable,
        'is_featured': _isFeatured,
        'is_popular': _isPopular,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (widget.existingItem == null) {
        // Create new item
        itemData['created_at'] = DateTime.now().toIso8601String();
        await _restaurantService.createMenuItem(
          MenuItem.fromJson({...itemData, 'id': ''}),
        );
      } else {
        // Update existing item
        await _restaurantService.updateMenuItem(
          widget.existingItem!.id,
          itemData,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingItem == null
                ? 'Menu item added successfully!'
                : 'Menu item updated successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _uploadImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${widget.restaurantId}/$fileName';

      await DatabaseService().client.storage
          .from('menu-item-images')
          .uploadBinary(path, bytes);

      return DatabaseService().client.storage
          .from('menu-item-images')
          .getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
