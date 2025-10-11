import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/address_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/delivery_method_selector.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/address_selector.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/payment_method_selector_cash.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final orderNotifier = ref.read(orderProvider.notifier);
    final addressNotifier = ref.read(addressProvider.notifier);

    // Load addresses when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get user ID from auth - for now using placeholder
      addressNotifier.loadAddresses('user_123');
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Order summary section
            Expanded(
              child: ListView(
                children: [
                  // Delivery Method Selector
                  const DeliveryMethodSelector(),
                  const SizedBox(height: 24),

                  // Address Selector (only for delivery)
                  const AddressSelector(),
                  const SizedBox(height: 24),

                  // Order Summary
                  const Text(
                    'Order Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Cart items
                  ...cartState.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.quantity}x ${item.menuItemId}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Subtotal
                  _buildSummaryRow(
                    'Subtotal',
                    '\$${cartState.subtotal.toStringAsFixed(2)}',
                  ),

                  // Tax
                  _buildSummaryRow(
                    'Tax',
                    '\$${cartState.taxAmount.toStringAsFixed(2)}',
                  ),

                  // Delivery fee (only for delivery)
                  if (cartState.deliveryMethod == DeliveryMethod.delivery)
                    _buildSummaryRow(
                      'Delivery Fee',
                      '\$${cartState.deliveryFee.toStringAsFixed(2)}',
                    ),

                  // Tip
                  if (cartState.tipAmount > 0)
                    _buildSummaryRow(
                      'Tip',
                      '\$${cartState.tipAmount.toStringAsFixed(2)}',
                    ),

                  // Discount
                  if (cartState.discountAmount > 0)
                    _buildSummaryRow(
                      'Discount',
                      '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                    ),

                  const Divider(height: 32),

                  // Total
                  _buildSummaryRow(
                    'Total',
                    '\$${cartState.totalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),

                  const SizedBox(height: 32),

                  // Payment method selector (Cash only)
                  const PaymentMethodSelectorCash(),
                ],
              ),
            ),

            // Place order button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canPlaceOrder(cartState)
                    ? () => _placeOrder(context, ref)
                    : null,
                child: cartState.isLoading
                    ? const LoadingIndicator()
                    : Text(_getPlaceOrderButtonText(cartState)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: isTotal
                ? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                : null,
          ),
        ],
      ),
    );
  }

  bool _canPlaceOrder(CartState cartState) {
    if (cartState.isLoading || cartState.items.isEmpty) return false;
    
    // For delivery, must have selected address
    if (cartState.deliveryMethod == DeliveryMethod.delivery &&
        cartState.selectedAddress == null) {
      return false;
    }
    
    return true;
  }

  String _getPlaceOrderButtonText(CartState cartState) {
    if (cartState.items.isEmpty) return 'Cart is Empty';
    if (cartState.deliveryMethod == DeliveryMethod.delivery &&
        cartState.selectedAddress == null) {
      return 'Select Delivery Address';
    }
    return 'Place Order (Cash on ${cartState.deliveryMethod == DeliveryMethod.delivery ? 'Delivery' : 'Pickup'})';
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final cartState = ref.watch(cartProvider);
    final placeOrderNotifier = ref.read(placeOrderProvider.notifier);
    final paymentService = PaymentService();

    // Show loading indicator
    final snackBar = SnackBar(
      content: Row(
        children: const [
          LoadingIndicator(),
          SizedBox(width: 16),
          Text('Processing your order...'),
        ],
      ),
      duration: const Duration(seconds: 30),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    try {
      // Place the order using the place order provider
      await placeOrderNotifier.placeOrder(
        userId: 'user_123', // This would come from auth provider in a real app
        restaurantId:
            'restaurant_456', // This would come from the selected restaurant
        deliveryAddress: {
          'street': '123 Main Street',
          'city': 'New York',
          'zipCode': '1001',
        },
        paymentMethod:
            'card', // This would come from the selected payment method
        tipAmount: cartState.tipAmount,
        promoCode: cartState.promoCode,
        specialInstructions:
            'Please ring the doorbell', // This would come from user input
      );

      // Show success message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to order tracking
      final placedOrder = ref.read(placeOrderProvider).placedOrder;
      if (placedOrder != null) {
        Navigator.of(context).pushNamed('/order/track', arguments: placedOrder);
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
