import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/enhanced_analytics_service.dart';
import 'package:food_delivery_app/shared/models/enhanced_analytics.dart';

/// Enhanced Analytics State
class EnhancedAnalyticsState {
  final AdvancedRevenueAnalytics? revenueAnalytics;
  final AdvancedCustomerAnalytics? customerAnalytics;
  final AdvancedMenuAnalytics? menuAnalytics;
  final RealTimeMetrics? realTimeMetrics;
  final List<AnalyticsReport> reports;
  final List<PredictiveAnalytics> predictions;
  final Map<String, dynamic> benchmarks;

  final bool isLoading;
  final bool isLoadingRevenue;
  final bool isLoadingCustomer;
  final bool isLoadingMenu;
  final bool isLoadingRealTime;
  final bool isLoadingReports;
  final bool isLoadingPredictions;

  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  const EnhancedAnalyticsState({
    this.revenueAnalytics,
    this.customerAnalytics,
    this.menuAnalytics,
    this.realTimeMetrics,
    this.reports = const [],
    this.predictions = const [],
    this.benchmarks = const {},

    this.isLoading = false,
    this.isLoadingRevenue = false,
    this.isLoadingCustomer = false,
    this.isLoadingMenu = false,
    this.isLoadingRealTime = false,
    this.isLoadingReports = false,
    this.isLoadingPredictions = false,

    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  EnhancedAnalyticsState copyWith({
    AdvancedRevenueAnalytics? revenueAnalytics,
    AdvancedCustomerAnalytics? customerAnalytics,
    AdvancedMenuAnalytics? menuAnalytics,
    RealTimeMetrics? realTimeMetrics,
    List<AnalyticsReport>? reports,
    List<PredictiveAnalytics>? predictions,
    Map<String, dynamic>? benchmarks,

    bool? isLoading,
    bool? isLoadingRevenue,
    bool? isLoadingCustomer,
    bool? isLoadingMenu,
    bool? isLoadingRealTime,
    bool? isLoadingReports,
    bool? isLoadingPredictions,

    String? errorMessage,
    bool clearError = false,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return EnhancedAnalyticsState(
      revenueAnalytics: revenueAnalytics ?? this.revenueAnalytics,
      customerAnalytics: customerAnalytics ?? this.customerAnalytics,
      menuAnalytics: menuAnalytics ?? this.menuAnalytics,
      realTimeMetrics: realTimeMetrics ?? this.realTimeMetrics,
      reports: reports ?? this.reports,
      predictions: predictions ?? this.predictions,
      benchmarks: benchmarks ?? this.benchmarks,

      isLoading: isLoading ?? this.isLoading,
      isLoadingRevenue: isLoadingRevenue ?? this.isLoadingRevenue,
      isLoadingCustomer: isLoadingCustomer ?? this.isLoadingCustomer,
      isLoadingMenu: isLoadingMenu ?? this.isLoadingMenu,
      isLoadingRealTime: isLoadingRealTime ?? this.isLoadingRealTime,
      isLoadingReports: isLoadingReports ?? this.isLoadingReports,
      isLoadingPredictions: isLoadingPredictions ?? this.isLoadingPredictions,

      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Get overall loading state
  bool get isAnyLoading =>
      isLoading ||
      isLoadingRevenue ||
      isLoadingCustomer ||
      isLoadingMenu ||
      isLoadingRealTime ||
      isLoadingReports ||
      isLoadingPredictions;

  /// Check if all main analytics are loaded
  bool get hasAllAnalytics =>
      revenueAnalytics != null &&
      customerAnalytics != null &&
      menuAnalytics != null;

  /// Get summary stats
  Map<String, dynamic> get summaryStats {
    if (!hasAllAnalytics) return {};

    return {
      'totalRevenue': revenueAnalytics!.totalRevenue,
      'targetAchievementRate': revenueAnalytics!.targetAchievementRate,
      'totalCustomers': customerAnalytics!.totalCustomers,
      'customerRetentionRate': customerAnalytics!.customerRetentionRate,
      'activeMenuItems': menuAnalytics!.activeMenuItems,
      'avgOrderValue': revenueAnalytics!.averageOrderValue,
      'isAcceptingOrders': realTimeMetrics?.isAcceptingOrders ?? true,
      'activeOrders': realTimeMetrics?.activeOrders ?? 0,
    };
  }
}

/// Enhanced Analytics Notifier
class EnhancedAnalyticsNotifier extends StateNotifier<EnhancedAnalyticsState> {
  final EnhancedAnalyticsService _analyticsService;

  EnhancedAnalyticsNotifier(this._analyticsService) : super(const EnhancedAnalyticsState());

  /// Load all analytics data
  Future<void> loadAllAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    AppLogger.function('EnhancedAnalyticsNotifier.loadAllAnalytics', 'ENTER',
        params: {
          'restaurantId': restaurantId,
          'startDate': startDate,
          'endDate': endDate,
          'useCache': useCache,
        });

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      // Load all analytics in parallel for better performance
      final results = await Future.wait([
        loadRevenueAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: useCache),
        loadCustomerAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: useCache),
        loadMenuAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: useCache),
        loadRealTimeMetrics(restaurantId),
        loadReports(restaurantId),
        loadPredictiveAnalytics(restaurantId),
        loadBenchmarks(restaurantId),
      ]);

      state = state.copyWith(
        isLoading: false,
      );

      AppLogger.success('All analytics loaded successfully');
      AppLogger.function('EnhancedAnalyticsNotifier.loadAllAnalytics', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load all analytics', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load analytics. Please try again.',
      );
    }
  }

  /// Load revenue analytics
  Future<void> loadRevenueAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    state = state.copyWith(isLoadingRevenue: true);

    try {
      final analytics = await _analyticsService.getAdvancedRevenueAnalytics(
        restaurantId,
        startDate: startDate,
        endDate: endDate,
        useCache: useCache,
      );

      state = state.copyWith(
        isLoadingRevenue: false,
        revenueAnalytics: analytics,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load revenue analytics', error: e, stack: stack);
      state = state.copyWith(
        isLoadingRevenue: false,
        errorMessage: 'Failed to load revenue analytics.',
      );
    }
  }

  /// Load customer analytics
  Future<void> loadCustomerAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    state = state.copyWith(isLoadingCustomer: true);

    try {
      final analytics = await _analyticsService.getAdvancedCustomerAnalytics(
        restaurantId,
        startDate: startDate,
        endDate: endDate,
        useCache: useCache,
      );

      state = state.copyWith(
        isLoadingCustomer: false,
        customerAnalytics: analytics,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load customer analytics', error: e, stack: stack);
      state = state.copyWith(
        isLoadingCustomer: false,
        errorMessage: 'Failed to load customer analytics.',
      );
    }
  }

  /// Load menu analytics
  Future<void> loadMenuAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    state = state.copyWith(isLoadingMenu: true);

    try {
      final analytics = await _analyticsService.getAdvancedMenuAnalytics(
        restaurantId,
        startDate: startDate,
        endDate: endDate,
        useCache: useCache,
      );

      state = state.copyWith(
        isLoadingMenu: false,
        menuAnalytics: analytics,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load menu analytics', error: e, stack: stack);
      state = state.copyWith(
        isLoadingMenu: false,
        errorMessage: 'Failed to load menu analytics.',
      );
    }
  }

  /// Load real-time metrics
  Future<void> loadRealTimeMetrics(String restaurantId) async {
    state = state.copyWith(isLoadingRealTime: true);

    try {
      final metrics = await _analyticsService.getRealTimeMetrics(restaurantId);

      state = state.copyWith(
        isLoadingRealTime: false,
        realTimeMetrics: metrics,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load real-time metrics', error: e, stack: stack);
      state = state.copyWith(
        isLoadingRealTime: false,
        errorMessage: 'Failed to load real-time metrics.',
      );
    }
  }

  /// Load analytics reports
  Future<void> loadReports(String restaurantId) async {
    state = state.copyWith(isLoadingReports: true);

    try {
      // This would need to be implemented in the service
      // For now, we'll use empty list
      state = state.copyWith(
        isLoadingReports: false,
        reports: [],
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load reports', error: e, stack: stack);
      state = state.copyWith(
        isLoadingReports: false,
        errorMessage: 'Failed to load reports.',
      );
    }
  }

  /// Load predictive analytics
  Future<void> loadPredictiveAnalytics(String restaurantId) async {
    state = state.copyWith(isLoadingPredictions: true);

    try {
      final predictions = await _analyticsService.getPredictiveAnalytics(restaurantId);

      state = state.copyWith(
        isLoadingPredictions: false,
        predictions: predictions,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load predictive analytics', error: e, stack: stack);
      state = state.copyWith(
        isLoadingPredictions: false,
        errorMessage: 'Failed to load predictive analytics.',
      );
    }
  }

  /// Load benchmarks
  Future<void> loadBenchmarks(String restaurantId) async {
    try {
      final benchmarks = await _analyticsService.getPerformanceBenchmarks();

      state = state.copyWith(benchmarks: benchmarks);
    } catch (e, stack) {
      AppLogger.error('Failed to load benchmarks', error: e, stack: stack);
      // Don't set error state for benchmarks as it's not critical
    }
  }

  /// Update date range and reload analytics
  Future<void> updateDateRange(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await loadAllAnalytics(
      restaurantId,
      startDate: startDate,
      endDate: endDate,
      useCache: false, // Don't use cache when date range changes
    );
  }

  /// Refresh specific analytics type
  Future<void> refreshAnalyticsType(
    String restaurantId,
    String type, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    switch (type.toLowerCase()) {
      case 'revenue':
        await loadRevenueAnalytics(
          restaurantId,
          startDate: startDate ?? state.startDate,
          endDate: endDate ?? state.endDate,
          useCache: false,
        );
        break;
      case 'customer':
        await loadCustomerAnalytics(
          restaurantId,
          startDate: startDate ?? state.startDate,
          endDate: endDate ?? state.endDate,
          useCache: false,
        );
        break;
      case 'menu':
        await loadMenuAnalytics(
          restaurantId,
          startDate: startDate ?? state.startDate,
          endDate: endDate ?? state.endDate,
          useCache: false,
        );
        break;
      case 'realtime':
        await loadRealTimeMetrics(restaurantId);
        break;
      case 'predictions':
        await loadPredictiveAnalytics(restaurantId);
        break;
      default:
        await loadAllAnalytics(
          restaurantId,
          startDate: startDate ?? state.startDate,
          endDate: endDate ?? state.endDate,
          useCache: false,
        );
    }
  }

  /// Generate analytics report
  Future<AnalyticsReport> generateReport(
    String restaurantId, {
    required String reportName,
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? additionalParameters,
  }) async {
    try {
      final report = await _analyticsService.generateAnalyticsReport(
        restaurantId,
        reportName: reportName,
        reportType: reportType,
        startDate: startDate ?? state.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        endDate: endDate ?? state.endDate ?? DateTime.now(),
        additionalParameters: additionalParameters,
      );

      // Refresh reports list
      await loadReports(restaurantId);

      return report;
    } catch (e, stack) {
      AppLogger.error('Failed to generate report', error: e, stack: stack);
      rethrow;
    }
  }

  /// Clear cache and reload
  Future<void> clearCacheAndReload(String restaurantId) async {
    try {
      await _analyticsService.clearCache(restaurantId);
      await loadAllAnalytics(
        restaurantId,
        startDate: state.startDate,
        endDate: state.endDate,
        useCache: false,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to clear cache and reload', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to clear cache and reload data.',
      );
    }
  }

  /// Update real-time metrics (called periodically)
  Future<void> updateRealTimeMetrics(String restaurantId) async {
    if (state.restaurantId != null) {
      await loadRealTimeMetrics(restaurantId);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset state
  void reset() {
    state = const EnhancedAnalyticsState();
  }
}

/// Enhanced Analytics Provider
final enhancedAnalyticsProvider = StateNotifierProvider<EnhancedAnalyticsNotifier, EnhancedAnalyticsState>((ref) {
  final analyticsService = EnhancedAnalyticsService();
  return EnhancedAnalyticsNotifier(analyticsService);
});

/// Individual providers for specific analytics types
final revenueAnalyticsProvider = Provider<AdvancedRevenueAnalytics?>((ref) {
  return ref.watch(enhancedAnalyticsProvider).revenueAnalytics;
});

final customerAnalyticsProvider = Provider<AdvancedCustomerAnalytics?>((ref) {
  return ref.watch(enhancedAnalyticsProvider).customerAnalytics;
});

final menuAnalyticsProvider = Provider<AdvancedMenuAnalytics?>((ref) {
  return ref.watch(enhancedAnalyticsProvider).menuAnalytics;
});

final realTimeMetricsProvider = Provider<RealTimeMetrics?>((ref) {
  return ref.watch(enhancedAnalyticsProvider).realTimeMetrics;
});

final analyticsReportsProvider = Provider<List<AnalyticsReport>>((ref) {
  return ref.watch(enhancedAnalyticsProvider).reports;
});

final predictiveAnalyticsProvider = Provider<List<PredictiveAnalytics>>((ref) {
  return ref.watch(enhancedAnalyticsProvider).predictions;
});

final analyticsBenchmarksProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(enhancedAnalyticsProvider).benchmarks;
});

final analyticsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(enhancedAnalyticsProvider).summaryStats;
});

/// Real-time metrics stream provider
final realTimeMetricsStreamProvider = StreamProvider.family<RealTimeMetrics, String>((ref, restaurantId) {
  final analyticsService = EnhancedAnalyticsService();
  return analyticsService.streamRealTimeMetrics(restaurantId);
});

/// Analytics loading states
final analyticsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(enhancedAnalyticsProvider).isAnyLoading;
});

final analyticsErrorProvider = Provider<String?>((ref) {
  return ref.watch(enhancedAnalyticsProvider).errorMessage;
});

/// Date range provider
final analyticsDateRangeProvider = Provider<Map<String, DateTime?>>((ref) {
  final state = ref.watch(enhancedAnalyticsProvider);
  return {
    'startDate': state.startDate,
    'endDate': state.endDate,
  };
});