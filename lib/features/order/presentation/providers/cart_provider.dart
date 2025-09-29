import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';

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
  }) {
    return CartState(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tipAmount: tipAmount ?? this.tipAmount,
      promoCode: promoCode ?? this.promoCode,
      discountAmount: discountAmount ?? this.discountAmount,
      selectedPaymentMethodId: selectedPaymentMethodId ?? this.selectedPaymentMethodId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Calculate total amount
  double get totalAmount => subtotal + taxAmount + deliveryFee + tipAmount - discountAmount;
}

// Cart provider to manage cart state
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  /// Add item to cart
  Future<void> addItem(MenuItem menuItem, {int quantity = 1, Map<String, dynamic>? customizations, String? specialInstructions}) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if item already exists in cart
      final existingItemIndex = state.items.indexWhere((item) => 
        item.menuItemId == menuItem.id && 
        _areCustomizationsEqual(item.customizations, customizations) &&
        item.specialInstructions == specialInstructions
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
          unitPrice: menuItem.price,
          customizations: customizations,
          specialInstructions: specialInstructions,
        );
        updatedItems = [...state.items, newItem];
      }
      
      final newState = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
      
      // Recalculate totals
      state = _calculateTotals(newState);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      final updatedItems = state.items.where((item) => item.id != itemId).toList();
      
      final newState = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
      
      // Recalculate totals
      state = _calculateTotals(newState);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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
      
      final newState = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
      
      // Recalculate totals
      state = _calculateTotals(newState);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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
      
      // Check if promotion is active
      if (!promotion.isActive) {
        throw Exception('Promo code is no longer active');
      }
      
      // Check if promotion is within valid dates
      final now = DateTime.now();
      if (now.isBefore(promotion.validFrom) || now.isAfter(promotion.validUntil)) {
        throw Exception('Promo code is not valid at this time');
      }
      
      // Check if promotion has usage limits
      if (promotion.usageLimit != null && promotion.usedCount >= promotion.usageLimit!) {
        throw Exception('Promo code has reached its usage limit');
      }
      
      // Check minimum order amount
      if (promotion.minimumOrderAmount != null && state.subtotal < promotion.minimumOrderAmount!) {
        throw Exception('Minimum order amount of \$${promotion.minimumOrderAmount} required');
      }
      
      // Calculate discount based on promotion type
      double discount = 0.0;
      if (promotion.discountType == PromotionType.percentage) {
        discount = state.subtotal * (promotion.discountValue / 100);
      } else if (promotion.discountType == PromotionType.fixedAmount) {
        discount = promotion.discountValue;
      }
      
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
    final subtotal = currentState.items.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));
    
    // Calculate tax (assuming 8.5% tax rate)
    final taxAmount = subtotal * 0.085;
    
    // Return updated state with calculated totals
    return currentState.copyWith(
      subtotal: subtotal,
      taxAmount: taxAmount,
    );
  }

  /// Update selected payment method
  void updateSelectedPaymentMethod(String paymentMethodId) {
    state = state.copyWith(selectedPaymentMethodId: paymentMethodId);
  }

  /// Helper method to compare customizations
  bool _areCustomizationsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    
    return true;
  }
}