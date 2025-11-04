import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/restaurant/data/dtos/menu_item_dto.dart';
import 'package:food_delivery_app/features/restaurant/data/dtos/menu_modifier_dto.dart';
import 'package:food_delivery_app/features/restaurant/data/repositories/menu_repository.dart';

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
  // Dynamic modifiers DTO/state
  MenuItemDTO? _dto;
  final Map<String, Set<String>> _selectedByGroup = {};
  bool _loadingModifiers = false;

  // Fallback (legacy) selected customizations
  int _selectedSizeIndex = 1; // Default to Medium
  final Set<String> _selectedToppings = {};
  double _spiceLevel = 1.0; // Default spice level
  final TextEditingController _instructionsController = TextEditingController();
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadModifiers();
  }

  bool get _useDynamic => _dto?.hasModifiers ?? false;

  Future<void> _loadModifiers() async {
    setState(() => _loadingModifiers = true);
    final repo = MenuRepository();
    final dto = await repo.fetchMenuItemWithModifiers(widget.menuItem.id);
    if (!mounted) return;

    if (dto != null && dto.modifierGroups.isNotEmpty) {
      for (final g in dto.modifierGroups) {
        if (!_selectedByGroup.containsKey(g.id)) {
          _selectedByGroup[g.id] = {};
        }
        if (g.type == MenuModifierType.single) {
          if (g.required && g.options.isNotEmpty) {
            _selectedByGroup[g.id] = {g.options.first.id};
          }
        }
      }
    }

    setState(() {
      _dto = dto;
      _loadingModifiers = false;
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  /// Calculate total price with customizations
  double get _totalPrice {
    if (_useDynamic && _dto != null) {
      final selections = _selectedByGroup.map((k, v) => MapEntry(k, v.toList()));
      return _dto!.computeFinalPrice(selections) * _quantity;
    }

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
    if (_useDynamic && _dto != null) {
      final selections = _selectedByGroup.map((k, v) => MapEntry(k, v.toList()));
      final unitPrice = _dto!.computeFinalPrice(selections);
      return {
        'modifierSelections': selections,
        'computedUnitPrice': unitPrice,
      };
    }

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

                    // Customization content (dynamic groups if available)
                    _buildCustomizationContent(),
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


  /// Build customization content: dynamic groups if available, else legacy UI
  Widget _buildCustomizationContent() {
    if (_loadingModifiers) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      ));
    }
    if (_useDynamic && _dto != null) {
      return _buildDynamicModifiersSection();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSizeSelector(),
        const SizedBox(height: 24),
        _buildToppingsSection(),
        const SizedBox(height: 24),
        _buildSpiceLevelSlider(),
      ],
    );
  }

  Widget _buildDynamicModifiersSection() {
    final groups = _dto?.modifierGroups ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              g.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          _buildGroupChips(g),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildGroupChips(MenuModifierGroup group) {
    final selected = _selectedByGroup[group.id] ?? {};
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in group.options)
          Padding(
            padding: const EdgeInsets.only(right: 0),
            child: group.type == MenuModifierType.single
                ? ChoiceChip(
                    selected: selected.contains(option.id),
                    label: Text(_formatOptionLabel(option)),
                    selectedColor: Colors.black87,
                    labelStyle: TextStyle(
                      color: selected.contains(option.id)
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onSelected: (isSelected) {
                      setState(() {
                        _selectedByGroup[group.id] = {option.id};
                      });
                    },
                  )
                : FilterChip(
                    selected: selected.contains(option.id),
                    label: Text(_formatOptionLabel(option)),
                    selectedColor: Colors.black87,
                    labelStyle: TextStyle(
                      color: selected.contains(option.id)
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onSelected: (isSelected) {
                      setState(() {
                        final set = _selectedByGroup[group.id] ?? {};
                        if (isSelected) {
                          set.add(option.id);
                        } else {
                          set.remove(option.id);
                        }
                        _selectedByGroup[group.id] = set;
                      });
                    },
                  ),
          ),
      ],
    );
  }

  String _formatOptionLabel(MenuModifierOption opt) {
    final hasMult = opt.multiplier != 1.0;
    final hasDelta = opt.priceDelta != 0.0;
    if (!hasMult && !hasDelta) return opt.name;

    final parts = <String>[];
    if (hasMult) parts.add('x${opt.multiplier.toStringAsFixed(opt.multiplier % 1 == 0 ? 0 : 2)}');
    if (hasDelta) {
      final sign = opt.priceDelta >= 0 ? '+' : '-';
      parts.add('$sign\$${opt.priceDelta.abs().toStringAsFixed(2)}');
    }
    return '${opt.name} (${parts.join(' ')})';
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
            color: Colors.black87,
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
                      color: isSelected ? Colors.black87 : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? Colors.black87
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
                  color: isSelected ? Colors.black87 : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.black87
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
                color: _getSpiceLevelColor().withValues(alpha: 0.1),
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
            overlayColor: _getSpiceLevelColor().withValues(alpha: 0.2),
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
    if (_spiceLevel <= 1) return Colors.black87;
    if (_spiceLevel <= 2) return Colors.black87;
    if (_spiceLevel <= 3) return Colors.black87;
    if (_spiceLevel <= 4) return Colors.black87;
    return Colors.black;
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
              borderSide: const BorderSide(color: Colors.black87, width: 2),
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
                color: Colors.black87,
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
                color: Colors.black87,
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _addToCart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
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
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // Close modal
    Navigator.of(context).pop();
  }
}
