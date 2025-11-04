// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdvancedRevenueAnalytics _$AdvancedRevenueAnalyticsFromJson(
  Map<String, dynamic> json,
) => AdvancedRevenueAnalytics(
  id: json['id'] as String,
  restaurantId: json['restaurant_id'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  totalRevenue: (json['total_revenue'] as num).toDouble(),
  grossRevenue: (json['gross_revenue'] as num).toDouble(),
  netRevenue: (json['net_revenue'] as num).toDouble(),
  targetRevenue: (json['target_revenue'] as num).toDouble(),
  revenueGrowthRate: (json['revenue_growth_rate'] as num).toDouble(),
  averageOrderValue: (json['average_order_value'] as num).toDouble(),
  revenuePerCustomer: (json['revenue_per_customer'] as num).toDouble(),
  revenueByCategory: (json['revenue_by_category'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, (e as num).toDouble()),
  ),
  revenueByPaymentMethod:
      (json['revenue_by_payment_method'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
  revenueByTimeOfDay: (json['revenue_by_time_of_day'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(k, (e as num).toDouble())),
  revenueByDayOfWeek: (json['revenue_by_day_of_week'] as Map<String, dynamic>)
      .map((k, e) => MapEntry(k, (e as num).toDouble())),
  dailyRevenueData: (json['daily_revenue_data'] as List<dynamic>)
      .map((e) => DailyRevenueData.fromJson(e as Map<String, dynamic>))
      .toList(),
  weeklyRevenueData: (json['weekly_revenue_data'] as List<dynamic>)
      .map((e) => WeeklyRevenueData.fromJson(e as Map<String, dynamic>))
      .toList(),
  monthlyRevenueData: (json['monthly_revenue_data'] as List<dynamic>)
      .map((e) => MonthlyRevenueData.fromJson(e as Map<String, dynamic>))
      .toList(),
  revenueForecast: RevenueForecast.fromJson(
    json['revenue_forecast'] as Map<String, dynamic>,
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AdvancedRevenueAnalyticsToJson(
  AdvancedRevenueAnalytics instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'total_revenue': instance.totalRevenue,
  'gross_revenue': instance.grossRevenue,
  'net_revenue': instance.netRevenue,
  'target_revenue': instance.targetRevenue,
  'revenue_growth_rate': instance.revenueGrowthRate,
  'average_order_value': instance.averageOrderValue,
  'revenue_per_customer': instance.revenuePerCustomer,
  'revenue_by_category': instance.revenueByCategory,
  'revenue_by_payment_method': instance.revenueByPaymentMethod,
  'revenue_by_time_of_day': instance.revenueByTimeOfDay,
  'revenue_by_day_of_week': instance.revenueByDayOfWeek,
  'daily_revenue_data': instance.dailyRevenueData,
  'weekly_revenue_data': instance.weeklyRevenueData,
  'monthly_revenue_data': instance.monthlyRevenueData,
  'revenue_forecast': instance.revenueForecast,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

DailyRevenueData _$DailyRevenueDataFromJson(Map<String, dynamic> json) =>
    DailyRevenueData(
      date: DateTime.parse(json['date'] as String),
      revenue: (json['revenue'] as num).toDouble(),
      orders: (json['orders'] as num).toInt(),
      avgOrderValue: (json['avg_order_value'] as num).toDouble(),
    );

Map<String, dynamic> _$DailyRevenueDataToJson(DailyRevenueData instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'revenue': instance.revenue,
      'orders': instance.orders,
      'avg_order_value': instance.avgOrderValue,
    };

WeeklyRevenueData _$WeeklyRevenueDataFromJson(Map<String, dynamic> json) =>
    WeeklyRevenueData(
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      revenue: (json['revenue'] as num).toDouble(),
      orders: (json['orders'] as num).toInt(),
      weekNumber: (json['week_number'] as num).toInt(),
      year: (json['year'] as num).toInt(),
    );

Map<String, dynamic> _$WeeklyRevenueDataToJson(WeeklyRevenueData instance) =>
    <String, dynamic>{
      'week_start': instance.weekStart.toIso8601String(),
      'week_end': instance.weekEnd.toIso8601String(),
      'revenue': instance.revenue,
      'orders': instance.orders,
      'week_number': instance.weekNumber,
      'year': instance.year,
    };

MonthlyRevenueData _$MonthlyRevenueDataFromJson(Map<String, dynamic> json) =>
    MonthlyRevenueData(
      monthStart: DateTime.parse(json['month_start'] as String),
      monthEnd: DateTime.parse(json['month_end'] as String),
      revenue: (json['revenue'] as num).toDouble(),
      orders: (json['orders'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
    );

Map<String, dynamic> _$MonthlyRevenueDataToJson(MonthlyRevenueData instance) =>
    <String, dynamic>{
      'month_start': instance.monthStart.toIso8601String(),
      'month_end': instance.monthEnd.toIso8601String(),
      'revenue': instance.revenue,
      'orders': instance.orders,
      'month': instance.month,
      'year': instance.year,
    };

RevenueForecast _$RevenueForecastFromJson(Map<String, dynamic> json) =>
    RevenueForecast(
      next7Days: (json['next_7_days'] as num).toDouble(),
      next30Days: (json['next_30_days'] as num).toDouble(),
      next90Days: (json['next_90_days'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      forecastModel: json['forecast_model'] as String,
      seasonalFactors: (json['seasonal_factors'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$RevenueForecastToJson(RevenueForecast instance) =>
    <String, dynamic>{
      'next_7_days': instance.next7Days,
      'next_30_days': instance.next30Days,
      'next_90_days': instance.next90Days,
      'confidence_score': instance.confidenceScore,
      'forecast_model': instance.forecastModel,
      'seasonal_factors': instance.seasonalFactors,
    };

AdvancedCustomerAnalytics _$AdvancedCustomerAnalyticsFromJson(
  Map<String, dynamic> json,
) => AdvancedCustomerAnalytics(
  id: json['id'] as String,
  restaurantId: json['restaurant_id'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  totalCustomers: (json['total_customers'] as num).toInt(),
  newCustomers: (json['new_customers'] as num).toInt(),
  returningCustomers: (json['returning_customers'] as num).toInt(),
  activeCustomers: (json['active_customers'] as num).toInt(),
  customerRetentionRate: (json['customer_retention_rate'] as num).toDouble(),
  customerAcquisitionRate: (json['customer_acquisition_rate'] as num)
      .toDouble(),
  churnRate: (json['churn_rate'] as num).toDouble(),
  customerSegments: (json['customer_segments'] as List<dynamic>)
      .map((e) => CustomerSegment.fromJson(e as Map<String, dynamic>))
      .toList(),
  customerLifetimeValue: (json['customer_lifetime_value'] as num).toDouble(),
  avgOrdersPerCustomer: (json['avg_orders_per_customer'] as num).toDouble(),
  avgDaysBetweenOrders: (json['avg_days_between_orders'] as num).toDouble(),
  customerSatisfactionScore: (json['customer_satisfaction_score'] as num)
      .toDouble(),
  ageDistribution: Map<String, int>.from(json['age_distribution'] as Map),
  locationDistribution: Map<String, int>.from(
    json['location_distribution'] as Map,
  ),
  conversionFunnel: ConversionFunnel.fromJson(
    json['conversion_funnel'] as Map<String, dynamic>,
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AdvancedCustomerAnalyticsToJson(
  AdvancedCustomerAnalytics instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'total_customers': instance.totalCustomers,
  'new_customers': instance.newCustomers,
  'returning_customers': instance.returningCustomers,
  'active_customers': instance.activeCustomers,
  'customer_retention_rate': instance.customerRetentionRate,
  'customer_acquisition_rate': instance.customerAcquisitionRate,
  'churn_rate': instance.churnRate,
  'customer_segments': instance.customerSegments,
  'customer_lifetime_value': instance.customerLifetimeValue,
  'avg_orders_per_customer': instance.avgOrdersPerCustomer,
  'avg_days_between_orders': instance.avgDaysBetweenOrders,
  'customer_satisfaction_score': instance.customerSatisfactionScore,
  'age_distribution': instance.ageDistribution,
  'location_distribution': instance.locationDistribution,
  'conversion_funnel': instance.conversionFunnel,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

CustomerSegment _$CustomerSegmentFromJson(Map<String, dynamic> json) =>
    CustomerSegment(
      name: json['name'] as String,
      type: json['type'] as String,
      count: (json['count'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
      avgOrderValue: (json['avg_order_value'] as num).toDouble(),
      orderFrequency: (json['order_frequency'] as num).toDouble(),
      satisfactionScore: (json['satisfaction_score'] as num).toDouble(),
      characteristics: (json['characteristics'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CustomerSegmentToJson(CustomerSegment instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'count': instance.count,
      'percentage': instance.percentage,
      'avg_order_value': instance.avgOrderValue,
      'order_frequency': instance.orderFrequency,
      'satisfaction_score': instance.satisfactionScore,
      'characteristics': instance.characteristics,
    };

ConversionFunnel _$ConversionFunnelFromJson(Map<String, dynamic> json) =>
    ConversionFunnel(
      totalVisitors: (json['total_visitors'] as num).toInt(),
      menuViewers: (json['menu_viewers'] as num).toInt(),
      cartAdders: (json['cart_adders'] as num).toInt(),
      checkoutStarters: (json['checkout_starters'] as num).toInt(),
      orderCompleters: (json['order_completers'] as num).toInt(),
    );

Map<String, dynamic> _$ConversionFunnelToJson(ConversionFunnel instance) =>
    <String, dynamic>{
      'total_visitors': instance.totalVisitors,
      'menu_viewers': instance.menuViewers,
      'cart_adders': instance.cartAdders,
      'checkout_starters': instance.checkoutStarters,
      'order_completers': instance.orderCompleters,
    };

AdvancedMenuAnalytics _$AdvancedMenuAnalyticsFromJson(
  Map<String, dynamic> json,
) => AdvancedMenuAnalytics(
  id: json['id'] as String,
  restaurantId: json['restaurant_id'] as String,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  totalMenuItems: (json['total_menu_items'] as num).toInt(),
  activeMenuItems: (json['active_menu_items'] as num).toInt(),
  avgItemPrice: (json['avg_item_price'] as num).toDouble(),
  menuRevenue: (json['menu_revenue'] as num).toDouble(),
  topPerformingItems: (json['top_performing_items'] as List<dynamic>)
      .map((e) => MenuItemPerformance.fromJson(e as Map<String, dynamic>))
      .toList(),
  underperformingItems: (json['underperforming_items'] as List<dynamic>)
      .map((e) => MenuItemPerformance.fromJson(e as Map<String, dynamic>))
      .toList(),
  trendingItems: (json['trending_items'] as List<dynamic>)
      .map((e) => MenuItemPerformance.fromJson(e as Map<String, dynamic>))
      .toList(),
  categoryPerformance: (json['category_performance'] as Map<String, dynamic>)
      .map(
        (k, e) => MapEntry(
          k,
          CategoryPerformance.fromJson(e as Map<String, dynamic>),
        ),
      ),
  optimizationRecommendations:
      (json['optimization_recommendations'] as List<dynamic>)
          .map(
            (e) => MenuOptimizationRecommendation.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AdvancedMenuAnalyticsToJson(
  AdvancedMenuAnalytics instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'total_menu_items': instance.totalMenuItems,
  'active_menu_items': instance.activeMenuItems,
  'avg_item_price': instance.avgItemPrice,
  'menu_revenue': instance.menuRevenue,
  'top_performing_items': instance.topPerformingItems,
  'underperforming_items': instance.underperformingItems,
  'trending_items': instance.trendingItems,
  'category_performance': instance.categoryPerformance,
  'optimization_recommendations': instance.optimizationRecommendations,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

MenuItemPerformance _$MenuItemPerformanceFromJson(Map<String, dynamic> json) =>
    MenuItemPerformance(
      id: json['id'] as String,
      itemName: json['item_name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      totalOrders: (json['total_orders'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      popularityScore: (json['popularity_score'] as num).toDouble(),
      profitMargin: (json['profit_margin'] as num).toDouble(),
      growthRate: (json['growth_rate'] as num).toDouble(),
      customerRating: (json['customer_rating'] as num).toDouble(),
      timesViewed: (json['times_viewed'] as num).toInt(),
      conversionRate: (json['conversion_rate'] as num).toDouble(),
      trendIndicator: json['trend_indicator'] as String,
    );

Map<String, dynamic> _$MenuItemPerformanceToJson(
  MenuItemPerformance instance,
) => <String, dynamic>{
  'id': instance.id,
  'item_name': instance.itemName,
  'category': instance.category,
  'price': instance.price,
  'total_orders': instance.totalOrders,
  'total_revenue': instance.totalRevenue,
  'popularity_score': instance.popularityScore,
  'profit_margin': instance.profitMargin,
  'growth_rate': instance.growthRate,
  'customer_rating': instance.customerRating,
  'times_viewed': instance.timesViewed,
  'conversion_rate': instance.conversionRate,
  'trend_indicator': instance.trendIndicator,
};

CategoryPerformance _$CategoryPerformanceFromJson(Map<String, dynamic> json) =>
    CategoryPerformance(
      name: json['name'] as String,
      totalItems: (json['total_items'] as num).toInt(),
      totalOrders: (json['total_orders'] as num).toInt(),
      totalRevenue: (json['total_revenue'] as num).toDouble(),
      avgItemPrice: (json['avg_item_price'] as num).toDouble(),
      profitMargin: (json['profit_margin'] as num).toDouble(),
      categoryGrowthRate: (json['category_growth_rate'] as num).toDouble(),
      marketShare: (json['market_share'] as num).toDouble(),
    );

Map<String, dynamic> _$CategoryPerformanceToJson(
  CategoryPerformance instance,
) => <String, dynamic>{
  'name': instance.name,
  'total_items': instance.totalItems,
  'total_orders': instance.totalOrders,
  'total_revenue': instance.totalRevenue,
  'avg_item_price': instance.avgItemPrice,
  'profit_margin': instance.profitMargin,
  'category_growth_rate': instance.categoryGrowthRate,
  'market_share': instance.marketShare,
};

MenuOptimizationRecommendation _$MenuOptimizationRecommendationFromJson(
  Map<String, dynamic> json,
) => MenuOptimizationRecommendation(
  type: json['type'] as String,
  menuItemId: json['menu_item_id'] as String,
  itemName: json['item_name'] as String,
  recommendation: json['recommendation'] as String,
  reasoning: json['reasoning'] as String,
  potentialImpact: json['potential_impact'] as String,
  priority: json['priority'] as String,
  estimatedRevenueChange: (json['estimated_revenue_change'] as num).toDouble(),
);

Map<String, dynamic> _$MenuOptimizationRecommendationToJson(
  MenuOptimizationRecommendation instance,
) => <String, dynamic>{
  'type': instance.type,
  'menu_item_id': instance.menuItemId,
  'item_name': instance.itemName,
  'recommendation': instance.recommendation,
  'reasoning': instance.reasoning,
  'potential_impact': instance.potentialImpact,
  'priority': instance.priority,
  'estimated_revenue_change': instance.estimatedRevenueChange,
};

RealTimeMetrics _$RealTimeMetricsFromJson(Map<String, dynamic> json) =>
    RealTimeMetrics(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      metricTimestamp: DateTime.parse(json['metric_timestamp'] as String),
      activeOrders: (json['active_orders'] as num).toInt(),
      pendingOrders: (json['pending_orders'] as num).toInt(),
      preparingOrders: (json['preparing_orders'] as num).toInt(),
      readyOrders: (json['ready_orders'] as num).toInt(),
      currentDayRevenue: (json['current_day_revenue'] as num).toDouble(),
      currentHourRevenue: (json['current_hour_revenue'] as num).toDouble(),
      currentDayOrders: (json['current_day_orders'] as num).toInt(),
      currentHourOrders: (json['current_hour_orders'] as num).toInt(),
      currentAvgPrepTime: (json['current_avg_prep_time'] as num).toInt(),
      currentAvgResponseTime: (json['current_avg_response_time'] as num)
          .toInt(),
      staffAvailable: (json['staff_available'] as num).toInt(),
      queueLength: (json['queue_length'] as num).toInt(),
      isAcceptingOrders: json['is_accepting_orders'] as bool,
      kitchenCapacityUtilization: (json['kitchen_capacity_utilization'] as num)
          .toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RealTimeMetricsToJson(RealTimeMetrics instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurant_id': instance.restaurantId,
      'metric_timestamp': instance.metricTimestamp.toIso8601String(),
      'active_orders': instance.activeOrders,
      'pending_orders': instance.pendingOrders,
      'preparing_orders': instance.preparingOrders,
      'ready_orders': instance.readyOrders,
      'current_day_revenue': instance.currentDayRevenue,
      'current_hour_revenue': instance.currentHourRevenue,
      'current_day_orders': instance.currentDayOrders,
      'current_hour_orders': instance.currentHourOrders,
      'current_avg_prep_time': instance.currentAvgPrepTime,
      'current_avg_response_time': instance.currentAvgResponseTime,
      'staff_available': instance.staffAvailable,
      'queue_length': instance.queueLength,
      'is_accepting_orders': instance.isAcceptingOrders,
      'kitchen_capacity_utilization': instance.kitchenCapacityUtilization,
      'created_at': instance.createdAt.toIso8601String(),
    };

AnalyticsReport _$AnalyticsReportFromJson(Map<String, dynamic> json) =>
    AnalyticsReport(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      reportName: json['report_name'] as String,
      reportType: json['report_type'] as String,
      dateRangeStart: DateTime.parse(json['date_range_start'] as String),
      dateRangeEnd: DateTime.parse(json['date_range_end'] as String),
      reportData: json['report_data'] as Map<String, dynamic>,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      fileUrl: json['file_url'] as String?,
      fileFormat: json['file_format'] as String?,
      isScheduled: json['is_scheduled'] as bool,
      scheduleFrequency: json['schedule_frequency'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$AnalyticsReportToJson(AnalyticsReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'restaurant_id': instance.restaurantId,
      'report_name': instance.reportName,
      'report_type': instance.reportType,
      'date_range_start': instance.dateRangeStart.toIso8601String(),
      'date_range_end': instance.dateRangeEnd.toIso8601String(),
      'report_data': instance.reportData,
      'generated_at': instance.generatedAt.toIso8601String(),
      'file_url': instance.fileUrl,
      'file_format': instance.fileFormat,
      'is_scheduled': instance.isScheduled,
      'schedule_frequency': instance.scheduleFrequency,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

PredictiveAnalytics _$PredictiveAnalyticsFromJson(Map<String, dynamic> json) =>
    PredictiveAnalytics(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      predictionDate: DateTime.parse(json['prediction_date'] as String),
      predictionType: json['prediction_type'] as String,
      predictionHorizon: (json['prediction_horizon'] as num).toInt(),
      predictedValue: (json['predicted_value'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num).toDouble(),
      predictionModel: json['prediction_model'] as String,
      actualValue: (json['actual_value'] as num?)?.toDouble(),
      accuracyScore: (json['accuracy_score'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PredictiveAnalyticsToJson(
  PredictiveAnalytics instance,
) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'prediction_date': instance.predictionDate.toIso8601String(),
  'prediction_type': instance.predictionType,
  'prediction_horizon': instance.predictionHorizon,
  'predicted_value': instance.predictedValue,
  'confidence_score': instance.confidenceScore,
  'prediction_model': instance.predictionModel,
  'actual_value': instance.actualValue,
  'accuracy_score': instance.accuracyScore,
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
