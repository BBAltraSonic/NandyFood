import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/features/order/data/repositories/cart_order_repository.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:uuid/uuid.dart';

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
  final CartOrderRepository _orderRepository;
  final DatabaseService _dbService;

  PlaceOrderNotifier(this._ref)
      : _orderRepository = CartOrderRepository(),
        _dbService = DatabaseService(),
        super(PlaceOrderState());

  /// Place order with comprehensive validation and order creation
  Future<void> placeOrder({
    String? userId,
    String? restaurantId,
    Map<String, dynamic>? deliveryAddress,
    String? paymentMethod,
    double? tipAmount,
    String? promoCode,
    String? specialInstructions,
    String? orderId,
    bool isTestOrder = false,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Get current authenticated user if userId not provided
      userId ??= _dbService.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User must be authenticated to place an order');
      }

      // Get cart state and validate
      final cartState = _ref.read(cartProvider);
      final cartItems = cartState.items;

      if (cartItems.isEmpty) {
        throw Exception('Cannot place order with empty cart');
      }

      // Validate cart items are still available
      if (!await _validateCartItems(cartItems)) {
        throw Exception('Some items in your cart are no longer available');
      }

      // Get restaurant information if not provided
      restaurantId ??= cartState.restaurantId;
      if (restaurantId == null) {
        throw Exception('Restaurant information is missing');
      }

      final restaurant = await _getRestaurant(restaurantId);
      if (restaurant == null) {
        throw Exception('Restaurant not found');
      }

      // Validate delivery address
      deliveryAddress ??= cartState.selectedAddress?.toJson();
      if (cartState.deliveryMethod == DeliveryMethod.delivery && deliveryAddress == null) {
        throw Exception('Delivery address is required for delivery orders');
      }

      // Validate payment method
      paymentMethod ??= cartState.paymentMethod;
      if (paymentMethod == null || paymentMethod.isEmpty) {
        throw Exception('Payment method is required');
      }

      // Calculate order totals
      final subtotal = cartState.subtotal;
      final taxAmount = cartState.taxAmount;
      final deliveryFee = cartState.deliveryFee;
      final discountAmount = cartState.discountAmount;
      final tip = tipAmount ?? cartState.tipAmount;
      final totalAmount = subtotal + taxAmount + deliveryFee + tip - discountAmount;

      // Validate minimum order amount
      if (restaurant.minimumOrderAmount != null && subtotal < restaurant.minimumOrderAmount!) {
        throw Exception('Minimum order amount of R${restaurant.minimumOrderAmount} required');
      }

      // Generate unique order number
      final generatedOrderId = orderId ?? const Uuid().v4();
      final orderNumber = _generateOrderNumber();

      // Calculate delivery times
      final now = DateTime.now();
      final estimatedPrepTime = Duration(minutes: 30);
      final estimatedDeliveryTime = Duration(minutes: restaurant.estimatedDeliveryTime);

      DateTime scheduledDeliveryTime;
      if (cartState.isAsapDelivery) {
        scheduledDeliveryTime = now.add(estimatedPrepTime).add(estimatedDeliveryTime);
      } else {
        scheduledDeliveryTime = cartState.scheduledDeliveryTime ?? now.add(estimatedPrepTime).add(estimatedDeliveryTime);
      }

      // Create order data
      final orderData = {
        'id': generatedOrderId,
        'order_number': orderNumber,
        'user_id': userId,
        'restaurant_id': restaurantId,
        'status': 'pending', // Initial status
        'payment_status': paymentMethod == 'cash' ? 'pending' : 'pending',
        'payment_method': paymentMethod,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'delivery_fee': deliveryFee,
        'tip_amount': tip,
        'discount_amount': discountAmount,
        'total_amount': totalAmount,
        'delivery_method': cartState.deliveryMethod.name,
        'delivery_address': deliveryAddress,
        'delivery_notes': specialInstructions ?? cartState.deliveryNotes,
        'promo_code': promoCode?.toUpperCase() ?? cartState.promoCode,
        'placed_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'estimated_prep_time': estimatedPrepTime.inMinutes,
        'estimated_delivery_time': estimatedDeliveryTime.inMinutes,
        'scheduled_delivery_time': scheduledDeliveryTime.toIso8601String(),
        'is_asap_delivery': cartState.isAsapDelivery,
        'is_test_order': isTestOrder,
      };

      // Create order in database
      final createOrderResult = await _orderRepository.createOrder(orderData);
      final createdOrderId = createOrderResult.when(
        success: (orderId) => orderId,
        failure: (failure) => throw Exception('Failed to create order: ${failure.message}'),
      );

      // Create order items
      await _createOrderItems(createdOrderId, cartItems);

      // Get full order details
      final order = await _getOrderById(createdOrderId);
      if (order == null) {
        throw Exception('Failed to retrieve created order');
      }

      // Update state with placed order
      state = state.copyWith(
        placedOrder: order,
        totalAmount: totalAmount,
        deliveryFee: deliveryFee,
        taxAmount: taxAmount,
        tipAmount: tip,
        discountAmount: discountAmount,
        promoCode: promoCode?.toUpperCase() ?? cartState.promoCode,
        isLoading: false,
      );

      // Clear the cart after successful order placement
      _ref.read(cartProvider.notifier).clearCart();

      // Send order confirmation (if not test order)
      if (!isTestOrder) {
        await _sendOrderConfirmation(order);
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
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

  // ==================== HELPER METHODS ====================

  /// Validate cart items are still available and belong to the same restaurant
  Future<bool> _validateCartItems(List<OrderItem> cartItems) async {
    try {
      String? restaurantId;

      for (final item in cartItems) {
        final menuItemData = await _dbService.getMenuItemById(item.menuItemId);
        if (menuItemData == null) return false;

        final menuItem = MenuItem.fromJson(menuItemData);
        if (!menuItem.isAvailable) return false;

        // Check if all items belong to the same restaurant
        if (restaurantId == null) {
          restaurantId = menuItem.restaurantId;
        } else if (restaurantId != menuItem.restaurantId) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error validating cart items: $e');
      return false;
    }
  }

  /// Get restaurant information
  Future<Restaurant?> _getRestaurant(String restaurantId) async {
    try {
      final restaurantData = await _dbService.getRestaurant(restaurantId);
      if (restaurantData == null) return null;
      return Restaurant.fromJson(restaurantData);
    } catch (e) {
      print('Error getting restaurant: $e');
      return null;
    }
  }

  /// Get order by ID
  Future<Order?> _getOrderById(String orderId) async {
    try {
      final orderData = await _dbService.getOrder(orderId);
      if (orderData == null) return null;
      return Order.fromJson(orderData);
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  /// Create order items in database
  Future<void> _createOrderItems(String orderId, List<OrderItem> cartItems) async {
    try {
      for (final item in cartItems) {
        final orderItemData = {
          'id': const Uuid().v4(),
          'order_id': orderId,
          'menu_item_id': item.menuItemId,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'customizations': item.customizations,
          'special_instructions': item.specialInstructions,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // This would require an 'order_items' table in Supabase
        await _dbService.client.from('order_items').insert(orderItemData);
      }
    } catch (e) {
      print('Error creating order items: $e');
      rethrow;
    }
  }

  /// Generate unique order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(6);
    final random = (now.second + now.minute).toString().padLeft(2, '0');
    return 'ORD$timestamp$random';
  }

  /// Send order confirmation
  Future<void> _sendOrderConfirmation(Order order) async {
    try {
      // This would integrate with a notification service
      // For now, we'll just print the confirmation
      print('Order Confirmation Sent:');
      print('Order Number: ${order.id}');
      print('Status: ${order.status}');
      print('Total: R${order.totalAmount.toStringAsFixed(2)}');
      print('Estimated Preparation Time: ${order.estimatedPreparationTime} minutes');

      // You could integrate with:
      // - Email service
      // - SMS service
      // - Push notifications
      // - WhatsApp business API

    } catch (e) {
      print('Error sending order confirmation: $e');
      // Don't fail the order if confirmation fails
    }
  }

  // ==================== VALIDATION METHODS ====================

  /// Validate order before placing
  Future<Map<String, String>> validateOrder() async {
    final errors = <String, String>{};

    try {
      // Get cart state
      final cartState = _ref.read(cartProvider);

      // Check if cart is empty
      if (cartState.items.isEmpty) {
        errors['cart'] = 'Your cart is empty';
        return errors;
      }

      // Check user authentication
      final userId = _dbService.auth.currentUser?.id;
      if (userId == null) {
        errors['auth'] = 'Please sign in to place an order';
        return errors;
      }

      // Validate restaurant
      if (cartState.restaurantId == null) {
        errors['restaurant'] = 'Restaurant information is missing';
        return errors;
      }

      final restaurant = await _getRestaurant(cartState.restaurantId!);
      if (restaurant == null) {
        errors['restaurant'] = 'Restaurant not found';
        return errors;
      }

      // Check if restaurant is open
      if (!_isRestaurantOpen(restaurant)) {
        errors['restaurant'] = 'Restaurant is currently closed';
        return errors;
      }

      // Validate delivery address for delivery orders
      if (cartState.deliveryMethod == DeliveryMethod.delivery && cartState.selectedAddress == null) {
        errors['address'] = 'Delivery address is required';
      }

      // Validate payment method
      if (cartState.paymentMethod.isEmpty) {
        errors['payment'] = 'Payment method is required';
      }

      // Validate minimum order amount
      if (restaurant.minimumOrderAmount != null && cartState.subtotal < restaurant.minimumOrderAmount!) {
        errors['amount'] = 'Minimum order amount of R${restaurant.minimumOrderAmount} required';
      }

      // Validate delivery time
      if (!cartState.isAsapDelivery && cartState.scheduledDeliveryTime != null) {
        if (!_isValidDeliveryTime(cartState.scheduledDeliveryTime!, restaurant)) {
          errors['delivery_time'] = 'Selected delivery time is not available';
        }
      }

      // Validate stock availability
      if (!await _validateCartItems(cartState.items)) {
        errors['stock'] = 'Some items in your cart are no longer available';
      }

    } catch (e) {
      errors['general'] = 'An unexpected error occurred: ${e.toString()}';
    }

    return errors;
  }

  /// Check if restaurant is currently open
  bool _isRestaurantOpen(Restaurant restaurant) {
    try {
      final now = DateTime.now();
      final dayOfWeek = now.weekday;
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final dayKeys = [
        'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
      ];
      final dayKey = dayKeys[dayOfWeek - 1];

      final operatingHours = restaurant.openingHours[dayKey];
      if (operatingHours == null || operatingHours['is_closed'] == true) {
        return false;
      }

      final openTime = operatingHours['open'] as String?;
      final closeTime = operatingHours['close'] as String?;

      if (openTime == null || closeTime == null) return false;

      return _compareTime(currentTime, openTime) >= 0 && _compareTime(currentTime, closeTime) <= 0;
    } catch (e) {
      return false;
    }
  }

  /// Check if delivery time is valid
  bool _isValidDeliveryTime(DateTime deliveryTime, Restaurant restaurant) {
    // Check if delivery time is in the future
    if (deliveryTime.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      return false;
    }

    // Check if restaurant is open at delivery time
    final dayOfWeek = deliveryTime.weekday;
    final dayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    final dayKey = dayKeys[dayOfWeek - 1];

    final operatingHours = restaurant.openingHours[dayKey];
    if (operatingHours == null || operatingHours['is_closed'] == true) {
      return false;
    }

    final openTime = operatingHours['open'] as String?;
    final closeTime = operatingHours['close'] as String?;

    if (openTime == null || closeTime == null) return false;

    final deliveryTimeStr = '${deliveryTime.hour.toString().padLeft(2, '0')}:${deliveryTime.minute.toString().padLeft(2, '0')}';

    return _compareTime(deliveryTimeStr, openTime) >= 0 && _compareTime(deliveryTimeStr, closeTime) <= 0;
  }

  // ==================== UTILITY METHODS ====================

  /// Compare two time strings in "HH:mm" format
  /// Returns: -1 if time1 < time2, 0 if equal, 1 if time1 > time2
  int _compareTime(String time1, String time2) {
    final parts1 = time1.split(':').map(int.parse).toList();
    final parts2 = time2.split(':').map(int.parse).toList();

    final totalMinutes1 = parts1[0] * 60 + parts1[1];
    final totalMinutes2 = parts2[0] * 60 + parts2[1];

    return totalMinutes1.compareTo(totalMinutes2);
  }

  /// Get order summary for confirmation
  Map<String, dynamic> getOrderSummary() {
    final cartState = _ref.read(cartProvider);

    return {
      'items_count': cartState.items.fold(0, (sum, item) => sum + item.quantity),
      'subtotal': cartState.subtotal,
      'tax_amount': cartState.taxAmount,
      'delivery_fee': cartState.deliveryFee,
      'tip_amount': cartState.tipAmount,
      'discount_amount': cartState.discountAmount,
      'total_amount': cartState.totalAmount,
      'delivery_method': cartState.deliveryMethod.name,
      'estimated_delivery_time': cartState.isAsapDelivery
          ? 'ASAP (${(30 + (cartState.restaurant?.estimatedDeliveryTime ?? 45))} minutes)'
          : 'Scheduled',
      'restaurant_name': cartState.restaurant?.name ?? 'Unknown Restaurant',
      'promo_code': cartState.promoCode,
    };
  }

  /// Cancel an order (if it hasn't been confirmed by restaurant)
  Future<bool> cancelOrder(String orderId, String? reason) async {
    try {
      // This would update the order status in the database
      // For now, we'll just return true as a placeholder
      print('Cancelling order: $orderId');
      if (reason != null) {
        print('Reason: $reason');
      }

      // In a real implementation:
      // await _dbService.client.from('orders').update({'status': 'cancelled'}).eq('id', orderId);

      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  /// Retry placing a failed order
  Future<void> retryOrder() async {
    if (state.placedOrder == null && state.errorMessage != null) {
      // Try to place the order again with the same parameters
      final cartState = _ref.read(cartProvider);
      if (cartState.items.isNotEmpty) {
        await placeOrder(isTestOrder: false);
      }
    }
  }
}
