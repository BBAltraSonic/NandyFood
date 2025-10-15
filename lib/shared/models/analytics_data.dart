import 'package:json_annotation/json_annotation.dart';

part 'analytics_data.g.dart';

/// Sales analytics data
@JsonSerializable()
class SalesAnalytics {
  @JsonKey(name: 'total_sales')
  final double totalSales;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'average_order_value')
  final double averageOrderValue;
  final Map<String, double> salesByDay;
  final Map<String, int> ordersByDay;

  SalesAnalytics({
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.salesByDay,
    required this.ordersByDay,
  });

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) =>
      _$SalesAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$SalesAnalyticsToJson(this);
}

/// Revenue analytics data
@JsonSerializable()
class RevenueAnalytics {
  @JsonKey(name: 'gross_revenue')
  final double grossRevenue;
  @JsonKey(name: 'net_revenue')
  final double netRevenue;
  @JsonKey(name: 'delivery_fees')
  final double deliveryFees;
  @JsonKey(name: 'platform_fees')
  final double platformFees;
  @JsonKey(name: 'refunds')
  final double refunds;
  final Map<String, double> revenueByMonth;

  RevenueAnalytics({
    required this.grossRevenue,
    required this.netRevenue,
    required this.deliveryFees,
    required this.platformFees,
    required this.refunds,
    required this.revenueByMonth,
  });

  factory RevenueAnalytics.fromJson(Map<String, dynamic> json) =>
      _$RevenueAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$RevenueAnalyticsToJson(this);
}

/// Customer analytics data
@JsonSerializable()
class CustomerAnalytics {
  @JsonKey(name: 'total_customers')
  final int totalCustomers;
  @JsonKey(name: 'new_customers')
  final int newCustomers;
  @JsonKey(name: 'returning_customers')
  final int returningCustomers;
  @JsonKey(name: 'repeat_rate')
  final double repeatRate;
  @JsonKey(name: 'average_orders_per_customer')
  final double averageOrdersPerCustomer;

  CustomerAnalytics({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.repeatRate,
    required this.averageOrdersPerCustomer,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) =>
      _$CustomerAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerAnalyticsToJson(this);
}

/// Menu item performance data
@JsonSerializable()
class MenuItemPerformance {
  @JsonKey(name: 'item_id')
  final String itemId;
  @JsonKey(name: 'item_name')
  final String itemName;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'average_rating')
  final double? averageRating;

  MenuItemPerformance({
    required this.itemId,
    required this.itemName,
    required this.totalOrders,
    required this.totalRevenue,
    this.averageRating,
  });

  factory MenuItemPerformance.fromJson(Map<String, dynamic> json) =>
      _$MenuItemPerformanceFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemPerformanceToJson(this);
}

/// Order status breakdown
@JsonSerializable()
class OrderStatusBreakdown {
  final int pending;
  final int confirmed;
  final int preparing;
  @JsonKey(name: 'ready_for_pickup')
  final int readyForPickup;
  @JsonKey(name: 'out_for_delivery')
  final int outForDelivery;
  final int delivered;
  final int cancelled;

  OrderStatusBreakdown({
    required this.pending,
    required this.confirmed,
    required this.preparing,
    required this.readyForPickup,
    required this.outForDelivery,
    required this.delivered,
    required this.cancelled,
  });

  factory OrderStatusBreakdown.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$OrderStatusBreakdownToJson(this);

  int get total =>
      pending +
      confirmed +
      preparing +
      readyForPickup +
      outForDelivery +
      delivered +
      cancelled;
}

/// Peak hours data
@JsonSerializable()
class PeakHoursData {
  @JsonKey(name: 'hour_of_day')
  final int hourOfDay;
  @JsonKey(name: 'order_count')
  final int orderCount;
  @JsonKey(name: 'total_sales')
  final double totalSales;

  PeakHoursData({
    required this.hourOfDay,
    required this.orderCount,
    required this.totalSales,
  });

  factory PeakHoursData.fromJson(Map<String, dynamic> json) =>
      _$PeakHoursDataFromJson(json);

  Map<String, dynamic> toJson() => _$PeakHoursDataToJson(this);
}

/// Comprehensive analytics dashboard data
class DashboardAnalytics {
  final SalesAnalytics salesAnalytics;
  final RevenueAnalytics revenueAnalytics;
  final CustomerAnalytics customerAnalytics;
  final List<MenuItemPerformance> topItems;
  final OrderStatusBreakdown orderStatusBreakdown;
  final List<PeakHoursData> peakHours;

  DashboardAnalytics({
    required this.salesAnalytics,
    required this.revenueAnalytics,
    required this.customerAnalytics,
    required this.topItems,
    required this.orderStatusBreakdown,
    required this.peakHours,
  });
}
