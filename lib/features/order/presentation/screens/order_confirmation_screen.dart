import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:intl/intl.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estimatedDeliveryTime = order.estimatedDeliveryAt ??
        DateTime.now().add(const Duration(minutes: 30));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Success Animation
                    Lottie.asset(
                      'assets/animations/success.json',
                      width: 200,
                      height: 200,
                      repeat: false,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if animation file not found
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withValues(alpha: 0.1),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 120,
                            color: Colors.green,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Success Message
                    Text(
                      'Order Placed Successfully!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Thank you for your order',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Order Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[200]!,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Order Number
                          _buildDetailRow(
                            context,
                            'Order Number',
                            '#${order.id.substring(0, 8).toUpperCase()}',
                            icon: Icons.receipt_long,
                            valueColor: theme.primaryColor,
                            isBold: true,
                          ),

                          const Divider(height: 24),

                          // Estimated Delivery Time
                          _buildDetailRow(
                            context,
                            'Estimated Delivery',
                            _formatEstimatedDelivery(estimatedDeliveryTime),
                            icon: Icons.access_time,
                            valueColor: Colors.orange[700],
                          ),

                          const Divider(height: 24),

                          // Total Amount
                          _buildDetailRow(
                            context,
                            'Total Amount',
                            '\$${order.totalAmount.toStringAsFixed(2)}',
                            icon: Icons.attach_money,
                            isBold: true,
                          ),

                          const Divider(height: 24),

                          // Payment Method
                          _buildDetailRow(
                            context,
                            'Payment Method',
                            _formatPaymentMethod(order.paymentMethod),
                            icon: Icons.payment,
                          ),

                          if (order.deliveryAddress.isNotEmpty) ...[
                            const Divider(height: 24),
                            _buildAddressRow(context, order.deliveryAddress),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You can track your order status in real-time from the Track Order screen',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Track Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(
                          '/order/track',
                          arguments: order,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Track Order',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Return to Home Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home',
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Return to Home',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
    bool isBold = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? Colors.black87,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(
    BuildContext context,
    Map<String, dynamic> address,
  ) {
    final theme = Theme.of(context);
    final addressString = '${address['street'] ?? ''}, '
        '${address['city'] ?? ''} ${address['zipCode'] ?? ''}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.location_on,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                addressString,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatEstimatedDelivery(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return DateFormat('h:mm a').format(estimatedTime);
    }
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      default:
        return method;
    }
  }
}
