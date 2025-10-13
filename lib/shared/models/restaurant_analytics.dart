import 'package:json_annotation/json_annotation.dart';

part 'restaurant_analytics.g.dart';

@JsonSerializable()
class RestaurantAnalytics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final DateTime date;
  
  // Order metrics
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'completed_orders')
  final int completedOrders;
  @JsonKey(name: 'cancelled_orders')
  final int cancelledOrders;
  @JsonKey(name: 'rejected_orders')
  final int rejectedOrders;
  
  // Revenue metrics
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'average_order_value')
  final double averageOrderValue;
  @JsonKey(name: 'highest_order_value')
  final double? highestOrderValue;
  @JsonKey(name: 'lowest_order_value')
  final double? lowestOrderValue;
  
  // Customer metrics
  @JsonKey(name: 'new_customers')
  final int newCustomers;
  @JsonKey(name: 'returning_customers')
  final int returningCustomers;
  @JsonKey(name: 'unique_customers')
  final int uniqueCustomers;
  
  // Performance metrics
  @JsonKey(name: 'average_prep_time')
  final int? averagePrepTime;
  @JsonKey(name: 'average_delivery_time')
  final int? averageDeliveryTime;
  @JsonKey(name: 'average_response_time')
  final int? averageResponseTime;
  
  // Satisfaction metrics
  @JsonKey(name: 'customer_satisfaction_score')
  final double? customerSatisfactionScore;
  @JsonKey(name: 'total_reviews')
  final int? totalReviews;
  @JsonKey(name: 'average_rating')
  final double? averageRating;
  
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  RestaurantAnalytics({
    required this.id,
    required this.restaurantId,
    required this.date,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.rejectedOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    this.highestOrderValue,
    this.lowestOrderValue,
    required this.newCustomers,
    required this.returningCustomers,
    required this.uniqueCustomers,
    this.averagePrepTime,
    this.averageDeliveryTime,
    this.averageResponseTime,
    this.customerSatisfactionScore,
    this.totalReviews,
    this.averageRating,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantAnalytics.fromJson(Map<String, dynamic> json) =>
      _$RestaurantAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantAnalyticsToJson(this);

  /// Helper getters
  double get completionRate =>
      totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0;

  double get cancellationRate =>
      totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0;

  double get rejectionRate =>
      totalOrders > 0 ? (rejectedOrders / totalOrders) * 100 : 0;

  double get customerRetentionRate =>
      uniqueCustomers > 0 ? (returningCustomers / uniqueCustomers) * 100 : 0;
}

@JsonSerializable()
class DashboardMetrics {
  @JsonKey(name: 'today_orders')
  final int todayOrders;
  @JsonKey(name: 'today_revenue')
  final double todayRevenue;
  @JsonKey(name: 'pending_orders')
  final int pendingOrders;
  @JsonKey(name: 'avg_order_value')
  final double avgOrderValue;
  @JsonKey(name: 'active_menu_items')
  final int activeMenuItems;
  @JsonKey(name: 'restaurant_rating')
  final double restaurantRating;
  @JsonKey(name: 'total_reviews')
  final int totalReviews;
  @JsonKey(name: 'is_accepting_orders')
  final bool isAcceptingOrders;

  DashboardMetrics({
    required this.todayOrders,
    required this.todayRevenue,
    required this.pendingOrders,
    required this.avgOrderValue,
    required this.activeMenuItems,
    required this.restaurantRating,
    required this.totalReviews,
    required this.isAcceptingOrders,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) =>
      _$DashboardMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardMetricsToJson(this);

  /// Helper getters
  bool get hasOrders => todayOrders > 0;
  bool get hasPendingOrders => pendingOrders > 0;
  String get ratingDisplay => restaurantRating.toStringAsFixed(1);
}

@JsonSerializable()
class MenuItemAnalytics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'menu_item_id')
  final String menuItemId;
  final DateTime date;
  @JsonKey(name: 'times_ordered')
  final int timesOrdered;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'times_viewed')
  final int timesViewed;
  @JsonKey(name: 'conversion_rate')
  final double? conversionRate;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MenuItemAnalytics({
    required this.id,
    required this.restaurantId,
    required this.menuItemId,
    required this.date,
    required this.timesOrdered,
    required this.totalRevenue,
    required this.timesViewed,
    this.conversionRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemAnalytics.fromJson(Map<String, dynamic> json) =>
      _$MenuItemAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemAnalyticsToJson(this);

  double get averageItemPrice =>
      timesOrdered > 0 ? totalRevenue / timesOrdered : 0;
}
