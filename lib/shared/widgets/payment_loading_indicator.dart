import 'package:flutter/material.dart';
import 'dart:async';

/// Custom loading indicator for payment processing
class PaymentLoadingIndicator extends StatefulWidget {
  final String message;
  final int? estimatedSeconds;
  final bool cancellable;
  final VoidCallback? onCancel;

  const PaymentLoadingIndicator({
    super.key,
    this.message = 'Processing payment...',
    this.estimatedSeconds,
    this.cancellable = false,
    this.onCancel,
  });

  @override
  State<PaymentLoadingIndicator> createState() =>
      _PaymentLoadingIndicatorState();
}

class _PaymentLoadingIndicatorState extends State<PaymentLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    if (widget.estimatedSeconds != null) {
      _remainingSeconds = widget.estimatedSeconds;
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds != null && _remainingSeconds! > 0) {
          _remainingSeconds = _remainingSeconds! - 1;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated payment icon
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_controller.value * 0.1),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payment,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Message
              Text(
                widget.message,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Progress indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),

              // Estimated time
              if (_remainingSeconds != null) ...[
                const SizedBox(height: 16),
                Text(
                  _remainingSeconds! > 0
                      ? 'Estimated time: $_remainingSeconds seconds'
                      : 'Almost done...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Cancel button
              if (widget.cancellable && widget.onCancel != null) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel Payment'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple circular payment loading indicator
class SimplePaymentLoadingIndicator extends StatelessWidget {
  const SimplePaymentLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Processing...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
