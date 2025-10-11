import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

// Place order state class to represent the place order state
class PlaceOrderState {
  final bool isLoading;
  final String? errorMessage;
  final Order? placedOrder;
  final double totalAmount;
  final double deliveryFee;
  final double taxAmount;
  final double tipAmount;
  final double discountAmount;
  final String? promoCode;

  PlaceOrderState({
    this.isLoading = false,
    this.errorMessage,
    this.placedOrder,
    this.totalAmount = 0.0,
    this.deliveryFee = 0.0,
    this.taxAmount = 0.0,
    this.tipAmount = 0.0,
    this.discountAmount = 0.0,
    this.promoCode,
  });

  PlaceOrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    Order? placedOrder,
    double? totalAmount,
    double? deliveryFee,
    double? taxAmount,
    double? tipAmount,
    double? discountAmount,
    String? promoCode,
  }) {
    return PlaceOrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      placedOrder: placedOrder ?? this.placedOrder,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      promoCode: promoCode ?? this.promoCode,
    );
  }
}

// Place order provider to manage placing orders
final placeOrderProvider =
    StateNotifierProvider<PlaceOrderNotifier, PlaceOrderState>(
      (ref) => PlaceOrderNotifier(ref),
    );

class PlaceOrderNotifier extends StateNotifier<PlaceOrderState> {
  final Ref _ref;

  PlaceOrderNotifier(this._ref) : super(PlaceOrderState());

  /// Place order with items in cart
  Future<void> placeOrder({
    required String userId,
    required String restaurantId,
    required Map<String, dynamic> deliveryAddress,
    String? paymentMethod,
    double? tipAmount,
    String? promoCode,
    String? specialInstructions,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Get cart items
      final cartState = _ref.read(cartProvider);
      final cartItems = cartState.items;

      if (cartItems.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }

      // Calculate order totals
      final subtotal = cartState.subtotal;
      final taxAmount = cartState.taxAmount;
      final deliveryFee = cartState.deliveryFee;
      final discountAmount = cartState.discountAmount;
      final totalAmount = cartState.totalAmount;

      // Create order data
      final order = Order(
        id: '', // Will be set by the database
        userId: userId,
        restaurantId: restaurantId,
        deliveryAddress: deliveryAddress,
        status: OrderStatus.placed,
        totalAmount: totalAmount,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        taxAmount: taxAmount,
        tipAmount: tipAmount ?? 0.0,
        discountAmount: discountAmount,
        promoCode: promoCode?.toUpperCase(),
        paymentMethod: paymentMethod ?? 'Credit Card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        specialInstructions: specialInstructions,
      );

      // Create order using order provider
      await _ref.read(orderProvider.notifier).createOrder(order);

      // Update state with placed order
      state = state.copyWith(placedOrder: order, isLoading: false);

      // Clear the cart after successful order placement
      _ref.read(cartProvider.notifier).clearCart();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Update delivery fee
  void updateDeliveryFee(double fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  /// Update tip amount
  void updateTipAmount(double tip) {
    state = state.copyWith(tipAmount: tip);
  }

  /// Apply promo code
  Future<void> applyPromoCode(String code) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // In a real app, this would validate the promo code with the backend
      // For now, we'll simulate a 10% discount
      final cartState = _ref.read(cartProvider);
      final discount = cartState.subtotal * 0.1;

      state = state.copyWith(
        promoCode: code.toUpperCase(),
        discountAmount: discount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid promo code',
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset order state
  void reset() {
    state = PlaceOrderState();
  }
}
