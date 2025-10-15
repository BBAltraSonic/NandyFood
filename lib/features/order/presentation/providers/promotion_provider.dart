import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/promotion_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';

/// Promotion state
class PromotionState {
  final List<Promotion> availablePromotions;
  final Promotion? appliedPromotion;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  PromotionState({
    this.availablePromotions = const [],
    this.appliedPromotion,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  PromotionState copyWith({
    List<Promotion>? availablePromotions,
    Promotion? appliedPromotion,
    bool clearAppliedPromotion = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return PromotionState(
      availablePromotions: availablePromotions ?? this.availablePromotions,
      appliedPromotion: clearAppliedPromotion
          ? null
          : (appliedPromotion ?? this.appliedPromotion),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
      successMessage: clearSuccess ? null : successMessage,
    );
  }
}

/// Promotion notifier
class PromotionNotifier extends StateNotifier<PromotionState> {
  PromotionNotifier() : super(PromotionState());

  final PromotionService _promotionService = PromotionService();

  /// Load available promotions
  Future<void> loadPromotions({String? restaurantId}) async {
    AppLogger.function('PromotionNotifier.loadPromotions', 'ENTER',
        params: {'restaurantId': restaurantId});

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final promotions =
          await _promotionService.getActivePromotions(restaurantId: restaurantId);

      state = state.copyWith(
        availablePromotions: promotions,
        isLoading: false,
      );

      AppLogger.success('Loaded ${promotions.length} promotions');
      AppLogger.function('PromotionNotifier.loadPromotions', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load promotions', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load promotions. Please try again.',
      );
    }
  }

  /// Apply promotion code
  Future<bool> applyPromotionCode(
    String code, {
    required String userId,
    required double orderAmount,
    String? restaurantId,
    bool isFirstOrder = false,
  }) async {
    AppLogger.function('PromotionNotifier.applyPromotionCode', 'ENTER',
        params: {'code': code});

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final promotion = await _promotionService.validatePromotionCode(
        code,
        userId: userId,
        orderAmount: orderAmount,
        restaurantId: restaurantId,
        isFirstOrder: isFirstOrder,
      );

      if (promotion == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid or expired promotion code',
        );
        AppLogger.warning('Promotion code validation failed: $code');
        return false;
      }

      final discount = promotion.calculateDiscount(orderAmount);

      state = state.copyWith(
        appliedPromotion: promotion,
        isLoading: false,
        successMessage: 'Promotion applied! You save R${discount.toStringAsFixed(2)}',
      );

      AppLogger.success('Promotion applied successfully: $code');
      AppLogger.function('PromotionNotifier.applyPromotionCode', 'EXIT',
          result: true);

      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to apply promotion code', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to apply promotion. Please try again.',
      );
      return false;
    }
  }

  /// Remove applied promotion
  void removePromotion() {
    AppLogger.info('Removing applied promotion');
    state = state.copyWith(
      clearAppliedPromotion: true,
      clearSuccess: true,
    );
  }

  /// Calculate discount for current applied promotion
  double calculateDiscount(double orderAmount) {
    if (state.appliedPromotion == null) return 0.0;
    return state.appliedPromotion!.calculateDiscount(orderAmount);
  }

  /// Load recommended promotions
  Future<void> loadRecommendedPromotions({
    required String userId,
    String? restaurantId,
    double? orderAmount,
  }) async {
    AppLogger.function('PromotionNotifier.loadRecommendedPromotions', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final promotions = await _promotionService.getRecommendedPromotions(
        userId: userId,
        restaurantId: restaurantId,
        orderAmount: orderAmount,
      );

      state = state.copyWith(
        availablePromotions: promotions,
        isLoading: false,
      );

      AppLogger.success('Loaded ${promotions.length} recommended promotions');
      AppLogger.function('PromotionNotifier.loadRecommendedPromotions', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load recommended promotions',
          error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load recommendations.',
      );
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Reset state
  void reset() {
    state = PromotionState();
  }
}

/// Promotion provider
final promotionProvider =
    StateNotifierProvider<PromotionNotifier, PromotionState>((ref) {
  return PromotionNotifier();
});

/// Provider for first order promotions
final firstOrderPromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  return PromotionService().getFirstOrderPromotions();
});

/// Provider for user promotion history
final userPromotionHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return PromotionService().getUserPromotionHistory(userId);
});
