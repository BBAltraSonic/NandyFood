import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/enhanced_analytics.dart';

/// Predictive Analytics Service for forecasting and recommendations
class PredictiveAnalyticsService {
  final SupabaseClient _supabase;

  PredictiveAnalyticsService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Generate revenue forecast
  Future<PredictiveAnalytics> generateRevenueForecast(
    String restaurantId, {
    int daysAhead = 30,
    String model = 'linear_trend_with_seasonal',
  }) async {
    AppLogger.function('PredictiveAnalyticsService.generateRevenueForecast', 'ENTER');

    try {
      // Get historical data for the last 90 days
      final historicalData = await _getHistoricalRevenueData(restaurantId, 90);

      if (historicalData.isEmpty) {
        throw Exception('Insufficient historical data for forecasting');
      }

      // Calculate predictions using different models
      final predictions = await _calculateRevenuePredictions(
        historicalData,
        daysAhead: daysAhead,
        model: model,
      );

      // Calculate confidence score based on historical accuracy
      final confidenceScore = await _calculateConfidenceScore(
        restaurantId,
        'revenue',
        model,
      );

      final prediction = PredictiveAnalytics(
        id: 'revenue_forecast_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        predictionDate: DateTime.now(),
        predictionType: 'revenue',
        predictionHorizon: daysAhead,
        predictedValue: predictions,
        confidenceScore: confidenceScore,
        predictionModel: model,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save prediction to database
      await _savePrediction(prediction);

      AppLogger.success('Revenue forecast generated successfully');
      return prediction;
    } catch (e, stack) {
      AppLogger.error('Failed to generate revenue forecast', error: e, stack: stack);
      rethrow;
    }
  }

  /// Generate demand forecast
  Future<PredictiveAnalytics> generateDemandForecast(
    String restaurantId, {
    int daysAhead = 7,
    String model = 'seasonal_pattern',
  }) async {
    AppLogger.function('PredictiveAnalyticsService.generateDemandForecast', 'ENTER');

    try {
      // Get historical order data
      final historicalData = await _getHistoricalOrderData(restaurantId, 90);

      if (historicalData.isEmpty) {
        throw Exception('Insufficient historical data for forecasting');
      }

      // Calculate demand predictions
      final predictions = await _calculateDemandPredictions(
        historicalData,
        daysAhead: daysAhead,
        model: model,
      );

      // Calculate confidence score
      final confidenceScore = await _calculateConfidenceScore(
        restaurantId,
        'demand',
        model,
      );

      final prediction = PredictiveAnalytics(
        id: 'demand_forecast_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        predictionDate: DateTime.now(),
        predictionType: 'demand',
        predictionHorizon: daysAhead,
        predictedValue: predictions,
        confidenceScore: confidenceScore,
        predictionModel: model,
        metadata: {
          'peak_hours': await _identifyPeakHours(historicalData),
          'seasonal_factors': await _calculateSeasonalFactors(historicalData),
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _savePrediction(prediction);

      AppLogger.success('Demand forecast generated successfully');
      return prediction;
    } catch (e, stack) {
      AppLogger.error('Failed to generate demand forecast', error: e, stack: stack);
      rethrow;
    }
  }

  /// Generate staffing recommendations
  Future<List<StaffingRecommendation>> generateStaffingRecommendations(
    String restaurantId,
  ) async {
    AppLogger.function('PredictiveAnalyticsService.generateStaffingRecommendations', 'ENTER');

    try {
      // Get demand forecast
      final demandForecast = await generateDemandForecast(restaurantId, daysAhead: 7);

      // Get historical staffing data
      final staffingData = await _getHistoricalStaffingData(restaurantId, 30);

      // Get current staff availability
      final currentStaff = await _getCurrentStaffData(restaurantId);

      final recommendations = <StaffingRecommendation>[];

      // Analyze each day in the forecast
      for (int i = 0; i < 7; i++) {
        final date = DateTime.now().add(Duration(days: i));
        final predictedDemand = _getDemandForDate(demandForecast, date);

        final recommendedStaff = _calculateOptimalStaffing(
          predictedDemand,
          staffingData,
          currentStaff,
        );

        recommendations.add(StaffingRecommendation(
          date: date,
          predictedDemand: predictedDemand,
          recommendedStaff: recommendedStaff,
          currentStaff: currentStaff.length,
          adjustmentNeeded: recommendedStaff - currentStaff.length,
          reasoning: _generateStaffingReasoning(predictedDemand, currentStaff.length, recommendedStaff),
          priority: _calculateStaffingPriority(predictedDemand, currentStaff.length, recommendedStaff),
        ));
      }

      AppLogger.success('Staffing recommendations generated successfully');
      return recommendations;
    } catch (e, stack) {
      AppLogger.error('Failed to generate staffing recommendations', error: e, stack: stack);
      return [];
    }
  }

  /// Generate inventory recommendations
  Future<List<InventoryRecommendation>> generateInventoryRecommendations(
    String restaurantId,
  ) async {
    AppLogger.function('PredictiveAnalyticsService.generateInventoryRecommendations', 'ENTER');

    try {
      // Get demand forecast
      final demandForecast = await generateDemandForecast(restaurantId, daysAhead: 7);

      // Get menu item analytics
      final menuAnalytics = await _getMenuAnalytics(restaurantId);

      // Get current inventory levels
      final currentInventory = await _getCurrentInventory(restaurantId);

      final recommendations = <InventoryRecommendation>[];

      for (final item in menuAnalytics.topPerformingItems) {
        final predictedDemand = _predictItemDemand(item, demandForecast);
        final currentStock = currentInventory[item.id] ?? 0;

        if (currentStock < predictedDemand) {
          final reorderQuantity = _calculateReorderQuantity(predictedDemand, currentStock);

          recommendations.add(InventoryRecommendation(
            menuItemId: item.id,
            itemName: item.itemName,
            currentStock: currentStock,
            predictedDemand: predictedDemand,
            reorderQuantity: reorderQuantity,
            urgency: _calculateInventoryUrgency(currentStock.toDouble(), predictedDemand.toDouble()),
            reasoning: _generateInventoryReasoning(item, currentStock.toDouble(), predictedDemand.toDouble()),
            estimatedCost: _calculateEstimatedCost(item, reorderQuantity),
          ));
        }
      }

      AppLogger.success('Inventory recommendations generated successfully');
      return recommendations;
    } catch (e, stack) {
      AppLogger.error('Failed to generate inventory recommendations', error: e, stack: stack);
      return [];
    }
  }

  /// Generate menu optimization recommendations
  Future<List<MenuOptimizationRecommendation>> generateMenuOptimizationRecommendations(
    String restaurantId,
  ) async {
    AppLogger.function('PredictiveAnalyticsService.generateMenuOptimizationRecommendations', 'ENTER');

    try {
      // Get menu analytics
      final menuAnalytics = await _getMenuAnalytics(restaurantId);

      // Get customer preferences
      final customerPreferences = await _getCustomerPreferences(restaurantId);

      // Get market trends
      final marketTrends = await _getMarketTrends();

      final recommendations = <MenuOptimizationRecommendation>[];

      // Analyze underperforming items
      for (final item in menuAnalytics.underperformingItems) {
        if (item.popularityScore < 20) {
          final recommendationType = _determineOptimizationType(item, customerPreferences);

          recommendations.add(MenuOptimizationRecommendation(
            type: recommendationType,
            menuItemId: item.id,
            itemName: item.itemName,
            recommendation: _generateOptimizationRecommendation(item, recommendationType),
            reasoning: _generateOptimizationReasoning(item, recommendationType, customerPreferences),
            potentialImpact: _calculateOptimizationImpact(item, recommendationType),
            priority: _calculateOptimizationPriority(item, recommendationType),
            estimatedRevenueChange: _estimateRevenueChange(item, recommendationType),
          ));
        }
      }

      // Analyze trending opportunities
      for (final item in menuAnalytics.trendingItems) {
        if (item.growthRate > 20) {
          recommendations.add(MenuOptimizationRecommendation(
            type: 'promote',
            menuItemId: item.id,
            itemName: item.itemName,
            recommendation: 'Increase visibility and promotion for this trending item',
            reasoning: 'Item shows strong growth trend (${item.growthRate.toStringAsFixed(1)}% growth)',
            potentialImpact: 'High - capitalize on momentum',
            priority: 'high',
            estimatedRevenueChange: item.totalRevenue * 0.2, // 20% increase potential
          ));
        }
      }

      AppLogger.success('Menu optimization recommendations generated successfully');
      return recommendations;
    } catch (e, stack) {
      AppLogger.error('Failed to generate menu optimization recommendations', error: e, stack: stack);
      return [];
    }
  }

  /// Get predictive accuracy metrics
  Future<PredictionAccuracyMetrics> getPredictionAccuracyMetrics(
    String restaurantId,
    String predictionType,
  ) async {
    AppLogger.function('PredictiveAnalyticsService.getPredictionAccuracyMetrics', 'ENTER');

    try {
      final data = await _supabase
          .from('predictive_analytics')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('prediction_type', predictionType)
          .not('actual_value', 'is', null)
          .order('prediction_date', ascending: false)
          .limit(100);

      if (data.isEmpty) {
        return PredictionAccuracyMetrics(
          totalPredictions: 0,
          accuratePredictions: 0,
          accuracyRate: 0.0,
          averageError: 0.0,
          modelPerformance: {},
        );
      }

      final predictions = data
          .map((json) => PredictiveAnalytics.fromJson(json))
          .toList();

      int accuratePredictions = 0;
      double totalError = 0.0;
      final Map<String, List<double>> modelErrors = {};

      for (final prediction in predictions) {
        if (prediction.actualValue != null && prediction.accuracyScore != null) {
          if (prediction.accuracyScore! >= 0.8) {
            accuratePredictions++;
          }

          final error = (prediction.predictedValue - prediction.actualValue!).abs();
          totalError += error;

          final model = prediction.predictionModel;
          modelErrors.putIfAbsent(model, () => []).add(error);
        }
      }

      final modelPerformance = <String, double>{};
      for (final entry in modelErrors.entries) {
        final errors = entry.value;
        modelPerformance[entry.key] = errors.reduce((a, b) => a + b) / errors.length;
      }

      return PredictionAccuracyMetrics(
        totalPredictions: predictions.length,
        accuratePredictions: accuratePredictions,
        accuracyRate: predictions.isNotEmpty ? (accuratePredictions / predictions.length) * 100 : 0.0,
        averageError: predictions.isNotEmpty ? totalError / predictions.length : 0.0,
        modelPerformance: modelPerformance,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get prediction accuracy metrics', error: e, stack: stack);
      return PredictionAccuracyMetrics(
        totalPredictions: 0,
        accuratePredictions: 0,
        accuracyRate: 0.0,
        averageError: 0.0,
        modelPerformance: {},
      );
    }
  }

  // Private helper methods

  Future<List<Map<String, dynamic>>> _getHistoricalRevenueData(
    String restaurantId,
    int days,
  ) async {
    final data = await _supabase
        .from('restaurant_analytics')
        .select('date, total_revenue')
        .eq('restaurant_id', restaurantId)
        .gte('date', DateTime.now().subtract(Duration(days: days)).toIso8601String())
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _getHistoricalOrderData(
    String restaurantId,
    int days,
  ) async {
    final data = await _supabase
        .from('restaurant_analytics')
        .select('date, total_orders')
        .eq('restaurant_id', restaurantId)
        .gte('date', DateTime.now().subtract(Duration(days: days)).toIso8601String())
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<double> _calculateRevenuePredictions(
    List<Map<String, dynamic>> historicalData, {
    required int daysAhead,
    required String model,
  }) async {
    if (historicalData.isEmpty) return 0.0;

    switch (model) {
      case 'linear_trend':
        return _calculateLinearTrendPrediction(historicalData, daysAhead);
      case 'moving_average':
        return _calculateMovingAveragePrediction(historicalData);
      case 'seasonal_pattern':
        return _calculateSeasonalPrediction(historicalData, daysAhead);
      case 'linear_trend_with_seasonal':
      default:
        final trendPrediction = _calculateLinearTrendPrediction(historicalData, daysAhead);
        final seasonalAdjustment = _calculateSeasonalAdjustment(historicalData);
        return trendPrediction * seasonalAdjustment;
    }
  }

  double _calculateLinearTrendPrediction(
    List<Map<String, dynamic>> data,
    int daysAhead,
  ) {
    if (data.length < 2) return data.isNotEmpty ? data.last['total_revenue']?.toDouble() ?? 0.0 : 0.0;

    // Calculate linear regression
    final n = data.length.toDouble();
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < data.length; i++) {
      final x = i.toDouble();
      final y = data[i]['total_revenue']?.toDouble() ?? 0.0;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Predict for future
    final futureX = data.length.toDouble() + daysAhead;
    return slope * futureX + intercept;
  }

  double _calculateMovingAveragePrediction(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0.0;

    final windowSize = min(7, data.length);
    final recentData = data.skip(data.length - windowSize).toList();

    final sum = recentData
        .map((d) => d['total_revenue']?.toDouble() ?? 0.0)
        .reduce((a, b) => a + b);

    return sum / windowSize;
  }

  double _calculateSeasonalPrediction(
    List<Map<String, dynamic>> data,
    int daysAhead,
  ) {
    if (data.isEmpty) return 0.0;

    // Simple seasonal adjustment based on day of week
    final dayOfWeek = DateTime.now().add(Duration(days: daysAhead)).weekday;
    final historicalAverage = data
        .map((d) => d['total_revenue']?.toDouble() ?? 0.0)
        .reduce((a, b) => a + b) / data.length;

    // Day of week multipliers (simplified)
    final dayMultipliers = [0.8, 0.9, 1.0, 1.0, 1.1, 1.3, 1.2]; // Mon-Sun
    final multiplier = dayMultipliers[dayOfWeek - 1];

    return historicalAverage * multiplier;
  }

  double _calculateSeasonalAdjustment(List<Map<String, dynamic>> data) {
    if (data.length < 7) return 1.0;

    // Calculate day-of-week patterns
    final dayOfWeekSums = List.filled(7, 0.0);
    final dayOfWeekCounts = List.filled(7, 0);

    for (final entry in data) {
      final date = DateTime.parse(entry['date']);
      final dayOfWeek = date.weekday - 1; // 0-6 (Mon-Sun)
      final revenue = entry['total_revenue']?.toDouble() ?? 0.0;

      dayOfWeekSums[dayOfWeek] += revenue;
      dayOfWeekCounts[dayOfWeek]++;
    }

    // Calculate average for each day
    final dayOfWeekAverages = List.generate(7, (i) {
      return dayOfWeekCounts[i] > 0 ? dayOfWeekSums[i] / dayOfWeekCounts[i] : 0.0;
    });

    final overallAverage = dayOfWeekAverages.reduce((a, b) => a + b) / 7;
    final currentDayOfWeek = DateTime.now().weekday - 1;

    return overallAverage > 0 ? dayOfWeekAverages[currentDayOfWeek] / overallAverage : 1.0;
  }

  Future<double> _calculateDemandPredictions(
    List<Map<String, dynamic>> historicalData, {
    required int daysAhead,
    required String model,
  }) async {
    // Similar to revenue predictions but for order volume
    final orderData = historicalData.map((d) => {
      'date': d['date'],
      'value': d['total_orders'] ?? 0,
    }).toList();

    if (orderData.isEmpty) return 0.0;

    switch (model) {
      case 'seasonal_pattern':
        return _calculateSeasonalOrderPrediction(orderData, daysAhead);
      default:
        return _calculateMovingAverageOrderPrediction(orderData);
    }
  }

  double _calculateSeasonalOrderPrediction(
    List<Map<String, dynamic>> data,
    int daysAhead,
  ) {
    if (data.isEmpty) return 0.0;

    final dayOfWeek = DateTime.now().add(Duration(days: daysAhead)).weekday;

    // Calculate average orders for each day of week
    final dayOfWeekSums = List.filled(7, 0.0);
    final dayOfWeekCounts = List.filled(7, 0);

    for (final entry in data) {
      final date = DateTime.parse(entry['date']);
      final dayIndex = date.weekday - 1;
      final orders = (entry['value'] as int?)?.toDouble() ?? 0.0;

      dayOfWeekSums[dayIndex] += orders;
      dayOfWeekCounts[dayIndex]++;
    }

    final averageForDay = dayOfWeekCounts[dayOfWeek - 1] > 0
        ? dayOfWeekSums[dayOfWeek - 1] / dayOfWeekCounts[dayOfWeek - 1]
        : 0.0;

    return averageForDay;
  }

  double _calculateMovingAverageOrderPrediction(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0.0;

    final windowSize = min(7, data.length);
    final recentData = data.skip(data.length - windowSize).toList();

    final sum = recentData
        .map((d) => (d['value'] as int?)?.toDouble() ?? 0.0)
        .reduce((a, b) => a + b);

    return sum / windowSize;
  }

  Future<double> _calculateConfidenceScore(
    String restaurantId,
    String predictionType,
    String model,
  ) async {
    // Get historical accuracy for this model
    final data = await _supabase
        .from('predictive_analytics')
        .select('accuracy_score')
        .eq('restaurant_id', restaurantId)
        .eq('prediction_type', predictionType)
        .eq('prediction_model', model)
        .not('accuracy_score', 'is', null)
        .order('prediction_date', ascending: false)
        .limit(10);

    if (data.isEmpty) return 0.7; // Default confidence score

    final accuracies = data
        .map((d) => d['accuracy_score'] as double? ?? 0.0)
        .toList();

    return accuracies.reduce((a, b) => a + b) / accuracies.length;
  }

  Future<void> _savePrediction(PredictiveAnalytics prediction) async {
    await _supabase.from('predictive_analytics').insert(prediction.toJson());
  }

  // Additional helper methods for staffing, inventory, and menu recommendations
  // These would contain the actual business logic for each recommendation type

  Future<List<Map<String, dynamic>>> _getHistoricalStaffingData(
    String restaurantId,
    int days,
  ) async {
    // Implementation would fetch staffing history
    return [];
  }

  Future<List<Map<String, dynamic>>> _getCurrentStaffData(String restaurantId) async {
    // Implementation would fetch current staff availability
    return [];
  }

  int _calculateOptimalStaffing(
    double predictedDemand,
    List<Map<String, dynamic>> staffingData,
    List<Map<String, dynamic>> currentStaff,
  ) {
    // Simplified calculation: 1 staff member per 10 orders per hour
    return max(1, (predictedDemand / 10).ceil());
  }

  String _generateStaffingReasoning(
    double predictedDemand,
    int currentStaff,
    int recommendedStaff,
  ) {
    if (recommendedStaff > currentStaff) {
      return 'High demand expected. Consider adding ${recommendedStaff - currentStaff} staff members.';
    } else if (recommendedStaff < currentStaff) {
      return 'Lower demand expected. Consider reducing staff by ${currentStaff - recommendedStaff}.';
    } else {
      return 'Current staffing level is optimal for predicted demand.';
    }
  }

  String _calculateStaffingPriority(
    double predictedDemand,
    int currentStaff,
    int recommendedStaff,
  ) {
    final difference = (recommendedStaff - currentStaff).abs();
    if (difference > 2) return 'high';
    if (difference > 0) return 'medium';
    return 'low';
  }

  double _getDemandForDate(PredictiveAnalytics forecast, DateTime date) {
    // Simplified: distribute forecast evenly across prediction horizon
    return forecast.predictedValue / forecast.predictionHorizon;
  }

  Future<Map<String, MenuItemPerformance>> _getMenuAnalytics(String restaurantId) async {
    // Implementation would fetch menu analytics
    return {};
  }

  Future<Map<String, int>> _getCurrentInventory(String restaurantId) async {
    // Implementation would fetch current inventory levels
    return {};
  }

  double _predictItemDemand(MenuItemPerformance item, PredictiveAnalytics demandForecast) {
    // Simplified: predict based on item's historical popularity
    return item.totalOrders * 0.1; // 10% of historical orders as baseline
  }

  int _calculateReorderQuantity(double predictedDemand, int currentStock) {
    return max(0, (predictedDemand - currentStock).ceil());
  }

  String _calculateInventoryUrgency(double currentStock, double predictedDemand) {
    final ratio = currentStock / predictedDemand;
    if (ratio < 0.5) return 'high';
    if (ratio < 0.8) return 'medium';
    return 'low';
  }

  String _generateInventoryReasoning(
    MenuItemPerformance item,
    double currentStock,
    double predictedDemand,
  ) {
    return 'Current stock ($currentStock) is insufficient for predicted demand ($predictedDemand.toStringAsFixed(0)}).';
  }

  double _calculateEstimatedCost(MenuItemPerformance item, int reorderQuantity) {
    return reorderQuantity * item.price * 0.6; // Assuming 60% cost of price
  }

  Future<Map<String, dynamic>> _getCustomerPreferences(String restaurantId) async {
    // Implementation would fetch customer preference data
    return {};
  }

  Future<Map<String, dynamic>> _getMarketTrends() async {
    // Implementation would fetch market trend data
    return {};
  }

  String _determineOptimizationType(
    MenuItemPerformance item,
    Map<String, dynamic> customerPreferences,
  ) {
    if (item.profitMargin < 10) return 'price_adjust';
    if (item.conversionRate < 5) return 'optimize';
    return 'remove';
  }

  String _generateOptimizationRecommendation(
    MenuItemPerformance item,
    String type,
  ) {
    switch (type) {
      case 'price_adjust':
        return 'Consider adjusting price to improve profitability';
      case 'optimize':
        return 'Optimize item description, images, or positioning';
      case 'remove':
        return 'Consider removing from menu due to poor performance';
      default:
        return 'Review item performance';
    }
  }

  String _generateOptimizationReasoning(
    MenuItemPerformance item,
    String type,
    Map<String, dynamic> preferences,
  ) {
    switch (type) {
      case 'price_adjust':
        return 'Low profit margin (${item.profitMargin.toStringAsFixed(1)}%) affects overall profitability';
      case 'optimize':
        return 'Low conversion rate (${item.conversionRate.toStringAsFixed(1)}%) suggests presentation issues';
      case 'remove':
        return 'Consistently low popularity score (${item.popularityScore.toStringAsFixed(1)})';
      default:
        return 'Performance metrics indicate optimization needed';
    }
  }

  String _calculateOptimizationImpact(MenuItemPerformance item, String type) {
    switch (type) {
      case 'price_adjust':
        return 'Medium - Improve profitability';
      case 'optimize':
        return 'High - Increase sales and conversion';
      case 'remove':
        return 'High - Reduce complexity and waste';
      default:
        return 'Medium - General improvement';
    }
  }

  String _calculateOptimizationPriority(MenuItemPerformance item, String type) {
    if (type == 'remove' && item.profitMargin < 0) return 'high';
    if (type == 'optimize' && item.conversionRate < 2) return 'high';
    return 'medium';
  }

  double _estimateRevenueChange(MenuItemPerformance item, String type) {
    switch (type) {
      case 'price_adjust':
        return item.totalRevenue * 0.15; // 15% improvement potential
      case 'optimize':
        return item.totalRevenue * 0.25; // 25% improvement potential
      case 'remove':
        return -item.totalRevenue * 0.1; // Small loss from removing
      default:
        return item.totalRevenue * 0.1; // 10% improvement potential
    }
  }

  List<int> _identifyPeakHours(List<Map<String, dynamic>> data) {
    // Simplified peak hour identification
    return [12, 13, 19, 20]; // Lunch and dinner hours
  }

  Map<String, double> _calculateSeasonalFactors(List<Map<String, dynamic>> data) {
    // Simplified seasonal factors
    return {
      'weekend': 1.2,
      'weekday': 0.9,
      'holiday': 1.5,
    };
  }
}

/// Staffing Recommendation Model
class StaffingRecommendation {
  final DateTime date;
  final double predictedDemand;
  final int recommendedStaff;
  final int currentStaff;
  final int adjustmentNeeded;
  final String reasoning;
  final String priority;

  StaffingRecommendation({
    required this.date,
    required this.predictedDemand,
    required this.recommendedStaff,
    required this.currentStaff,
    required this.adjustmentNeeded,
    required this.reasoning,
    required this.priority,
  });
}

/// Inventory Recommendation Model
class InventoryRecommendation {
  final String menuItemId;
  final String itemName;
  final int currentStock;
  final double predictedDemand;
  final int reorderQuantity;
  final String urgency;
  final String reasoning;
  final double estimatedCost;

  InventoryRecommendation({
    required this.menuItemId,
    required this.itemName,
    required this.currentStock,
    required this.predictedDemand,
    required this.reorderQuantity,
    required this.urgency,
    required this.reasoning,
    required this.estimatedCost,
  });
}

/// Prediction Accuracy Metrics Model
class PredictionAccuracyMetrics {
  final int totalPredictions;
  final int accuratePredictions;
  final double accuracyRate;
  final double averageError;
  final Map<String, double> modelPerformance;

  PredictionAccuracyMetrics({
    required this.totalPredictions,
    required this.accuratePredictions,
    required this.accuracyRate,
    required this.averageError,
    required this.modelPerformance,
  });
}