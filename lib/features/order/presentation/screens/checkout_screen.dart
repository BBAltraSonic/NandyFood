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
import 'package:food_delivery_app/features/order/presentation/screens/payment_method_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/payfast_payment_screen.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_method_provider.dart'
    as payment_method;
import 'package:food_delivery_app/core/services/auth_service.dart';
import 'package:food_delivery_app/core/utils/error_handler.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/tip_selector.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_confirmation_screen.dart';
import 'package:food_delivery_app/features/order/presentation/providers/promotion_provider.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/coupon_input_widget.dart';
import 'package:food_delivery_app/features/order/presentation/screens/promotions_screen.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final promotionState = ref.watch(promotionProvider);
    final authState = ref.watch(authStateProvider);
    final orderNotifier = ref.read(orderProvider.notifier);
    final addressNotifier = ref.read(addressProvider.notifier);
    
    // Calculate discount
    final discount = promotionState.appliedPromotion != null
        ? promotionState.appliedPromotion!.calculateDiscount(cartState.totalAmount)
        : 0.0;
    final finalAmount = cartState.totalAmount - discount;

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

                  // Discount from cart
                  if (cartState.discountAmount > 0)
                    _buildSummaryRow(
                      'Discount',
                      '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                    ),
                    
                  // Promotion discount
                  if (discount > 0)
                    _buildSummaryRow(
                      'Promotion (${promotionState.appliedPromotion!.code})',
                      '-R${discount.toStringAsFixed(2)}',
                      color: Colors.green,
                    ),

                  const Divider(height: 32),

                  // Total
                  _buildSummaryRow(
                    'Total',
                    'R${finalAmount.toStringAsFixed(2)}',
                    isTotal: true,
                  ),

                  const SizedBox(height: 32),
                  
                  // Coupon input
                  CouponInputWidget(
                    appliedCode: promotionState.appliedPromotion?.code,
                    isLoading: promotionState.isLoading,
                    onApply: (code) async {
                      if (authState.user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login to apply coupons')),
                        );
                        return;
                      }
                      
                      await ref.read(promotionProvider.notifier).applyPromotionCode(
                        code,
                        userId: authState.user!.id,
                        orderAmount: cartState.totalAmount,
                        restaurantId: cartState.restaurantId,
                      );
                      
                      if (promotionState.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(promotionState.errorMessage!)),
                        );
                      } else if (promotionState.successMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(promotionState.successMessage!),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    onRemove: () {
                      ref.read(promotionProvider.notifier).removePromotion();
                    },
                  ),
                  
                  // Browse promotions button
                  TextButton.icon(
                    onPressed: () async {
                      final promotion = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PromotionsScreen(
                            restaurantId: cartState.restaurantId,
                            orderAmount: cartState.totalAmount,
                          ),
                        ),
                      );
                      
                      if (promotion != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Promotion applied successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.local_offer),
                    label: const Text('Browse Available Promotions'),
                  ),

                  const SizedBox(height: 16),

                  // Tip Selector
                  TipSelector(
                    subtotal: cartState.subtotal,
                    currentTip: cartState.tipAmount,
                    onTipChanged: (tip) {
                      ref.read(cartProvider.notifier).setTipAmount(tip);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Payment method selector
                  _buildPaymentMethodSelector(context, ref, cartState),
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

  Widget _buildPaymentMethodSelector(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    final theme = Theme.of(context);
    String paymentMethodDisplay = 'Cash on Delivery';
    IconData paymentIcon = Icons.money;

    if (cartState.paymentMethod == 'payfast') {
      paymentMethodDisplay = 'Card Payment (PayFast)';
      paymentIcon = Icons.credit_card;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(paymentIcon, color: theme.colorScheme.primary),
            title: Text(paymentMethodDisplay),
            subtitle: Text(
              cartState.paymentMethod == 'cash'
                  ? 'Pay with cash when order arrives'
                  : 'Pay securely with your card',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selectedMethod =
                  await Navigator.push<payment_method.PaymentMethodType>(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentMethodScreen(
                    orderId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
                    amount: cartState.totalAmount,
                  ),
                ),
              );

              if (selectedMethod != null) {
                final methodStr =
                    selectedMethod == payment_method.PaymentMethodType.cash
                        ? 'cash'
                        : 'payfast';
                ref.read(cartProvider.notifier).setPaymentMethod(methodStr);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color)),
          Text(
            value,
            style: isTotal
                ? TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)
                : TextStyle(color: color),
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
    final paymentMethod = cartState.paymentMethod;

    try {
      if (paymentMethod == 'cash') {
        // CASH FLOW: Place order directly
        await _placeCashOrder(context, ref);
      } else if (paymentMethod == 'payfast') {
        // PAYFAST FLOW: Initialize payment first
        await _initializePayFastPayment(context, ref);
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeCashOrder(BuildContext context, WidgetRef ref) async {
    final cartState = ref.watch(cartProvider);
    final placeOrderNotifier = ref.read(placeOrderProvider.notifier);

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            LoadingIndicator(),
            SizedBox(width: 16),
            Text('Processing your order...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Place the order using the place order provider
      await placeOrderNotifier.placeOrder(
        userId: 'user_123', // Get from AuthService
        restaurantId: cartState.restaurantId ?? 'restaurant_456',
        deliveryAddress: cartState.selectedAddress?.toJson() ?? {
          'street': '123 Main Street',
          'city': 'City',
          'zipCode': '1001',
        },
        paymentMethod: 'cash',
        tipAmount: cartState.tipAmount,
        promoCode: cartState.promoCode,
        specialInstructions: cartState.deliveryNotes ?? '',
      );

      // Hide loading snackbar
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Navigate to order confirmation screen
        final placedOrder = ref.read(placeOrderProvider).placedOrder;
        if (placedOrder != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  OrderConfirmationScreen(order: placedOrder),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      rethrow;
    }
  }

  Future<void> _initializePayFastPayment(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final cartState = ref.watch(cartProvider);

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            LoadingIndicator(),
            SizedBox(width: 16),
            Text('Initializing secure payment...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final paymentNotifier = ref.read(paymentProvider.notifier);

      // Generate temporary order ID
      final tempOrderId = 'temp-${DateTime.now().millisecondsSinceEpoch}';

      // Initialize PayFast payment
      final paymentData = await paymentNotifier.initializePayment(
        orderId: tempOrderId,
        userId: 'user_123', // Get from AuthService
        amount: cartState.totalAmount,
        itemName: 'Food Order from ${cartState.restaurantId ?? "Restaurant"}',
        itemDescription:
            '${cartState.items.length} items - Order #$tempOrderId',
        customerEmail: 'user@example.com', // Get from user profile
        customerFirstName: 'Customer',
        customerLastName: 'User',
        customerPhone: '',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Navigate to PayFast payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PayFastPaymentScreen(
              paymentData: paymentData,
              orderId: tempOrderId,
              amount: cartState.totalAmount,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      rethrow;
    }
  }
}
