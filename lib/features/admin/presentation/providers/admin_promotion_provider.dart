import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/promotion_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';
import 'package:uuid/uuid.dart';

/// Admin Promotion State
class AdminPromotionState {
  final List<Promotion> activePromotions;
  final List<Promotion> draftPromotions;
  final List<Promotion> expiredPromotions;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  AdminPromotionState({
    this.activePromotions = const [],
    this.draftPromotions = const [],
    this.expiredPromotions = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminPromotionState copyWith({
    List<Promotion>? activePromotions,
    List<Promotion>? draftPromotions,
    List<Promotion>? expiredPromotions,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return AdminPromotionState(
      activePromotions: activePromotions ?? this.activePromotions,
      draftPromotions: draftPromotions ?? this.draftPromotions,
      expiredPromotions: expiredPromotions ?? this.expiredPromotions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
      successMessage: clearSuccess ? null : successMessage,
    );
  }
}

/// Admin Promotion Notifier
class AdminPromotionNotifier extends StateNotifier<AdminPromotionState> {
  AdminPromotionNotifier() : super(AdminPromotionState());

  final PromotionService _promotionService = PromotionService();

  /// Load all promotions for admin management
  Future<void> loadAllPromotions() async {
    AppLogger.function('AdminPromotionNotifier.loadAllPromotions', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final allPromotions = await _promotionService.getAllPromotions();

      final active = <Promotion>[];
      final draft = <Promotion>[];
      final expired = <Promotion>[];

      final now = DateTime.now();

      for (final promotion in allPromotions) {
        if (promotion.isExpired) {
          expired.add(promotion);
        } else if (promotion.status == PromotionStatus.inactive) {
          draft.add(promotion);
        } else {
          active.add(promotion);
        }
      }

      state = state.copyWith(
        activePromotions: active,
        draftPromotions: draft,
        expiredPromotions: expired,
        isLoading: false,
      );

      AppLogger.success('Loaded ${allPromotions.length} total promotions');
      AppLogger.function('AdminPromotionNotifier.loadAllPromotions', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load promotions', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load promotions. Please try again.',
      );
    }
  }

  /// Create a new promotion
  Future<bool> createPromotion({
    required String title,
    required String description,
    required String code,
    required PromotionType type,
    required double value,
    required DateTime startDate,
    required DateTime endDate,
    int? usageLimit,
    double? minOrderAmount,
    bool isFirstOrderOnly = false,
    String? restaurantId,
  }) async {
    AppLogger.function('AdminPromotionNotifier.createPromotion', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final promotion = Promotion(
        id: const Uuid().v4(),
        title: title,
        description: description,
        code: code.toUpperCase(),
        promotionType: type,
        discountValue: value,
        startDate: startDate,
        endDate: endDate,
        usageLimit: usageLimit,
        minOrderAmount: minOrderAmount,
        isFirstOrderOnly: isFirstOrderOnly,
        restaurantId: restaurantId,
        status: PromotionStatus.inactive, // Start as draft
        createdAt: DateTime.now(),
      );

      await _promotionService.createPromotion(promotion);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Promotion created successfully',
      );

      // Reload all promotions to update the lists
      await loadAllPromotions();

      AppLogger.success('Created promotion: ${promotion.code}');
      AppLogger.function('AdminPromotionNotifier.createPromotion', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to create promotion', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create promotion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Update an existing promotion
  Future<bool> updatePromotion(Promotion promotion) async {
    AppLogger.function('AdminPromotionNotifier.updatePromotion', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      // Update the promotion (Note: DateTime.now() will be set by the database)
      await _promotionService.updatePromotion(promotion);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Promotion updated successfully',
      );

      // Reload all promotions to update the lists
      await loadAllPromotions();

      AppLogger.success('Updated promotion: ${promotion.code}');
      AppLogger.function('AdminPromotionNotifier.updatePromotion', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to update promotion', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update promotion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete a promotion
  Future<bool> deletePromotion(String promotionId) async {
    AppLogger.function('AdminPromotionNotifier.deletePromotion', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      await _promotionService.deletePromotion(promotionId);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Promotion deleted successfully',
      );

      // Reload all promotions to update the lists
      await loadAllPromotions();

      AppLogger.success('Deleted promotion: $promotionId');
      AppLogger.function('AdminPromotionNotifier.deletePromotion', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to delete promotion', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete promotion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Duplicate a promotion
  Future<bool> duplicatePromotion(Promotion originalPromotion) async {
    AppLogger.function('AdminPromotionNotifier.duplicatePromotion', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final duplicatedPromotion = Promotion(
        id: const Uuid().v4(),
        title: '${originalPromotion.title} (Copy)',
        description: originalPromotion.description,
        code: '${originalPromotion.code}_COPY',
        promotionType: originalPromotion.promotionType,
        discountValue: originalPromotion.discountValue,
        startDate: originalPromotion.startDate,
        endDate: originalPromotion.endDate,
        usageLimit: originalPromotion.usageLimit,
        minOrderAmount: originalPromotion.minOrderAmount,
        isFirstOrderOnly: originalPromotion.isFirstOrderOnly,
        restaurantId: originalPromotion.restaurantId,
        status: PromotionStatus.inactive, // Start as draft
        createdAt: DateTime.now(),
      );

      await _promotionService.createPromotion(duplicatedPromotion);

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Promotion duplicated successfully',
      );

      // Reload all promotions to update the lists
      await loadAllPromotions();

      AppLogger.success('Duplicated promotion: ${originalPromotion.code}');
      AppLogger.function('AdminPromotionNotifier.duplicatePromotion', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to duplicate promotion', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to duplicate promotion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Activate a draft promotion
  Future<bool> activatePromotion(String promotionId) async {
    AppLogger.function('AdminPromotionNotifier.activatePromotion', 'ENTER');

    try {
      final promotion = await _promotionService.getPromotionById(promotionId);
      if (promotion == null) {
        state = state.copyWith(errorMessage: 'Promotion not found');
        return false;
      }

      final activatedPromotion = Promotion(
        id: promotion.id,
        title: promotion.title,
        description: promotion.description,
        code: promotion.code,
        promotionType: promotion.promotionType,
        discountValue: promotion.discountValue,
        startDate: promotion.startDate,
        endDate: promotion.endDate,
        usageLimit: promotion.usageLimit,
        usageCount: promotion.usageCount,
        userUsageLimit: promotion.userUsageLimit,
        minOrderAmount: promotion.minOrderAmount,
        maxDiscountAmount: promotion.maxDiscountAmount,
        isFirstOrderOnly: promotion.isFirstOrderOnly,
        restaurantId: promotion.restaurantId,
        status: PromotionStatus.active,
        createdAt: promotion.createdAt,
      );

      await _promotionService.updatePromotion(activatedPromotion);

      state = state.copyWith(successMessage: 'Promotion activated successfully');
      await loadAllPromotions();

      AppLogger.success('Activated promotion: $promotionId');
      AppLogger.function('AdminPromotionNotifier.activatePromotion', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to activate promotion', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to activate promotion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Deactivate an active promotion
  Future<bool> deactivatePromotion(String promotionId) async {
    AppLogger.function('AdminPromotionNotifier.deactivatePromotion', 'ENTER');

    try {
      final promotion = await _promotionService.getPromotionById(promotionId);
      if (promotion == null) {
        state = state.copyWith(errorMessage: 'Promotion not found');
        return false;
      }

      final deactivatedPromotion = Promotion(
        id: promotion.id,
        title: promotion.title,
        description: promotion.description,
        code: promotion.code,
        promotionType: promotion.promotionType,
        discountValue: promotion.discountValue,
        startDate: promotion.startDate,
        endDate: promotion.endDate,
        usageLimit: promotion.usageLimit,
        usageCount: promotion.usageCount,
        userUsageLimit: promotion.userUsageLimit,
        minOrderAmount: promotion.minOrderAmount,
        maxDiscountAmount: promotion.maxDiscountAmount,
        isFirstOrderOnly: promotion.isFirstOrderOnly,
        restaurantId: promotion.restaurantId,
        status: PromotionStatus.inactive,
        createdAt: promotion.createdAt,
      );

      await _promotionService.updatePromotion(deactivatedPromotion);

      state = state.copyWith(successMessage: 'Promotion deactivated successfully');
      await loadAllPromotions();

      AppLogger.success('Deactivated promotion: $promotionId');
      AppLogger.function('AdminPromotionNotifier.deactivatePromotion', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to deactivate promotion', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to deactivate promotion: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear messages
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

/// Admin Promotion Provider
final adminPromotionProvider = StateNotifierProvider<AdminPromotionNotifier, AdminPromotionState>((ref) {
  return AdminPromotionNotifier();
});