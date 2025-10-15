import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/analytics_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/analytics_data.dart';

/// Analytics state
class AnalyticsState {
  final DashboardAnalytics? dashboardAnalytics;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? startDate;
  final DateTime? endDate;

  AnalyticsState({
    this.dashboardAnalytics,
    this.isLoading = false,
    this.errorMessage,
    this.startDate,
    this.endDate,
  });

  AnalyticsState copyWith({
    DashboardAnalytics? dashboardAnalytics,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return AnalyticsState(
      dashboardAnalytics: dashboardAnalytics ?? this.dashboardAnalytics,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

/// Analytics notifier
class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier() : super(AnalyticsState());

  final AnalyticsService _analyticsService = AnalyticsService();

  /// Load dashboard analytics
  Future<void> loadDashboardAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsNotifier.loadDashboardAnalytics', 'ENTER',
        params: {'restaurantId': restaurantId});

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      final analytics = await _analyticsService.getDashboardAnalytics(
        restaurantId,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        dashboardAnalytics: analytics,
        isLoading: false,
      );

      AppLogger.success('Dashboard analytics loaded');
      AppLogger.function('AnalyticsNotifier.loadDashboardAnalytics', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load dashboard analytics',
          error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load analytics. Please try again.',
      );
    }
  }

  /// Update date range and reload
  Future<void> updateDateRange(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await loadDashboardAnalytics(
      restaurantId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Refresh analytics
  Future<void> refresh(String restaurantId) async {
    await loadDashboardAnalytics(
      restaurantId,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset state
  void reset() {
    state = AnalyticsState();
  }
}

/// Analytics provider
final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier();
});

/// Provider for sales analytics
final salesAnalyticsProvider = FutureProvider.family<SalesAnalytics,
    (String, DateTime?, DateTime?)>((ref, params) async {
  final restaurantId = params.$1;
  final startDate = params.$2;
  final endDate = params.$3;
  
  return AnalyticsService().getSalesAnalytics(
    restaurantId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// Provider for revenue analytics
final revenueAnalyticsProvider = FutureProvider.family<RevenueAnalytics,
    (String, DateTime?, DateTime?)>((ref, params) async {
  final restaurantId = params.$1;
  final startDate = params.$2;
  final endDate = params.$3;
  
  return AnalyticsService().getRevenueAnalytics(
    restaurantId,
    startDate: startDate,
    endDate: endDate,
  );
});

/// Provider for customer analytics
final customerAnalyticsProvider = FutureProvider.family<CustomerAnalytics,
    (String, DateTime?, DateTime?)>((ref, params) async {
  final restaurantId = params.$1;
  final startDate = params.$2;
  final endDate = params.$3;
  
  return AnalyticsService().getCustomerAnalytics(
    restaurantId,
    startDate: startDate,
    endDate: endDate,
  );
});
