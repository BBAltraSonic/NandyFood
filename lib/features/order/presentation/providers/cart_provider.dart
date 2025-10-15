import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';
import 'package:food_delivery_app/shared/models/address.dart';

// Enum for delivery method
enum DeliveryMethod { delivery, pickup }

// Import payment method type from payment_method_provider
// Note: We'll use string for backward compatibility
typedef PaymentMethodType = String;

// Cart state class to represent the cart state
class CartState {
  final List<OrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double deliveryFee;
  final double tipAmount;
  final String? promoCode;
  final double discountAmount;
  final String? selectedPaymentMethodId;
  final bool isLoading;
  final String? errorMessage;
  final DeliveryMethod deliveryMethod;
  final Address? selectedAddress;
  final String? deliveryNotes;
  final String paymentMethod; // 'cash' or 'payfast'
  final String? restaurantId;

  CartState({
    this.items = const [],
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.deliveryFee = 0.0,
    this.tipAmount = 0.0,
    this.promoCode,
    this.discountAmount = 0.0,
    this.selectedPaymentMethodId,
    this.isLoading = false,
    this.errorMessage,
    this.deliveryMethod = DeliveryMethod.delivery,
    this.selectedAddress,
    this.deliveryNotes,
    this.paymentMethod = 'cash', // Default to cash
    this.restaurantId,
  });

  CartState copyWith({
    List<OrderItem>? items,
    double? subtotal,
    double? taxAmount,
    double? deliveryFee,
    double? tipAmount,
    String? promoCode,
    double? discountAmount,
    String? selectedPaymentMethodId,
    bool? isLoading,
    String? errorMessage,
    DeliveryMethod? deliveryMethod,
    Address? selectedAddress,
    String? deliveryNotes,
    String? paymentMethod,
    String? restaurantId,
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tipAmount: tipAmount ?? this.tipAmount,
      promoCode: promoCode ?? this.promoCode,
      discountAmount: discountAmount ?? this.discountAmount,
      selectedPaymentMethodId:
          selectedPaymentMethodId ?? this.selectedPaymentMethodId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }

  /// Calculate total amount
  double get totalAmount =>
      subtotal + taxAmount + deliveryFee + tipAmount - discountAmount;
}

// Cart provider to manage cart state
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  /// Add item to cart
  Future<void> addItem(
    MenuItem menuItem, {
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? specialInstructions,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Calculate unit price with customizations
      double unitPrice = menuItem.price;
      if (customizations != null) {
        // Apply size multiplier
        if (customizations['sizeMultiplier'] != null) {
          unitPrice =
              menuItem.price * (customizations['sizeMultiplier'] as double);
        }
        // Add toppings price
        if (customizations['toppingsPrice'] != null) {
          unitPrice += customizations['toppingsPrice'] as double;
        }
      }

      // Check if item already exists in cart
      final existingItemIndex = state.items.indexWhere(
        (item) =>
            item.menuItemId == menuItem.id &&
            _areCustomizationsEqual(item.customizations, customizations) &&
            item.specialInstructions == specialInstructions,
      );

      List<OrderItem> updatedItems;
      if (existingItemIndex != -1) {
        // Update quantity of existing item
        final existingItem = state.items[existingItemIndex];
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
        updatedItems = [...state.items]..[existingItemIndex] = updatedItem;
      } else {
        // Add new item to cart
        final newItem = OrderItem(
          id: '${menuItem.id}_${DateTime.now().millisecondsSinceEpoch}',
          orderId: '', // Will be set when order is created
          menuItemId: menuItem.id,
          quantity: quantity,
          unitPrice: unitPrice,
          customizations: customizations,
          specialInstructions: specialInstructions,
        );
        updatedItems = [...state.items, newItem];
      }

      final newState = state.copyWith(items: updatedItems, isLoading: false);

      // Recalculate totals
      state = _calculateTotals(newState);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));

      final updatedItems = state.items
          .where((item) => item.id != itemId)
          .toList();

      final newState = state.copyWith(items: updatedItems, isLoading: false);

      // Recalculate totals
      state = _calculateTotals(newState);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));

      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        await removeItem(itemId);
        return;
      }

      final updatedItems = state.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(quantity: quantity);
        }
        return item;
      }).toList();

      final newState = state.copyWith(items: updatedItems, isLoading: false);

      // Recalculate totals
      state = _calculateTotals(newState);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Apply promo code
  Future<void> applyPromoCode(String code) async {
    state = state.copyWith(isLoading: true);

    try {
      // Clear any previous error messages
      state = state.copyWith(errorMessage: null);

      // If code is empty, clear the promo code
      if (code.isEmpty) {
        state = state.copyWith(
          promoCode: null,
          discountAmount: 0.0,
          isLoading: false,
        );
        return;
      }

      // Validate the promo code with the backend
      final dbService = DatabaseService();
      final promoData = await dbService.getPromotionByCode(code);

      if (promoData == null) {
        throw Exception('Invalid promo code');
      }

      final promotion = Promotion.fromJson(promoData);

      // Check if promotion is valid using new model
      if (!promotion.isValid) {
        throw Exception('Promo code is not valid or has expired');
      }

      // Check minimum order amount
      if (promotion.minOrderAmount != null &&
          state.subtotal < promotion.minOrderAmount!) {
        throw Exception(
          'Minimum order amount of R${promotion.minOrderAmount} required',
        );
      }

      // Calculate discount using promotion method
      double discount = promotion.calculateDiscount(state.subtotal);

      // Ensure discount doesn't exceed subtotal
      discount = discount > state.subtotal ? state.subtotal : discount;

      state = state.copyWith(
        promoCode: promotion.code,
        discountAmount: discount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  /// Set delivery fee
  void setDeliveryFee(double fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  /// Set tip amount
  void setTipAmount(double tip) {
    state = state.copyWith(tipAmount: tip);
  }

  /// Clear cart
  void clearCart() {
    state = state.copyWith(
      items: const [],
      subtotal: 0.0,
      taxAmount: 0.0,
      deliveryFee: 0.0,
      tipAmount: 0.0,
      promoCode: null,
      discountAmount: 0.0,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Helper method to calculate cart totals
  CartState _calculateTotals(CartState currentState) {
    // Calculate subtotal
    final subtotal = currentState.items.fold(
      0.0,
      (sum, item) => sum + (item.unitPrice * item.quantity),
    );

    // Calculate tax (assuming 8.5% tax rate)
    final taxAmount = subtotal * 0.085;

    // Return updated state with calculated totals
    return currentState.copyWith(subtotal: subtotal, taxAmount: taxAmount);
  }

  /// Update selected payment method
  void updateSelectedPaymentMethod(String paymentMethodId) {
    state = state.copyWith(selectedPaymentMethodId: paymentMethodId);
  }

  /// Set delivery method
  void setDeliveryMethod(DeliveryMethod method) {
    state = state.copyWith(
      deliveryMethod: method,
      deliveryFee: method == DeliveryMethod.pickup ? 0.0 : state.deliveryFee,
    );
  }

  /// Set selected address
  void setSelectedAddress(Address? address) {
    state = state.copyWith(selectedAddress: address);
  }

  /// Set delivery notes
  void setDeliveryNotes(String? notes) {
    state = state.copyWith(deliveryNotes: notes);
  }

  /// Set payment method ('cash' or 'payfast')
  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Set restaurant ID
  void setRestaurantId(String? restaurantId) {
    state = state.copyWith(restaurantId: restaurantId);
  }

  /// Helper method to compare customizations
  bool _areCustomizationsEqual(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }

    return true;
  }
}
