import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/restaurant_analytics.dart';

class OwnerRepository with RepositoryGuard {
  final RestaurantManagementService _svc;
  OwnerRepository({RestaurantManagementService? service}) : _svc = service ?? RestaurantManagementService();

  // Restaurant
  Future<Result<Restaurant>> getRestaurant(String restaurantId) async {
    return guard(() => _svc.getRestaurant(restaurantId));
  }

  Future<Result<bool>> updateRestaurant(String restaurantId, Map<String, dynamic> updates) async {
    return guard(() async {
      await _svc.updateRestaurant(restaurantId, updates);
      return true;
    });
  }

  Future<Result<bool>> updateOperatingHours(String restaurantId, Map<String, dynamic> hours) async {
    return guard(() async {
      await _svc.updateOperatingHours(restaurantId, hours);
      return true;
    });
  }

  Future<Result<bool>> toggleAcceptingOrders(String restaurantId, bool isAccepting) async {
    return guard(() async {
      await _svc.toggleAcceptingOrders(restaurantId, isAccepting);
      return true;
    });
  }

  // Menu
  Future<Result<List<MenuItem>>> getMenuItems(String restaurantId) async {
    return guard(() => _svc.getMenuItems(restaurantId));
  }

  Future<Result<MenuItem>> createMenuItem(MenuItem item) async {
    return guard(() => _svc.createMenuItem(item));
  }

  Future<Result<bool>> updateMenuItem(String itemId, Map<String, dynamic> updates) async {
    return guard(() async {
      await _svc.updateMenuItem(itemId, updates);
      return true;
    });
  }

  Future<Result<bool>> deleteMenuItem(String itemId) async {
    return guard(() async {
      await _svc.deleteMenuItem(itemId);
      return true;
    });
  }

  Future<Result<bool>> toggleMenuItemAvailability(String itemId, bool isAvailable) async {
    return guard(() async {
      await _svc.toggleMenuItemAvailability(itemId, isAvailable);
      return true;
    });
  }

  // Orders
  Future<Result<List<Order>>> getRestaurantOrders(
    String restaurantId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return guard(() => _svc.getRestaurantOrders(restaurantId, status: status, startDate: startDate, endDate: endDate));
  }

  Future<Result<bool>> updateOrderStatus(String orderId, String newStatus) async {
    return guard(() async {
      await _svc.updateOrderStatus(orderId, newStatus);
      return true;
    });
  }

  Future<Result<bool>> acceptOrder(String orderId, int estimatedPrepTimeMinutes) async {
    return guard(() async {
      await _svc.acceptOrder(orderId, estimatedPrepTimeMinutes);
      return true;
    });
  }

  Future<Result<bool>> rejectOrder(String orderId, String reason) async {
    return guard(() async {
      await _svc.rejectOrder(orderId, reason);
      return true;
    });
  }

  // Analytics
  Future<Result<List<RestaurantAnalytics>>> getAnalytics(String restaurantId, DateTime startDate, DateTime endDate) async {
    return guard(() => _svc.getAnalytics(restaurantId, startDate, endDate));
  }

  Future<Result<DashboardMetrics>> getDashboardMetrics(String restaurantId) async {
    return guard(() => _svc.getDashboardMetrics(restaurantId));
  }

  Future<Result<bool>> calculateDailyAnalytics(String restaurantId, [DateTime? date]) async {
    return guard(() async {
      await _svc.calculateDailyAnalytics(restaurantId, date);
      return true;
    });
  }
}

