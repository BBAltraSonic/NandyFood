import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';


class PaymentResultScreen extends StatelessWidget {
  final String orderId;
  final bool success;
  final String? paymentReference;
  final String? errorMessage;

  const PaymentResultScreen({
    super.key,
    required this.orderId,
    required this.success,
    this.paymentReference,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(success ? 'Payment Successful' : 'Payment Failed'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                size: 72,
                color: success ? Colors.green : theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'Your payment was successful' : 'Your payment could not be completed',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (success) ...[
                Text(
                  'Order #$orderId',
                  style: theme.textTheme.titleMedium,
                ),
                if (paymentReference != null) ...[
                  const SizedBox(height: 4),
                  Text('Ref: $paymentReference', style: theme.textTheme.bodySmall),
                ],
              ] else ...[
                Text(
                  errorMessage ?? 'We could not verify your payment. Please try again or choose a different method.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (success) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(RoutePaths.orderTrackWithId(orderId)),
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('Track Order'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(RoutePaths.home),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Home'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(RoutePaths.orderCart),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go(RoutePaths.orderCart),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Use Different Method'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go(RoutePaths.home),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

