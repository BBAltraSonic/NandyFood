import 'package:flutter/material.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

class CartSummaryWidget extends StatelessWidget {
  final CartState cartState;
  final VoidCallback? onCheckout;
  final VoidCallback? onApplyPromoCode;

  const CartSummaryWidget({
    super.key,
    required this.cartState,
    this.onCheckout,
    this.onApplyPromoCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cart header
            const Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Subtotal
            _buildSummaryRow(
              'Subtotal',
              '\$${cartState.subtotal.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),

            // Tax
            _buildSummaryRow(
              'Tax',
              '\$${cartState.taxAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),

            // Delivery fee
            _buildSummaryRow(
              'Delivery Fee',
              '\$${cartState.deliveryFee.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),

            // Discount (if applicable)
            if (cartState.discountAmount > 0)
              _buildSummaryRow(
                'Discount ${cartState.promoCode != null ? '(${cartState.promoCode})' : ''}',
                '-\$${cartState.discountAmount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            const SizedBox(height: 8),

            // Tip (if applicable)
            if (cartState.tipAmount > 0)
              _buildSummaryRow(
                'Tip',
                '\$${cartState.tipAmount.toStringAsFixed(2)}',
              ),
            const SizedBox(height: 16),

            // Divider
            const Divider(),
            const SizedBox(height: 8),

            // Total
            _buildSummaryRow(
              'Total',
              '\$${cartState.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 16),

            // Promo code input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Promo Code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && onApplyPromoCode != null) {
                        onApplyPromoCode!();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApplyPromoCode,
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cartState.items.isNotEmpty ? onCheckout : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a summary row
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount
                ? Colors.black87
                : (isTotal ? Colors.black : Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isDiscount
                ? Colors.black87
                : (isTotal ? Colors.black : Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
