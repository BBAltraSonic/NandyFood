import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/payment_method_selector_widget.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final orderNotifier = ref.read(orderProvider.notifier);
    final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);

    // Load payment methods when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paymentMethodsNotifier.loadPaymentMethods();
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

                  // Delivery fee
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

                  // Delivery address
                  const Text(
                    'Delivery Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '123 Main Street, New York, NY 10001',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment method selector
                  PaymentMethodSelectorWidget(
                    onPaymentMethodSelected: (paymentMethodId) {
                      // Handle payment method selection
                    },
                  ),
                ],
              ),
            ),

            // Place order button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    cartState.isLoading ||
                        cartState.selectedPaymentMethodId == null
                    ? null
                    : () => _placeOrder(context, ref),
                child: cartState.isLoading
                    ? const LoadingIndicator()
                    : const Text('Place Order'),
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
