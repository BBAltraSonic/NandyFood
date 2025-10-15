// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalesAnalytics _$SalesAnalyticsFromJson(Map<String, dynamic> json) =>
    SalesAnalytics(
      totalSales: (json['total_sales'] as num).toDouble(),
      totalOrders: (json['total_orders'] as num).toInt(),
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      salesByDay: (json['salesByDay'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      ordersByDay: Map<String, int>.from(json['ordersByDay'] as Map),
    );

Map<String, dynamic> _$SalesAnalyticsToJson(SalesAnalytics instance) =>
    <String, dynamic>{
      'total_sales': instance.totalSales,
      'total_orders': instance.totalOrders,
      'average_order_value': instance.averageOrderValue,
      'salesByDay': instance.salesByDay,
      'ordersByDay': instance.ordersByDay,
    };

RevenueAnalytics _$RevenueAnalyticsFromJson(Map<String, dynamic> json) =>
    RevenueAnalytics(
      grossRevenue: (json['gross_revenue'] as num).toDouble(),
      netRevenue: (json['net_revenue'] as num).toDouble(),
      deliveryFees: (json['delivery_fees'] as num).toDouble(),
      platformFees: (json['platform_fees'] as num).toDouble(),
      refunds: (json['refunds'] as num).toDouble(),
      revenueByMonth: (json['revenueByMonth'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$RevenueAnalyticsToJson(RevenueAnalytics instance) =>
    <String, dynamic>{
      'gross_revenue': instance.grossRevenue,
      'net_revenue': instance.netRevenue,
      'delivery_fees': instance.deliveryFees,
      'platform_fees': instance.platformFees,
      'refunds': instance.refunds,
      'revenueByMonth': instance.revenueByMonth,
    };

CustomerAnalytics _$CustomerAnalyticsFromJson(Map<String, dynamic> json) =>
    CustomerAnalytics(
      totalCustomers: (json['total_customers'] as num).toInt(),
      newCustomers: (json['new_customers'] as num).toInt(),
      returningCustomers: (json['returning_customers'] as num).toInt(),
      repeatRate: (json['repeat_rate'] as num).toDouble(),
      averageOrdersPerCustomer: (json['average_orders_per_customer'] as num)
          .toDouble(),
    );

Map<String, dynamic> _$CustomerAnalyticsToJson(CustomerAnalytics instance) =>
    <String, dynamic>{
      'total_customers': instance.totalCustomers,
      'new_customers': instance.newCustomers,
      'returning_customers': instance.returningCustomers,
      'repeat_rate': instance.repeatRate,
      'average_orders_per_customer': instance.averageOrdersPerCustomer,
    };

MenuItemPerformance _$MenuItemPerformanceFromJson(Map<String, dynamic> json) =>
    MenuItemPerformance(
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String,
      totalOrders: (json['total_orders'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MenuItemPerformanceToJson(
  MenuItemPerformance instance,
) => <String, dynamic>{
  'item_id': instance.itemId,
  'item_name': instance.itemName,
  'total_orders': instance.totalOrders,
  'total_revenue': instance.totalRevenue,
  'average_rating': instance.averageRating,
};

OrderStatusBreakdown _$OrderStatusBreakdownFromJson(
  Map<String, dynamic> json,
) => OrderStatusBreakdown(
  pending: (json['pending'] as num).toInt(),
  confirmed: (json['confirmed'] as num).toInt(),
  preparing: (json['preparing'] as num).toInt(),
  readyForPickup: (json['ready_for_pickup'] as num).toInt(),
  outForDelivery: (json['out_for_delivery'] as num).toInt(),
  delivered: (json['delivered'] as num).toInt(),
  cancelled: (json['cancelled'] as num).toInt(),
);

Map<String, dynamic> _$OrderStatusBreakdownToJson(
  OrderStatusBreakdown instance,
) => <String, dynamic>{
  'pending': instance.pending,
  'confirmed': instance.confirmed,
  'preparing': instance.preparing,
  'ready_for_pickup': instance.readyForPickup,
  'out_for_delivery': instance.outForDelivery,
  'delivered': instance.delivered,
  'cancelled': instance.cancelled,
};

PeakHoursData _$PeakHoursDataFromJson(Map<String, dynamic> json) =>
    PeakHoursData(
      hourOfDay: (json['hour_of_day'] as num).toInt(),
      orderCount: (json['order_count'] as num).toInt(),
      totalSales: (json['total_sales'] as num).toDouble(),
    );

Map<String, dynamic> _$PeakHoursDataToJson(PeakHoursData instance) =>
    <String, dynamic>{
      'hour_of_day': instance.hourOfDay,
      'order_count': instance.orderCount,
      'total_sales': instance.totalSales,
    };
