import 'package:json_annotation/json_annotation.dart';

part 'enhanced_analytics.g.dart';

/// Advanced Revenue Analytics Model
@JsonSerializable()
class AdvancedRevenueAnalytics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final DateTime startDate;
  final DateTime endDate;

  // Revenue metrics
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'gross_revenue')
  final double grossRevenue;
  @JsonKey(name: 'net_revenue')
  final double netRevenue;
  @JsonKey(name: 'target_revenue')
  final double targetRevenue;
  @JsonKey(name: 'revenue_growth_rate')
  final double revenueGrowthRate;
  @JsonKey(name: 'average_order_value')
  final double averageOrderValue;
  @JsonKey(name: 'revenue_per_customer')
  final double revenuePerCustomer;

  // Revenue breakdown
  @JsonKey(name: 'revenue_by_category')
  final Map<String, double> revenueByCategory;
  @JsonKey(name: 'revenue_by_payment_method')
  final Map<String, double> revenueByPaymentMethod;
  @JsonKey(name: 'revenue_by_time_of_day')
  final Map<String, double> revenueByTimeOfDay;
  @JsonKey(name: 'revenue_by_day_of_week')
  final Map<String, double> revenueByDayOfWeek;

  // Revenue trends
  @JsonKey(name: 'daily_revenue_data')
  final List<DailyRevenueData> dailyRevenueData;
  @JsonKey(name: 'weekly_revenue_data')
  final List<WeeklyRevenueData> weeklyRevenueData;
  @JsonKey(name: 'monthly_revenue_data')
  final List<MonthlyRevenueData> monthlyRevenueData;

  // Forecasting
  @JsonKey(name: 'revenue_forecast')
  final RevenueForecast revenueForecast;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  AdvancedRevenueAnalytics({
    required this.id,
    required this.restaurantId,
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.grossRevenue,
    required this.netRevenue,
    required this.targetRevenue,
    required this.revenueGrowthRate,
    required this.averageOrderValue,
    required this.revenuePerCustomer,
    required this.revenueByCategory,
    required this.revenueByPaymentMethod,
    required this.revenueByTimeOfDay,
    required this.revenueByDayOfWeek,
    required this.dailyRevenueData,
    required this.weeklyRevenueData,
    required this.monthlyRevenueData,
    required this.revenueForecast,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdvancedRevenueAnalytics.fromJson(Map<String, dynamic> json) =>
      _$AdvancedRevenueAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$AdvancedRevenueAnalyticsToJson(this);

  // Helper getters
  double get targetAchievementRate => targetRevenue > 0 ? (netRevenue / targetRevenue) * 100 : 0;
  bool get isOnTrack => targetAchievementRate >= 80;
  double get averageDailyRevenue => totalRevenue / endDate.difference(startDate).inDays;
}

@JsonSerializable()
class DailyRevenueData {
  final DateTime date;
  final double revenue;
  final int orders;
  @JsonKey(name: 'avg_order_value')
  final double avgOrderValue;

  DailyRevenueData({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.avgOrderValue,
  });

  factory DailyRevenueData.fromJson(Map<String, dynamic> json) =>
      _$DailyRevenueDataFromJson(json);

  Map<String, dynamic> toJson() => _$DailyRevenueDataToJson(json);
}

@JsonSerializable()
class WeeklyRevenueData {
  @JsonKey(name: 'week_start')
  final DateTime weekStart;
  @JsonKey(name: 'week_end')
  final DateTime weekEnd;
  final double revenue;
  final int orders;
  @JsonKey(name: 'week_number')
  final int weekNumber;
  final int year;

  WeeklyRevenueData({
    required this.weekStart,
    required this.weekEnd,
    required this.revenue,
    required this.orders,
    required this.weekNumber,
    required this.year,
  });

  factory WeeklyRevenueData.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRevenueDataFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyRevenueDataToJson(json);
}

@JsonSerializable()
class MonthlyRevenueData {
  @JsonKey(name: 'month_start')
  final DateTime monthStart;
  @JsonKey(name: 'month_end')
  final DateTime monthEnd;
  final double revenue;
  final int orders;
  final int month;
  final int year;

  MonthlyRevenueData({
    required this.monthStart,
    required this.monthEnd,
    required this.revenue,
    required this.orders,
    required this.month,
    required this.year,
  });

  factory MonthlyRevenueData.fromJson(Map<String, dynamic> json) =>
      _$MonthlyRevenueDataFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyRevenueDataToJson(json);
}

@JsonSerializable()
class RevenueForecast {
  @JsonKey(name: 'next_7_days')
  final double next7Days;
  @JsonKey(name: 'next_30_days')
  final double next30Days;
  @JsonKey(name: 'next_90_days')
  final double next90Days;
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;
  @JsonKey(name: 'forecast_model')
  final String forecastModel;
  @JsonKey(name: 'seasonal_factors')
  final Map<String, double> seasonalFactors;

  RevenueForecast({
    required this.next7Days,
    required this.next30Days,
    required this.next90Days,
    required this.confidenceScore,
    required this.forecastModel,
    required this.seasonalFactors,
  });

  factory RevenueForecast.fromJson(Map<String, dynamic> json) =>
      _$RevenueForecastFromJson(json);

  Map<String, dynamic> toJson() => _$RevenueForecastToJson(json);
}

/// Advanced Customer Analytics Model
@JsonSerializable()
class AdvancedCustomerAnalytics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final DateTime startDate;
  final DateTime endDate;

  // Customer metrics
  @JsonKey(name: 'total_customers')
  final int totalCustomers;
  @JsonKey(name: 'new_customers')
  final int newCustomers;
  @JsonKey(name: 'returning_customers')
  final int returningCustomers;
  @JsonKey(name: 'active_customers')
  final int activeCustomers;
  @JsonKey(name: 'customer_retention_rate')
  final double customerRetentionRate;
  @JsonKey(name: 'customer_acquisition_rate')
  final double customerAcquisitionRate;
  @JsonKey(name: 'churn_rate')
  final double churnRate;

  // Customer segmentation
  @JsonKey(name: 'customer_segments')
  final List<CustomerSegment> customerSegments;
  @JsonKey(name: 'customer_lifetime_value')
  final double customerLifetimeValue;

  // Behavioral analytics
  @JsonKey(name: 'avg_orders_per_customer')
  final double avgOrdersPerCustomer;
  @JsonKey(name: 'avg_days_between_orders')
  final double avgDaysBetweenOrders;
  @JsonKey(name: 'customer_satisfaction_score')
  final double customerSatisfactionScore;

  // Demographics
  @JsonKey(name: 'age_distribution')
  final Map<String, int> ageDistribution;
  @JsonKey(name: 'location_distribution')
  final Map<String, int> locationDistribution;

  // Journey analytics
  @JsonKey(name: 'conversion_funnel')
  final ConversionFunnel conversionFunnel;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  AdvancedCustomerAnalytics({
    required this.id,
    required this.restaurantId,
    required this.startDate,
    required this.endDate,
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.activeCustomers,
    required this.customerRetentionRate,
    required this.customerAcquisitionRate,
    required this.churnRate,
    required this.customerSegments,
    required this.customerLifetimeValue,
    required this.avgOrdersPerCustomer,
    required this.avgDaysBetweenOrders,
    required this.customerSatisfactionScore,
    required this.ageDistribution,
    required this.locationDistribution,
    required this.conversionFunnel,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdvancedCustomerAnalytics.fromJson(Map<String, dynamic> json) =>
      _$AdvancedCustomerAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$AdvancedCustomerAnalyticsToJson(this);

  // Helper getters
  double get repeatCustomerRate => totalCustomers > 0 ? (returningCustomers / totalCustomers) * 100 : 0;
  bool get hasGoodRetention => customerRetentionRate >= 60;
  bool get hasLowChurn => churnRate <= 20;
}

@JsonSerializable()
class CustomerSegment {
  final String name;
  final String type;
  final int count;
  @JsonKey(name: 'percentage')
  final double percentage;
  @JsonKey(name: 'avg_order_value')
  final double avgOrderValue;
  @JsonKey(name: 'order_frequency')
  final double orderFrequency;
  @JsonKey(name: 'satisfaction_score')
  final double satisfactionScore;
  final List<String> characteristics;

  CustomerSegment({
    required this.name,
    required this.type,
    required this.count,
    required this.percentage,
    required this.avgOrderValue,
    required this.orderFrequency,
    required this.satisfactionScore,
    required this.characteristics,
  });

  factory CustomerSegment.fromJson(Map<String, dynamic> json) =>
      _$CustomerSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerSegmentToJson(json);
}

@JsonSerializable()
class ConversionFunnel {
  @JsonKey(name: 'total_visitors')
  final int totalVisitors;
  @JsonKey(name: 'menu_viewers')
  final int menuViewers;
  @JsonKey(name: 'cart_adders')
  final int cartAdders;
  @JsonKey(name: 'checkout_starters')
  final int checkoutStarters;
  @JsonKey(name: 'order_completers')
  final int orderCompleters;

  ConversionFunnel({
    required this.totalVisitors,
    required this.menuViewers,
    required this.cartAdders,
    required this.checkoutStarters,
    required this.orderCompleters,
  });

  factory ConversionFunnel.fromJson(Map<String, dynamic> json) =>
      _$ConversionFunnelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversionFunnelToJson(json);

  // Helper getters
  double get menuViewRate => totalVisitors > 0 ? (menuViewers / totalVisitors) * 100 : 0;
  double get cartAddRate => menuViewers > 0 ? (cartAdders / menuViewers) * 100 : 0;
  double get checkoutRate => cartAdders > 0 ? (checkoutStarters / cartAdders) * 100 : 0;
  double get completionRate => checkoutStarters > 0 ? (orderCompleters / checkoutStarters) * 100 : 0;
  double get overallConversionRate => totalVisitors > 0 ? (orderCompleters / totalVisitors) * 100 : 0;
}

/// Advanced Menu Performance Analytics Model
@JsonSerializable()
class AdvancedMenuAnalytics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final DateTime startDate;
  final DateTime endDate;

  // Menu performance metrics
  @JsonKey(name: 'total_menu_items')
  final int totalMenuItems;
  @JsonKey(name: 'active_menu_items')
  final int activeMenuItems;
  @JsonKey(name: 'avg_item_price')
  final double avgItemPrice;
  @JsonKey(name: 'menu_revenue')
  final double menuRevenue;

  // Item performance
  @JsonKey(name: 'top_performing_items')
  final List<MenuItemPerformance> topPerformingItems;
  @JsonKey(name: 'underperforming_items')
  final List<MenuItemPerformance> underperformingItems;
  @JsonKey(name: 'trending_items')
  final List<MenuItemPerformance> trendingItems;

  // Category performance
  @JsonKey(name: 'category_performance')
  final Map<String, CategoryPerformance> categoryPerformance;

  // Menu optimization insights
  @JsonKey(name: 'optimization_recommendations')
  final List<MenuOptimizationRecommendation> optimizationRecommendations;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  AdvancedMenuAnalytics({
    required this.id,
    required this.restaurantId,
    required this.startDate,
    required this.endDate,
    required this.totalMenuItems,
    required this.activeMenuItems,
    required this.avgItemPrice,
    required this.menuRevenue,
    required this.topPerformingItems,
    required this.underperformingItems,
    required this.trendingItems,
    required this.categoryPerformance,
    required this.optimizationRecommendations,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdvancedMenuAnalytics.fromJson(Map<String, dynamic> json) =>
      _$AdvancedMenuAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$AdvancedMenuAnalyticsToJson(this);
}

@JsonSerializable()
class MenuItemPerformance {
  final String id;
  @JsonKey(name: 'item_name')
  final String itemName;
  @JsonKey(name: 'category')
  final String category;
  final double price;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'popularity_score')
  final double popularityScore;
  @JsonKey(name: 'profit_margin')
  final double profitMargin;
  @JsonKey(name: 'growth_rate')
  final double growthRate;
  @JsonKey(name: 'customer_rating')
  final double customerRating;
  @JsonKey(name: 'times_viewed')
  final int timesViewed;
  @JsonKey(name: 'conversion_rate')
  final double conversionRate;
  @JsonKey(name: 'trend_indicator')
  final String trendIndicator; // 'rising', 'stable', 'declining'

  MenuItemPerformance({
    required this.id,
    required this.itemName,
    required this.category,
    required this.price,
    required this.totalOrders,
    required this.totalRevenue,
    required this.popularityScore,
    required this.profitMargin,
    required this.growthRate,
    required this.customerRating,
    required this.timesViewed,
    required this.conversionRate,
    required this.trendIndicator,
  });

  factory MenuItemPerformance.fromJson(Map<String, dynamic> json) =>
      _$MenuItemPerformanceFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemPerformanceToJson(json);

  // Helper getters
  double get avgOrderValue => totalOrders > 0 ? totalRevenue / totalOrders : 0;
  bool get isTopPerformer => popularityScore >= 80;
  bool get isUnderperforming => popularityScore <= 20;
}

@JsonSerializable()
class CategoryPerformance {
  final String name;
  @JsonKey(name: 'total_items')
  final int totalItems;
  @JsonKey(name: 'total_orders')
  final int totalOrders;
  @JsonKey(name: 'total_revenue')
  final double totalRevenue;
  @JsonKey(name: 'avg_item_price')
  final double avgItemPrice;
  @JsonKey(name: 'profit_margin')
  final double profitMargin;
  @JsonKey(name: 'category_growth_rate')
  final double categoryGrowthRate;
  @JsonKey(name: 'market_share')
  final double marketShare; // Percentage of total menu revenue

  CategoryPerformance({
    required this.name,
    required this.totalItems,
    required this.totalOrders,
    required this.totalRevenue,
    required this.avgItemPrice,
    required this.profitMargin,
    required this.categoryGrowthRate,
    required this.marketShare,
  });

  factory CategoryPerformance.fromJson(Map<String, dynamic> json) =>
      _$CategoryPerformanceFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryPerformanceToJson(json);
}

@JsonSerializable()
class MenuOptimizationRecommendation {
  final String type; // 'promote', 'optimize', 'remove', 'price_adjust'
  @JsonKey(name: 'menu_item_id')
  final String menuItemId;
  @JsonKey(name: 'item_name')
  final String itemName;
  final String recommendation;
  final String reasoning;
  @JsonKey(name: 'potential_impact')
  final String potentialImpact;
  @JsonKey(name: 'priority')
  final String priority; // 'high', 'medium', 'low'
  @JsonKey(name: 'estimated_revenue_change')
  final double estimatedRevenueChange;

  MenuOptimizationRecommendation({
    required this.type,
    required this.menuItemId,
    required this.itemName,
    required this.recommendation,
    required this.reasoning,
    required this.potentialImpact,
    required this.priority,
    required this.estimatedRevenueChange,
  });

  factory MenuOptimizationRecommendation.fromJson(Map<String, dynamic> json) =>
      _$MenuOptimizationRecommendationFromJson(json);

  Map<String, dynamic> toJson() => _$MenuOptimizationRecommendationToJson(json);
}

/// Real-time Metrics Model
@JsonSerializable()
class RealTimeMetrics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'metric_timestamp')
  final DateTime metricTimestamp;

  // Order metrics
  @JsonKey(name: 'active_orders')
  final int activeOrders;
  @JsonKey(name: 'pending_orders')
  final int pendingOrders;
  @JsonKey(name: 'preparing_orders')
  final int preparingOrders;
  @JsonKey(name: 'ready_orders')
  final int readyOrders;

  // Revenue metrics
  @JsonKey(name: 'current_day_revenue')
  final double currentDayRevenue;
  @JsonKey(name: 'current_hour_revenue')
  final double currentHourRevenue;
  @JsonKey(name: 'current_day_orders')
  final int currentDayOrders;
  @JsonKey(name: 'current_hour_orders')
  final int currentHourOrders;

  // Performance metrics
  @JsonKey(name: 'current_avg_prep_time')
  final int currentAvgPrepTime;
  @JsonKey(name: 'current_avg_response_time')
  final int currentAvgResponseTime;
  @JsonKey(name: 'staff_available')
  final int staffAvailable;
  @JsonKey(name: 'queue_length')
  final int queueLength;

  // System status
  @JsonKey(name: 'is_accepting_orders')
  final bool isAcceptingOrders;
  @JsonKey(name: 'kitchen_capacity_utilization')
  final double kitchenCapacityUtilization;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  RealTimeMetrics({
    required this.id,
    required this.restaurantId,
    required this.metricTimestamp,
    required this.activeOrders,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.currentDayRevenue,
    required this.currentHourRevenue,
    required this.currentDayOrders,
    required this.currentHourOrders,
    required this.currentAvgPrepTime,
    required this.currentAvgResponseTime,
    required this.staffAvailable,
    required this.queueLength,
    required this.isAcceptingOrders,
    required this.kitchenCapacityUtilization,
    required this.createdAt,
  });

  factory RealTimeMetrics.fromJson(Map<String, dynamic> json) =>
      _$RealTimeMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$RealTimeMetricsToJson(json);

  // Helper getters
  double get ordersPerHour => currentHourOrders.toDouble();
  double get revenuePerHour => currentHourRevenue;
  double get avgPrepTimeMinutes => currentAvgPrepTime.toDouble();
  bool get isAtCapacity => kitchenCapacityUtilization >= 80;
  bool get hasLongQueue => queueLength > 10;
}

/// Analytics Report Model
@JsonSerializable()
class AnalyticsReport {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'report_name')
  final String reportName;
  @JsonKey(name: 'report_type')
  final String reportType;
  @JsonKey(name: 'date_range_start')
  final DateTime dateRangeStart;
  @JsonKey(name: 'date_range_end')
  final DateTime dateRangeEnd;
  @JsonKey(name: 'report_data')
  final Map<String, dynamic> reportData;
  @JsonKey(name: 'generated_at')
  final DateTime generatedAt;
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @JsonKey(name: 'file_format')
  final String? fileFormat;
  @JsonKey(name: 'is_scheduled')
  final bool isScheduled;
  @JsonKey(name: 'schedule_frequency')
  final String? scheduleFrequency;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  AnalyticsReport({
    required this.id,
    required this.restaurantId,
    required this.reportName,
    required this.reportType,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.reportData,
    required this.generatedAt,
    this.fileUrl,
    this.fileFormat,
    required this.isScheduled,
    this.scheduleFrequency,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsReportFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsReportToJson(this);

  // Helper getters
  bool get isDownloadable => fileUrl != null;
  String get dateRangeDisplay => '${dateRangeStart.day}/${dateRangeStart.month}/${dateRangeStart.year} - ${dateRangeEnd.day}/${dateRangeEnd.month}/${dateRangeEnd.year}';
}

/// Predictive Analytics Model
@JsonSerializable()
class PredictiveAnalytics {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'prediction_date')
  final DateTime predictionDate;
  @JsonKey(name: 'prediction_type')
  final String predictionType;
  @JsonKey(name: 'prediction_horizon')
  final int predictionHorizon;
  @JsonKey(name: 'predicted_value')
  final double predictedValue;
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;
  @JsonKey(name: 'prediction_model')
  final String predictionModel;
  @JsonKey(name: 'actual_value')
  final double? actualValue;
  @JsonKey(name: 'accuracy_score')
  final double? accuracyScore;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  PredictiveAnalytics({
    required this.id,
    required this.restaurantId,
    required this.predictionDate,
    required this.predictionType,
    required this.predictionHorizon,
    required this.predictedValue,
    required this.confidenceScore,
    required this.predictionModel,
    this.actualValue,
    this.accuracyScore,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PredictiveAnalytics.fromJson(Map<String, dynamic> json) =>
      _$PredictiveAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$PredictiveAnalyticsToJson(this);

  // Helper getters
  bool get isHighConfidence => confidenceScore >= 0.8;
  bool get hasActualData => actualValue != null;
  double get predictionAccuracy => accuracyScore ?? 0.0;
  bool get isAccurate => hasActualData && (accuracyScore ?? 0) >= 0.8;
}