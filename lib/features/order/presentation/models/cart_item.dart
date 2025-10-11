import 'package:food_delivery_app/shared/models/order_item.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

class CartItem {
  final OrderItem orderItem;
  final MenuItem menuItem;

  CartItem({required this.orderItem, required this.menuItem});

  double get totalPrice => orderItem.unitPrice * orderItem.quantity;

  CartItem copyWith({OrderItem? orderItem, MenuItem? menuItem}) {
    return CartItem(
      orderItem: orderItem ?? this.orderItem,
      menuItem: menuItem ?? this.menuItem,
    );
  }
}
