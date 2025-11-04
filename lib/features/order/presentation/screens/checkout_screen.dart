import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/services/payment_service.dart' as payment_service;
import 'package:food_delivery_app/core/services/payfast_service.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/payment_method_selector_widget.dart';
import 'package:food_delivery_app/core/config/business_config.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_config_provider.dart';
import 'package:food_delivery_app/features/order/presentation/screens/payfast_payment_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'cash'; // Default payment method

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final cartState = ref.watch(cartProvider);
    final orderNotifier = ref.read(orderProvider.notifier);
    final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);
    final authState = ref.watch(authStateProvider);

    // Load payment methods when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState.user != null) {
        paymentMethodsNotifier.loadPaymentMethods(authState.user!.id);
      }
    });

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: NeutralColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: cartState.isLoading
          ? const LoadingIndicator()
          : _buildCheckoutContent(context, ref, cartState),
      bottomNavigationBar: _buildPlaceOrderBar(context, ref, cartState),
    );
  }

  Widget _buildCheckoutContent(
    BuildContext context,
    WidgetRef ref,
    CartState cartState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Order Summary Section
          _buildOrderSummarySection(context, cartState),
          const SizedBox(height: 32),

          // Delivery Address Section
          _buildDeliveryAddressSection(context),
          const SizedBox(height: 32),

          // Payment Method Section
          _buildPaymentMethodSection(context, ref),
          const SizedBox(height: 32),

          // Order Instructions Section
          _buildOrderInstructionsSection(context),
          const SizedBox(height: 32),

          // Security & Privacy Section
          _buildSecuritySection(context),
          const SizedBox(height: 100), // Extra padding for bottom navigation
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);

    return Container(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: BrandColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Order Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cart items preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeutralColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: cartState.items.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: BrandColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${item.quantity}x Item #${item.menuItemId}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ).toList(),
            ),
          ),

          if (cartState.items.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                '+${cartState.items.length - 3} more items',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: NeutralColors.textSecondary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Pricing breakdown
          _buildPricingBreakdown(context, cartState),
        ],
      ),
    );
  }

  Widget _buildPricingBreakdown(BuildContext context, CartState cartState) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildSummaryRow(context, 'Subtotal', '\$${cartState.subtotal.toStringAsFixed(2)}'),
        const SizedBox(height: 12),

        _buildSummaryRow(context, 'Delivery Fee', '\$${cartState.deliveryFee.toStringAsFixed(2)}'),
        const SizedBox(height: 12),

        _buildSummaryRow(context, 'Service Fee', '\$${(cartState.totalAmount * 0.05).toStringAsFixed(2)}'),
        const SizedBox(height: 12),

        if (cartState.tipAmount > 0)
          _buildSummaryRow(context, 'Tip', '\$${cartState.tipAmount.toStringAsFixed(2)}'),
        const SizedBox(height: 12),

        if (cartState.discountAmount > 0) ...[
          _buildSummaryRow(
            context,
            'Discount',
            '-\$${cartState.discountAmount.toStringAsFixed(2)}',
            isDiscount: true,
          ),
          const SizedBox(height: 12),
        ],

        const Divider(),
        const SizedBox(height: 12),

        // Total row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '\$${cartState.totalAmount.toStringAsFixed(2)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: BrandColors.primary,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: BrandColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Delivery Address',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigate to address selection
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Change'),
                style: TextButton.styleFrom(
                  foregroundColor: BrandColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Address details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NeutralColors.gray100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeutralColors.gray300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.home_rounded,
                      color: BrandColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Home',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '123 Main Street, Apt 4B',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'New York, NY 10001',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: NeutralColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      color: BrandColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(555) 123-4567',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final paymentMethodsState = ref.watch(paymentMethodsProvider);

    return Container(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.payment_rounded,
                  color: BrandColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Payment Method',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  // Navigate to add payment method
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add New'),
                style: TextButton.styleFrom(
                  foregroundColor: BrandColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment methods list
          _buildPaymentMethodsList(context),

          const SizedBox(height: 16),

          // Security badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSecurityBadge(context, 'SSL Secured', Icons.lock_rounded),
              const SizedBox(width: 16),
              _buildSecurityBadge(context, 'PCI Compliant', Icons.verified_rounded),
              const SizedBox(width: 16),
              _buildSecurityBadge(context, '256-bit Encryption', Icons.enhanced_encryption_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NeutralColors.gray100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeutralColors.gray300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: BrandColors.secondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: NeutralColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          title: const Text('Cash on Pickup'),
          leading: Radio<String>(
            value: 'cash',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
        ),
        ListTile(
          title: const Text('PayFast'),
          leading: Radio<String>(
            value: 'payfast',
            groupValue: _paymentMethod,
            onChanged: (value) {
              setState(() {
                _paymentMethod = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInstructionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.note_alt_rounded,
                  color: BrandColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Special Instructions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Optional',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: NeutralColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Instructions input
          TextField(
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add any special instructions for your order...',
              hintStyle: TextStyle(
                color: NeutralColors.textSecondary,
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
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrandColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        border: Border.all(color: BrandColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.security_rounded,
                  color: BrandColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your payment information is secure and encrypted. We never store your payment details.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: BrandColors.primary.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderBar(BuildContext context, WidgetRef ref, CartState cartState) {
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
                      'Total Amount',
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
                    onPressed: () => _placeOrder(context, ref, cartState),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Place Order'),
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

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isDiscount = false}) {
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

  Future<void> _placeOrder(BuildContext context, WidgetRef ref, CartState cartState) async {
    // Validate minimum order amount
    if (cartState.totalAmount < BusinessConfig.minOrderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minimum order amount is \$${BusinessConfig.minOrderAmount.toStringAsFixed(2)}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if user is authenticated
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || authState.user == null) {
      context.push('/auth/login');
      return;
    }

    // Validate payment method is selected
    if (_paymentMethod.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate restaurant is selected
    if (cartState.restaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurant information missing'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Generate order ID
      final orderId = const Uuid().v4();

      // Handle payment based on selected method
      final paymentMethod = _paymentMethod;

      if (paymentMethod == 'payfast') {
        // Navigate to PayFast payment screen
        final paymentService = PayFastService();
        final paymentData = await paymentService.initializePayment(
          orderId: orderId,
          userId: authState.user!.id,
          amount: cartState.totalAmount,
          itemName: 'NandyFood Order',
          customerEmail: authState.user?.email,
          customerFirstName: authState.user?.userMetadata?['full_name']?.toString().split(' ').first,
          customerLastName: authState.user?.userMetadata?['full_name']?.toString().split(' ').last,
        );

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PayFastPaymentScreen(
                paymentData: paymentData,
                orderId: orderId,
                amount: cartState.totalAmount,
              ),
            ),
          );
        }
      } else {
        // Handle cash payment or saved card
        final paymentService = payment_service.PaymentService();

        final paymentMethodType = paymentMethod == 'cash'
            ? payment_service.PaymentMethodType.cash
            : payment_service.PaymentMethodType.card;

        final paymentSuccess = await paymentService.processPayment(
          context: context,
          amount: cartState.totalAmount,
          orderId: orderId,
          method: paymentMethodType,
        );

        if (paymentSuccess) {
          // Place the order after successful payment
          await _placeOrderAfterPayment(context, ref, orderId, cartState);
        }
      }

    } catch (e, stack) {
      AppLogger.error('Failed to place order', error: e, stack: stack);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _placeOrderAfterPayment(
    BuildContext context,
    WidgetRef ref,
    String orderId,
    CartState cartState,
  ) async {
    try {
      final authState = ref.read(authStateProvider);

      // Place order using cart data
      await ref.read(placeOrderProvider.notifier).placeOrder(
        orderId: orderId,
        userId: authState.user!.id,
        restaurantId: cartState.restaurantId!,
        deliveryAddress: cartState.selectedAddress?.toJson() ?? {'type': 'pickup'},
        paymentMethod: _paymentMethod == 'cash' ? 'cash' : 'card',
        tipAmount: cartState.tipAmount,
        promoCode: cartState.promoCode,
        specialInstructions: cartState.deliveryNotes,
      );

      if (context.mounted) {
        // Navigate to order tracking
        context.push('/order/track/$orderId');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to place order after payment', error: e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful but failed to place order: $e'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Support',
              onPressed: () {
                // Navigate to support or contact info
              },
            ),
          ),
        );
      }
    }
  }
}