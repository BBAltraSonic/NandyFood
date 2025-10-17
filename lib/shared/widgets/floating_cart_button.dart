import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:go_router/go_router.dart';

/// A floating action button that displays the current cart state
/// and provides quick access to the cart screen.
///
/// Features:
/// - Animated item count badge
/// - Tap to navigate to cart
/// - Long press to preview cart summary
/// - Smooth animations for count changes
/// - Hide when cart is empty
class FloatingCartButton extends ConsumerStatefulWidget {
  const FloatingCartButton({super.key});

  @override
  ConsumerState<FloatingCartButton> createState() =>
      _FloatingCartButtonState();
}

class _FloatingCartButtonState extends ConsumerState<FloatingCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isPreviewVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removePreview();
    super.dispose();
  }

  void _removePreview() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isPreviewVisible = false;
  }

  void _showCartPreview(BuildContext context, CartState cartState) {
    if (_isPreviewVisible) return;

    _isPreviewVisible = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => _CartPreviewOverlay(
        cartState: cartState,
        onDismiss: _removePreview,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final itemCount = cartState.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    // Listen to item count changes and trigger animation
    ref.listen<CartState>(cartProvider, (previous, current) {
      final previousCount = previous?.items.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ) ??
          0;
      final currentCount = current.items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      );

      if (previousCount != currentCount) {
        _animationController.forward(from: 0);
      }
    });

    // Hide button when cart is empty
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      bottom: 80,
      child: GestureDetector(
        onTap: () {
          context.push('/cart');
        },
        onLongPress: () {
          _showCartPreview(context, cartState);
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_scaleAnimation.value * 0.2),
              child: child,
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF919849),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF919849).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Cart icon
                const Center(
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                // Badge with item count
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        itemCount > 99 ? '99+' : '$itemCount',
                        style: const TextStyle(
                          color: Color(0xFF919849),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay widget that shows cart preview on long press
class _CartPreviewOverlay extends StatelessWidget {
  final CartState cartState;
  final VoidCallback onDismiss;

  const _CartPreviewOverlay({
    required this.cartState,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping the card
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF919849),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Cart Preview',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Item count
                    _buildInfoRow(
                      Icons.inventory_2_outlined,
                      'Items',
                      '${cartState.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                    ),
                    const SizedBox(height: 12),
                    // Subtotal
                    _buildInfoRow(
                      Icons.receipt_outlined,
                      'Subtotal',
                      '\$${cartState.subtotal.toStringAsFixed(2)}',
                    ),
                    if (cartState.discountAmount > 0) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.discount_outlined,
                        'Savings',
                        '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                        valueColor: Colors.green,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF919849).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'R ${cartState.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF919849),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hint text
                    const Text(
                      'Tap outside to close',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
