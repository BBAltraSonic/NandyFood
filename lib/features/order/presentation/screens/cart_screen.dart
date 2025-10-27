import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _promoController = TextEditingController();
  final Map<String, String> _menuItemNames = {};
  final Map<String, String?> _menuItemImages = {};

  @override
  void initState() {
    super.initState();
    _loadMenuItemDetails();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  /// Load menu item details (name and image) for all cart items
  Future<void> _loadMenuItemDetails() async {
    final cartState = ref.read(cartProvider);
    final dbService = DatabaseService();

    for (final item in cartState.items) {
      try {
        final menuItem = await dbService.getMenuItemById(item.menuItemId);
        if (menuItem != null && mounted) {
          setState(() {
            _menuItemNames[item.menuItemId] = menuItem['name'] as String;
            _menuItemImages[item.menuItemId] = menuItem['image_url'] as String?;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  /// Calculate estimated delivery time based on cart items
  int _calculateEstimatedDeliveryTime() {
    final cartState = ref.read(cartProvider);
    // Base delivery time: 15 minutes
    // Add 5 minutes per item type
    final baseTime = 15;
    final itemTime = cartState.items.length * 2;
    // Add 10 minutes travel time
    return baseTime + itemTime + 10;
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cartState.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Cart',
              onPressed: () {
                _showClearCartDialog(context, ref);
              },
            ),
        ],
      ),
      body: cartState.items.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartContent(context, ref, cartState),
      bottomNavigationBar: cartState.items.isNotEmpty
          ? _buildCheckoutBar(context, cartState)
          : null,
    );
  }

  /// Build empty cart view
  Widget _buildEmptyCart(BuildContext context) {
    return EmptyStateWidget.emptyCart(
      onBrowse: () {
        Navigator.pop(context);
      },
    );
  }

  /// Build cart content
  Widget _buildCartContent(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return Column(
      children: [
        // Estimated delivery time banner
        _buildDeliveryTimeBanner(),
        const SizedBox(height: 8),
        
        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cartState.items.length,
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              final itemName = _menuItemNames[item.menuItemId] ?? 'Menu Item';
              final itemImage = _menuItemImages[item.menuItemId];
              return _buildCartItem(context, ref, item, itemName, itemImage);
            },
          ),
        ),

        // Promo code section
        _buildPromoCodeSection(context, ref, cartState),

        // Order summary
        _buildOrderSummary(cartState),
      ],
    );
  }

  /// Build delivery time banner
  Widget _buildDeliveryTimeBanner() {
    final estimatedTime = _calculateEstimatedDeliveryTime();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$estimatedTime - ${estimatedTime + 10} minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build cart item
  Widget _buildCartItem(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    String itemName,
    String? itemImage,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item thumbnail
            if (itemImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: itemImage,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant, color: Colors.grey, size: 40),
              ),
            const SizedBox(width: 12),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${item.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (item.customizations != null &&
                      item.customizations.isNotEmpty)
                    _buildCustomizationsDisplay(item.customizations),
                  if (item.specialInstructions != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.note, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.specialInstructions!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Quantity controls and total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Item total
                Text(
                  '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                const SizedBox(height: 8),
                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          if (item.quantity > 1) {
                            ref
                                .read(cartProvider.notifier)
                                .updateItemQuantity(item.id, item.quantity - 1);
                          } else {
                            ref.read(cartProvider.notifier).removeItem(item.id);
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          ref
                              .read(cartProvider.notifier)
                              .updateItemQuantity(item.id, item.quantity + 1);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Remove button
                InkWell(
                  onTap: () {
                    ref.read(cartProvider.notifier).removeItem(item.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build promo code section
  Widget _buildPromoCodeSection(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    // Listen to cart state changes for promo code feedback
    ref.listen<CartState>(cartProvider, (previous, current) {
      if (previous?.promoCode != current.promoCode &&
          current.promoCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Promo code applied!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'You saved \$${current.discountAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      if (current.errorMessage != null &&
          current.errorMessage!.isNotEmpty &&
          previous?.errorMessage != current.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(current.errorMessage!),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    if (cartState.promoCode != null) {
      // Show applied promo code
      return Card(
        margin: const EdgeInsets.all(16),
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Promo Code Applied',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      cartState.promoCode!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.green),
                onPressed: () {
                  ref.read(cartProvider.notifier).applyPromoCode('');
                  _promoController.clear();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Show promo code input
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 8),
                const Text(
                  'Have a promo code?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.confirmation_number),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: cartState.isLoading
                      ? null
                      : () {
                          if (_promoController.text.isNotEmpty) {
                            ref
                                .read(cartProvider.notifier)
                                .applyPromoCode(_promoController.text);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: cartState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build order summary
  Widget _buildOrderSummary(CartState cartState) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Subtotal',
              '\$${cartState.subtotal.toStringAsFixed(2)}',
            ),
            _buildSummaryRow(
              'Tax',
              '\$${cartState.taxAmount.toStringAsFixed(2)}',
            ),
            _buildSummaryRow(
              'Delivery Fee',
              '\$${cartState.deliveryFee.toStringAsFixed(2)}',
            ),
            if (cartState.promoCode != null) ...[
              _buildSummaryRow(
                'Discount (${cartState.promoCode})',
                '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
              // Highlight savings
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.savings, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'You saved',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '\$${cartState.discountAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(),
            _buildSummaryRow(
              'Total',
              '\$${cartState.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Build summary row
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Build checkout bar
  Widget _buildCheckoutBar(BuildContext context, CartState cartState) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '\$${cartState.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to checkout screen
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );
  }

  /// Build enhanced customizations display
  Widget _buildCustomizationsDisplay(Map<String, dynamic> customizations) {
    return Container(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Size selection
          if (customizations.containsKey('size'))
            _buildCustomizationChip(
              icon: Icons.format_size,
              label: 'Size: ${customizations['size']}',
              color: Colors.blue,
            ),
          // Toppings
          if (customizations.containsKey('toppings') &&
              customizations['toppings'] is List)
            ..._buildToppingsChips(customizations['toppings'] as List),
          // Spice level
          if (customizations.containsKey('spiceLevel'))
            _buildCustomizationChip(
              icon: Icons.local_fire_department,
              label: _getSpiceLevelDisplay(customizations['spiceLevel']),
              color: _getSpiceLevelDisplayColor(customizations['spiceLevel']),
            ),
        ],
      ),
    );
  }

  /// Build individual customization chip
  Widget _buildCustomizationChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build toppings chips
  List<Widget> _buildToppingsChips(List toppings) {
    if (toppings.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: toppings.map((topping) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, size: 12, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    topping.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ];
  }

  /// Get spice level display text
  String _getSpiceLevelDisplay(dynamic level) {
    final spiceLevel = level is int ? level : (level as double).toInt();
    switch (spiceLevel) {
      case 1:
        return 'Mild';
      case 2:
        return 'Medium';
      case 3:
        return 'Spicy';
      case 4:
        return 'Hot';
      case 5:
        return 'Extra Hot';
      default:
        return 'Spice: $spiceLevel';
    }
  }

  /// Get spice level display color
  Color _getSpiceLevelDisplayColor(dynamic level) {
    final spiceLevel = level is int ? level : (level as double).toInt();
    if (spiceLevel <= 1) return Colors.green;
    if (spiceLevel <= 2) return Colors.orange;
    if (spiceLevel <= 3) return Colors.deepOrange;
    if (spiceLevel <= 4) return Colors.red;
    return Colors.red.shade900;
  }

  /// Format customizations for display (fallback)
  String _formatCustomizations(Map<String, dynamic> customizations) {
    final parts = <String>[];
    
    if (customizations.containsKey('size')) {
      parts.add('Size: ${customizations['size']}');
    }
    if (customizations.containsKey('toppings') &&
        customizations['toppings'] is List) {
      final toppings = customizations['toppings'] as List;
      if (toppings.isNotEmpty) {
        parts.add('+ ${toppings.join(', ')}');
      }
    }
    if (customizations.containsKey('spiceLevel')) {
      parts.add('Spice: ${customizations['spiceLevel']}');
    }

    return parts.isEmpty
        ? customizations.entries.map((e) => '${e.key}: ${e.value}').join(', ')
        : parts.join(' • ');
  }

  /// Show clear cart confirmation dialog
  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content:
            const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Cart cleared'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
