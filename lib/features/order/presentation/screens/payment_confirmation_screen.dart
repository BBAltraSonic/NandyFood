import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_provider.dart';
import 'package:food_delivery_app/shared/models/payment_transaction.dart';

/// Screen showing payment confirmation result
class PaymentConfirmationScreen extends ConsumerStatefulWidget {
  final String orderId;
  final bool success;
  final String? paymentReference;
  final String? errorMessage;

  const PaymentConfirmationScreen({
    super.key,
    required this.orderId,
    required this.success,
    this.paymentReference,
    this.errorMessage,
  });

  @override
  ConsumerState<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState
    extends ConsumerState<PaymentConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    AppLogger.function('PaymentConfirmationScreen.initState', 'ENTER', params: {
      'orderId': widget.orderId,
      'success': widget.success,
      'paymentReference': widget.paymentReference,
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentProvider);

    return PopScope(
      canPop: widget.success,
      child: Scaffold(
        body: SafeArea(
          child: widget.success
              ? _buildSuccessView(context)
              : paymentState.isVerifying
                  ? _buildPendingView(context)
                  : _buildFailureView(context),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _animationController,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated success icon
              ScaleTransition(
                scale: _animationController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Success title
              Text(
                'Payment Successful!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Your order has been placed successfully',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Order details card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Order Number',
                        '#${widget.orderId}',
                        theme,
                      ),
                      const Divider(height: 20),
                      _buildDetailRow(
                        'Payment Method',
                        'PayFast Card Payment',
                        theme,
                      ),
                      if (widget.paymentReference != null) ...[
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Payment Reference',
                          widget.paymentReference!,
                          theme,
                          copyable: true,
                        ),
                      ],
                      const Divider(height: 20),
                      _buildDetailRow(
                        'Status',
                        'Confirmed',
                        theme,
                        valueColor: Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToOrderTracking(context),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Track Order'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToHome(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade600,
              ),
            ),

            const SizedBox(height: 32),

            // Error title
            Text(
              'Payment Failed',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              widget.errorMessage ?? 'We couldn\'t process your payment',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Error details card
            Card(
              elevation: 2,
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Don\'t worry, your card was not charged',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _retryPayment(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _changePaymentMethod(context),
                icon: const Icon(Icons.payment),
                label: const Text('Use Different Method'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => _navigateToHome(context),
              child: const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingView(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pending icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: _isCheckingStatus
                  ? const CircularProgressIndicator()
                  : Icon(
                      Icons.hourglass_empty,
                      size: 80,
                      color: Colors.orange.shade600,
                    ),
            ),

            const SizedBox(height: 32),

            // Pending title
            Text(
              'Payment Verification Pending',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'We\'re verifying your payment with the bank. This usually takes a few seconds.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            if (widget.paymentReference != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Payment Reference',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.paymentReference!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Action buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isCheckingStatus ? null : () => _checkStatus(context),
                icon: _isCheckingStatus
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isCheckingStatus ? 'Checking...' : 'Check Status'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton.icon(
              onPressed: () => _navigateToHome(context),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
    bool copyable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _copyToClipboard(value),
                child: Icon(
                  Icons.copy,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    // Copy to clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _checkStatus(BuildContext context) async {
    if (widget.paymentReference == null) return;

    setState(() => _isCheckingStatus = true);

    try {
      final status = await ref
          .read(paymentProvider.notifier)
          .verifyPaymentStatus(widget.paymentReference!);

      if (status == PaymentTransactionStatus.completed) {
        setState(() {});
      } else if (status == PaymentTransactionStatus.failed) {
        setState(() {});
      }
    } catch (e) {
      AppLogger.error('Failed to check payment status', error: e);
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  void _navigateToOrderTracking(BuildContext context) {
    AppLogger.navigation('PaymentConfirmation', 'OrderTracking');
    // Navigate to order tracking - implementation depends on routing setup
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/order-tracking',
      (route) => false,
      arguments: widget.orderId,
    );
  }

  void _navigateToHome(BuildContext context) {
    AppLogger.navigation('PaymentConfirmation', 'Home');
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    );
  }

  void _retryPayment(BuildContext context) {
    AppLogger.info('Retrying payment');
    // Pop back to checkout
    Navigator.popUntil(context, (route) => route.settings.name == '/checkout');
  }

  void _changePaymentMethod(BuildContext context) {
    AppLogger.info('Changing payment method');
    // Pop back to payment method selection
    int popCount = 0;
    Navigator.popUntil(context, (route) {
      popCount++;
      return popCount >= 2; // Pop payment confirmation and payfast screens
    });
  }
}
