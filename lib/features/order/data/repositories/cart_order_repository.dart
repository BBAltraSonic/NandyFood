import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/payment_service.dart' as ps;
import 'package:food_delivery_app/shared/models/order.dart';

class CartOrderRepository with RepositoryGuard {
  final DatabaseService _db;
  final ps.PaymentService _payment;

  CartOrderRepository({DatabaseService? db, ps.PaymentService? payment})
      : _db = db ?? DatabaseService(),
        _payment = payment ?? ps.PaymentService();

  Future<Result<String>> createOrder(Map<String, dynamic> orderData) async {
    return guard(() => _db.createOrder(orderData));
  }

  Future<Result<Order>> getOrderById(String orderId) async {
    return guard(() async {
      final row = await _db.getOrder(orderId);
      if (row == null) {
        throw NotFoundFailure(message: 'Order not found', code: '404');
      }
      return Order.fromJson(row);
    });
  }

  Future<Result<List<Order>>> getUserOrders(String userId) async {
    return guard(() async {
      final rows = await _db.getUserOrders(userId);
      return rows.map((r) => Order.fromJson(r)).toList();
    });
  }

  /// Process cash payment; returns true on success
  Future<Result<bool>> processCashPayment({
    required double amount,
    required String orderId,
    required Object uiContext, // BuildContext at callsite
  }) async {
    return guard(() async {
      // We keep the signature loosely typed to avoid UI import here; cast at callsite
      final ctx = uiContext as dynamic; // expecting BuildContext
      final ok = await _payment.processPayment(
        context: ctx,
        amount: amount,
        orderId: orderId,
        method: ps.PaymentMethodType.cash,
      );
      return ok;
    });
  }

  Future<Result<bool>> confirmCashPayment(String orderId) async {
    return guard(() => _payment.confirmCashPayment(orderId));
  }
}

