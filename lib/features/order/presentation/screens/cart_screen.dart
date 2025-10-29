import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Your Cart',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: NeutralColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          if (cartState.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: ShadowTokens.shadowSm,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.grey.shade600,
                ),
                tooltip: 'Clear Cart',
                onPressed: () {
                  _showClearCartDialog(context, ref);
                },
              ),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty cart illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: BrandColors.primary,
            ),
          ),
          const SizedBox(height: 32),

          // Empty cart text
          Text(
            'Your cart is empty',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Add some delicious items to get started!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: NeutralColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Browse button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Browse Restaurants'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                ),
                elevation: 4,
                shadowColor: BrandColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
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
        // Enhanced delivery time banner
        _buildEnhancedDeliveryTimeBanner(),
        const SizedBox(height: 16),

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: cartState.items.length,
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              final itemName = _menuItemNames[item.menuItemId] ?? 'Menu Item';
              final itemImage = _menuItemImages[item.menuItemId];
              return _buildEnhancedCartItem(context, ref, item, itemName, itemImage);
            },
          ),
        ),

        // Promo code section
        _buildEnhancedPromoCodeSection(context, ref, cartState),

        // Order summary
        _buildEnhancedOrderSummary(cartState),
      ],
    );
  }

  /// Build enhanced delivery time banner
  Widget _buildEnhancedDeliveryTimeBanner() {
    final estimatedTime = _calculateEstimatedDeliveryTime();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrandColors.secondary, BrandColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        boxShadow: [
          BoxShadow(
            color: BrandColors.secondary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated Delivery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$estimatedTime - ${estimatedTime + 10} minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'FAST',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build enhanced cart item
  Widget _buildEnhancedCartItem(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
    String itemName,
    String? itemImage,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Food image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                gradient: LinearGradient(
                  colors: [BrandColors.primary.withValues(alpha: 0.3), BrandColors.primaryLight.withValues(alpha: 0.2)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                child: itemImage != null
                    ? CachedNetworkImage(
                        imageUrl: itemImage!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [BrandColors.primary.withValues(alpha: 0.3), BrandColors.primaryLight.withValues(alpha: 0.2)],
                            ),
                          ),
                          child: const Icon(
                            Icons.local_dining_rounded,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [BrandColors.primary.withValues(alpha: 0.3), BrandColors.primaryLight.withValues(alpha: 0.2)],
                            ),
                          ),
                          child: const Icon(
                            Icons.local_dining_rounded,
                            color: Colors.white54,
                            size: 32,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.local_dining_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 32,
                      ),
              ),
            ),

            const SizedBox(width: 16),

            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.customizations != null && item.customizations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: BrandColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Customized',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: BrandColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Quantity and price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                Text(
                  '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: BrandColors.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Quantity controls
                Container(
                  decoration: BoxDecoration(
                    color: NeutralColors.gray100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrease button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                          ),
                          onTap: () {
                            ref.read(cartProvider.notifier).updateItemQuantity(
                              item.id,
                              item.quantity - 1,
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.quantity > 1
                                  ? BrandColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.remove_rounded,
                              color: item.quantity > 1
                                  ? BrandColors.primary
                                  : Colors.grey.shade400,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      // Quantity display
                      Container(
                        width: 40,
                        height: 32,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Increase button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(20),
                          ),
                          onTap: () {
                            ref.read(cartProvider.notifier).updateItemQuantity(
                              item.id,
                              item.quantity + 1,
                            );
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: BrandColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: BrandColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build enhanced promo code section
  Widget _buildEnhancedPromoCodeSection(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BrandColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: BrandColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Promo Code',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    hintText: 'Enter promo code',
                    hintStyle: TextStyle(
                      color: NeutralColors.textSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.tag_rounded,
                      color: BrandColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                      borderSide: BorderSide(color: NeutralColors.gray300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                      borderSide: BorderSide(color: NeutralColors.gray300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                      borderSide: BorderSide(color: BrandColors.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_promoController.text.isNotEmpty) {
                    ref.read(cartProvider.notifier).applyPromoCode(_promoController.text);
                    _promoController.clear();
                    FocusScope.of(context).unfocus();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('Apply'),
              ),
            ],
          ),

          // Applied promo code display
          if (cartState.promoCode?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrandColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: BrandColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Promo code "${cartState.promoCode}" applied',
                      style: TextStyle(
                        color: BrandColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      ref.read(cartProvider.notifier).removePromoCode();
                    },
                    color: BrandColors.accent,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build enhanced order summary
  Widget _buildEnhancedOrderSummary(CartState cartState) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: BrandColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Order Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Summary rows
          _buildSummaryRow('Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),

          _buildSummaryRow('Delivery Fee', '\$${cartState.deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 12),

          if (cartState.tipAmount > 0) ...[
            _buildSummaryRow('Tip', '\$${cartState.tipAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
          ],

          if (cartState.discountAmount > 0) ...[
            _buildSummaryRow(
              'Discount',
              '-\$${cartState.discountAmount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
            const SizedBox(height: 12),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${cartState.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: BrandColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isDiscount = false}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: NeutralColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDiscount ? BrandColors.accent : NeutralColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build enhanced checkout bar
  Widget _buildCheckoutBar(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BorderRadiusTokens.xxl),
        ),
        boxShadow: ShadowTokens.shadowLg,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                    Text(
                      '\$${cartState.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/order/checkout');
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Proceed to Checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                      ),
                      elevation: 4,
                      shadowColor: BrandColors.primary.withValues(alpha: 0.3),
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

  void _showClearCartDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}