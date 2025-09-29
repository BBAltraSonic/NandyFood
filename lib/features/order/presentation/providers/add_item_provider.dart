import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

// Add item state class to represent the add item state
class AddItemState {
  final bool isLoading;
  final String? errorMessage;
  final OrderItem? addedItem;

  AddItemState({
    this.isLoading = false,
    this.errorMessage,
    this.addedItem,
  });

  AddItemState copyWith({
    bool? isLoading,
    String? errorMessage,
    OrderItem? addedItem,
  }) {
    return AddItemState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      addedItem: addedItem ?? this.addedItem,
    );
  }
}

// Add item provider to manage adding items to cart
final addItemProvider = StateNotifierProvider<AddItemNotifier, AddItemState>(
  (ref) => AddItemNotifier(ref),
);

class AddItemNotifier extends StateNotifier<AddItemState> {
  final Ref _ref;
  
  AddItemNotifier(this._ref) : super(AddItemState());

  /// Add item to cart
  Future<void> addItemToCart({
    required MenuItem menuItem,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? specialInstructions,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Add item to cart using cart provider
      await _ref.read(cartProvider.notifier).addItem(
        menuItem,
        quantity: quantity,
        customizations: customizations,
        specialInstructions: specialInstructions,
      );
      
      // Create order item for state
      final orderItem = OrderItem(
        id: '${menuItem.id}_${DateTime.now().millisecondsSinceEpoch}',
        orderId: '', // Will be set when order is created
        menuItemId: menuItem.id,
        quantity: quantity,
        unitPrice: menuItem.price,
        customizations: customizations,
        specialInstructions: specialInstructions,
      );
      
      state = state.copyWith(
        addedItem: orderItem,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Remove item from cart
  Future<void> removeItemFromCart(String itemId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Remove item from cart using cart provider
      await _ref.read(cartProvider.notifier).removeItem(itemId);
      
      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update item quantity in cart
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Update item quantity using cart provider
      await _ref.read(cartProvider.notifier).updateItemQuantity(itemId, quantity);
      
      state = state.copyWith(
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}