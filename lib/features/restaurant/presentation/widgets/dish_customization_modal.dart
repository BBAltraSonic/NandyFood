import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

/// Model for dish size options
class DishSize {
  final String label;
  final double priceMultiplier;

  const DishSize({required this.label, required this.priceMultiplier});
}

/// Model for toppings/add-ons
class Topping {
  final String name;
  final double price;

  const Topping({required this.name, required this.price});
}

/// Available dish sizes
const List<DishSize> dishSizes = [
  DishSize(label: 'Small', priceMultiplier: 0.8),
  DishSize(label: 'Medium', priceMultiplier: 1.0),
  DishSize(label: 'Large', priceMultiplier: 1.3),
];

/// Common toppings/add-ons
const List<Topping> commonToppings = [
  Topping(name: 'Extra Cheese', price: 1.50),
  Topping(name: 'Bacon', price: 2.00),
  Topping(name: 'Avocado', price: 2.50),
  Topping(name: 'Mushrooms', price: 1.00),
  Topping(name: 'Jalapeños', price: 0.75),
  Topping(name: 'Olives', price: 0.75),
  Topping(name: 'Extra Sauce', price: 0.50),
];

/// Show dish customization modal
Future<void> showDishCustomizationModal({
  required BuildContext context,
  required MenuItem menuItem,
  required WidgetRef ref,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DishCustomizationModal(menuItem: menuItem, ref: ref),
  );
}

/// Dish customization modal widget
class DishCustomizationModal extends StatefulWidget {
  final MenuItem menuItem;
  final WidgetRef ref;

  const DishCustomizationModal({
    Key? key,
    required this.menuItem,
    required this.ref,
  }) : super(key: key);

  @override
  State<DishCustomizationModal> createState() => _DishCustomizationModalState();
}

class _DishCustomizationModalState extends State<DishCustomizationModal> {
  // Selected customizations
  int _selectedSizeIndex = 1; // Default to Medium
  final Set<String> _selectedToppings = {};
  double _spiceLevel = 1.0; // Default spice level
  final TextEditingController _instructionsController = TextEditingController();
  int _quantity = 1;

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  /// Calculate total price with customizations
  double get _totalPrice {
    final basePrice =
        widget.menuItem.price * dishSizes[_selectedSizeIndex].priceMultiplier;
    final toppingsPrice = _selectedToppings.fold(0.0, (sum, toppingName) {
      final topping = commonToppings.firstWhere((t) => t.name == toppingName);
      return sum + topping.price;
    });
    return (basePrice + toppingsPrice) * _quantity;
  }

  /// Build customizations map
  Map<String, dynamic> get _customizations {
    return {
      'size': dishSizes[_selectedSizeIndex].label,
      'sizeMultiplier': dishSizes[_selectedSizeIndex].priceMultiplier,
      'toppings': _selectedToppings.toList(),
      'toppingsPrice': _selectedToppings.fold(0.0, (sum, toppingName) {
        final topping = commonToppings.firstWhere((t) => t.name == toppingName);
        return sum + topping.price;
      }),
      'spiceLevel': _spiceLevel.toInt(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Dish image
                    _buildDishImage(),
                    const SizedBox(height: 16),

                    // Dish name and price
                    _buildDishHeader(),
                    const SizedBox(height: 8),

                    // Dish description
                    if (widget.menuItem.description != null) ...[
                      Text(
                        widget.menuItem.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Size selector
                    _buildSizeSelector(),
                    const SizedBox(height: 24),

                    // Toppings/add-ons
                    _buildToppingsSection(),
                    const SizedBox(height: 24),

                    // Spice level
                    _buildSpiceLevelSlider(),
                    const SizedBox(height: 24),

                    // Special instructions
                    _buildSpecialInstructions(),
                    const SizedBox(height: 24),

                    // Quantity selector
                    _buildQuantitySelector(),
                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),

              // Bottom action bar
              _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  /// Build dish image
  Widget _buildDishImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: widget.menuItem.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.menuItem.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => _buildPlaceholderImage(),
            )
          : _buildPlaceholderImage(),
    );
  }

  /// Build placeholder image
  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.restaurant, size: 64, color: Colors.grey.shade400),
    );
  }

  /// Build dish header (name and price)
  Widget _buildDishHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.menuItem.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Text(
          '\$${widget.menuItem.price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
      ],
    );
  }

  /// Build size selector
  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Size',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(dishSizes.length, (index) {
            final size = dishSizes[index];
            final isSelected = index == _selectedSizeIndex;
            final price = widget.menuItem.price * size.priceMultiplier;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < dishSizes.length - 1 ? 8.0 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSizeIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepOrange
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          size.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Build toppings section
  Widget _buildToppingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Toppings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonToppings.map((topping) {
            final isSelected = _selectedToppings.contains(topping.name);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedToppings.remove(topping.name);
                  } else {
                    _selectedToppings.add(topping.name);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.deepOrange : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.deepOrange
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.white,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      '${topping.name} (+\$${topping.price.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Build spice level slider
  Widget _buildSpiceLevelSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spice Level',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSpiceLevelColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 18,
                    color: _getSpiceLevelColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getSpiceLevelLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getSpiceLevelColor(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _getSpiceLevelColor(),
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: _getSpiceLevelColor(),
            overlayColor: _getSpiceLevelColor().withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: _spiceLevel,
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) {
              setState(() {
                _spiceLevel = value;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mild',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                'Extra Hot',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get spice level color based on current level
  Color _getSpiceLevelColor() {
    if (_spiceLevel <= 1) return Colors.green;
    if (_spiceLevel <= 2) return Colors.orange;
    if (_spiceLevel <= 3) return Colors.deepOrange;
    if (_spiceLevel <= 4) return Colors.red;
    return Colors.red.shade900;
  }

  /// Get spice level label
  String _getSpiceLevelLabel() {
    if (_spiceLevel <= 1) return 'Mild';
    if (_spiceLevel <= 2) return 'Medium';
    if (_spiceLevel <= 3) return 'Spicy';
    if (_spiceLevel <= 4) return 'Hot';
    return 'Extra Hot';
  }

  /// Build special instructions text field
  Widget _buildSpecialInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Instructions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instructionsController,
          maxLines: 3,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Add any special requests (optional)...',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  /// Build quantity selector
  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Quantity:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () {
                        setState(() {
                          _quantity--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove),
                color: Colors.deepOrange,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _quantity.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _quantity < 99
                    ? () {
                        setState(() {
                          _quantity++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add),
                color: Colors.deepOrange,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build bottom action bar
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_outlined),
              const SizedBox(width: 8),
              Text(
                'Add to Cart - \$${_totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add item to cart with customizations
  Future<void> _addToCart() async {
    // Get cart notifier
    final cartNotifier = widget.ref.read(cartProvider.notifier);

    // Add item with customizations
    await cartNotifier.addItem(
      widget.menuItem,
      quantity: _quantity,
      customizations: _customizations,
      specialInstructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
    );

    // Show success message
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.menuItem.name} added to cart'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Close modal
    Navigator.of(context).pop();
  }
}
