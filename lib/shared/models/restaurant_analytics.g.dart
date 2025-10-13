// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestaurantAnalytics _$RestaurantAnalyticsFromJson(Map<String, dynamic> json) =>
    RestaurantAnalytics(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalOrders: (json['total_orders'] as num).toInt(),
      completedOrders: (json['completed_orders'] as num).toInt(),
      cancelledOrders: (json['cancelled_orders'] as num).toInt(),
      rejectedOrders: (json['rejected_orders'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      averageOrderValue: (json['average_order_value'] as num).toDouble(),
      highestOrderValue: (json['highest_order_value'] as num?)?.toDouble(),
      lowestOrderValue: (json['lowest_order_value'] as num?)?.toDouble(),
      newCustomers: (json['new_customers'] as num).toInt(),
      returningCustomers: (json['returning_customers'] as num).toInt(),
      uniqueCustomers: (json['unique_customers'] as num).toInt(),
      averagePrepTime: (json['average_prep_time'] as num?)?.toInt(),
      averageDeliveryTime: (json['average_delivery_time'] as num?)?.toInt(),
      averageResponseTime: (json['average_response_time'] as num?)?.toInt(),
      customerSatisfactionScore: (json['customer_satisfaction_score'] as num?)
          ?.toDouble(),
      totalReviews: (json['total_reviews'] as num?)?.toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RestaurantAnalyticsToJson(
  RestaurantAnalytics instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'date': instance.date.toIso8601String(),
  'total_orders': instance.totalOrders,
  'completed_orders': instance.completedOrders,
  'cancelled_orders': instance.cancelledOrders,
  'rejected_orders': instance.rejectedOrders,
  'total_revenue': instance.totalRevenue,
  'average_order_value': instance.averageOrderValue,
  'highest_order_value': instance.highestOrderValue,
  'lowest_order_value': instance.lowestOrderValue,
  'new_customers': instance.newCustomers,
  'returning_customers': instance.returningCustomers,
  'unique_customers': instance.uniqueCustomers,
  'average_prep_time': instance.averagePrepTime,
  'average_delivery_time': instance.averageDeliveryTime,
  'average_response_time': instance.averageResponseTime,
  'customer_satisfaction_score': instance.customerSatisfactionScore,
  'total_reviews': instance.totalReviews,
  'average_rating': instance.averageRating,
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

DashboardMetrics _$DashboardMetricsFromJson(Map<String, dynamic> json) =>
    DashboardMetrics(
      todayOrders: (json['today_orders'] as num).toInt(),
      todayRevenue: (json['today_revenue'] as num).toDouble(),
      pendingOrders: (json['pending_orders'] as num).toInt(),
      avgOrderValue: (json['avg_order_value'] as num).toDouble(),
      activeMenuItems: (json['active_menu_items'] as num).toInt(),
      restaurantRating: (json['restaurant_rating'] as num).toDouble(),
      totalReviews: (json['total_reviews'] as num).toInt(),
      isAcceptingOrders: json['is_accepting_orders'] as bool,
    );

Map<String, dynamic> _$DashboardMetricsToJson(DashboardMetrics instance) =>
    <String, dynamic>{
      'today_orders': instance.todayOrders,
      'today_revenue': instance.todayRevenue,
      'pending_orders': instance.pendingOrders,
      'avg_order_value': instance.avgOrderValue,
      'active_menu_items': instance.activeMenuItems,
      'restaurant_rating': instance.restaurantRating,
      'total_reviews': instance.totalReviews,
      'is_accepting_orders': instance.isAcceptingOrders,
    };

MenuItemAnalytics _$MenuItemAnalyticsFromJson(Map<String, dynamic> json) =>
    MenuItemAnalytics(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      menuItemId: json['menu_item_id'] as String,
      date: DateTime.parse(json['date'] as String),
      timesOrdered: (json['times_ordered'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      timesViewed: (json['times_viewed'] as num).toInt(),
      conversionRate: (json['conversion_rate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MenuItemAnalyticsToJson(MenuItemAnalytics instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurant_id': instance.restaurantId,
      'menu_item_id': instance.menuItemId,
      'date': instance.date.toIso8601String(),
      'times_ordered': instance.timesOrdered,
      'total_revenue': instance.totalRevenue,
      'times_viewed': instance.timesViewed,
      'conversion_rate': instance.conversionRate,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
