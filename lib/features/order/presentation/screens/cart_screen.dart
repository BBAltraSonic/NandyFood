import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        actions: [
          if (cartState.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cart cleared')));
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add delicious items to your cart',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Navigate to home screen or restaurant list
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Browse Restaurants'),
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
        // Cart items list
        Expanded(
          child: ListView.builder(
            itemCount: cartState.items.length,
            itemBuilder: (context, index) {
              final item = cartState.items[index];
              return _buildCartItem(context, ref, item);
            },
          ),
        ),

        // Promo code section
        if (cartState.promoCode == null) _buildPromoCodeSection(context, ref),

        // Order summary
        _buildOrderSummary(cartState),
      ],
    );
  }

  /// Build cart item
  Widget _buildCartItem(BuildContext context, WidgetRef ref, dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                    Text(
                      _formatCustomizations(item.customizations),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  if (item.specialInstructions != null)
                    Text(
                      'Note: ${item.specialInstructions}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
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
                Text('${item.quantity}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    ref
                        .read(cartProvider.notifier)
                        .updateItemQuantity(item.id, item.quantity + 1);
                  },
                ),
              ],
            ),

            // Item total
            Text(
              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                ref.read(cartProvider.notifier).removeItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build promo code section
  Widget _buildPromoCodeSection(BuildContext context, WidgetRef ref) {
    final TextEditingController promoController = TextEditingController();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Have a promo code?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoController,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (promoController.text.isNotEmpty) {
                      ref
                          .read(cartProvider.notifier)
                          .applyPromoCode(promoController.text);
                    }
                  },
                  child: const Text('Apply'),
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
            if (cartState.promoCode != null)
              _buildSummaryRow(
                'Discount (${cartState.promoCode})',
                '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
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

  /// Format customizations for display
  String _formatCustomizations(Map<String, dynamic> customizations) {
    return customizations.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}
