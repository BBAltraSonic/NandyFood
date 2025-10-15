import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';

/// Service for managing promotions and discounts
class PromotionService {
  static final PromotionService _instance = PromotionService._internal();
  factory PromotionService() => _instance;
  PromotionService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Get all active promotions
  Future<List<Promotion>> getActivePromotions({String? restaurantId}) async {
    AppLogger.function('PromotionService.getActivePromotions', 'ENTER',
        params: {'restaurantId': restaurantId});

    try {
      var query = _dbService.client
          .from('promotions')
          .select()
          .eq('status', 'active')
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String());

      if (restaurantId != null) {
        query = query.or('restaurant_id.eq.$restaurantId,restaurant_id.is.null');
      } else {
        query = query.isFilter('restaurant_id', null);
      }

      final response = await query;
      final promotions = (response as List)
          .map((json) => Promotion.fromJson(json as Map<String, dynamic>))
          .where((p) => p.isValid)
          .toList();

      AppLogger.success('Fetched ${promotions.length} active promotions');
      AppLogger.function('PromotionService.getActivePromotions', 'EXIT',
          result: promotions.length);

      return promotions;
    } catch (e, stack) {
      AppLogger.error('Failed to get active promotions',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Validate and apply a promotion code
  Future<Promotion?> validatePromotionCode(
    String code, {
    required String userId,
    required double orderAmount,
    String? restaurantId,
    bool isFirstOrder = false,
  }) async {
    AppLogger.function('PromotionService.validatePromotionCode', 'ENTER',
        params: {
          'code': code,
          'userId': userId,
          'orderAmount': orderAmount,
        });

    try {
      // Fetch promotion by code
      final response = await _dbService.client
          .from('promotions')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('Promotion code not found: $code');
        return null;
      }

      final promotion = Promotion.fromJson(response as Map<String, dynamic>);

      // Validate promotion
      if (!promotion.isValid) {
        AppLogger.warning('Promotion is not valid: $code');
        return null;
      }

      // Check restaurant restriction
      if (promotion.restaurantId != null &&
          promotion.restaurantId != restaurantId) {
        AppLogger.warning(
            'Promotion not valid for this restaurant: $code, required: ${promotion.restaurantId}, got: $restaurantId');
        return null;
      }

      // Check minimum order amount
      if (promotion.minOrderAmount != null &&
          orderAmount < promotion.minOrderAmount!) {
        AppLogger.warning(
            'Order amount too low for promotion: $code, min: ${promotion.minOrderAmount}, got: $orderAmount');
        return null;
      }

      // Check first order restriction
      if (promotion.isFirstOrderOnly && !isFirstOrder) {
        AppLogger.warning('Promotion only valid for first orders: $code');
        return null;
      }

      // Check user usage limit
      if (promotion.userUsageLimit != null) {
        final userUsage = await _getUserPromotionUsageCount(
          userId,
          promotion.id,
        );
        if (userUsage >= promotion.userUsageLimit!) {
          AppLogger.warning(
              'User has exceeded usage limit for promotion: $code');
          return null;
        }
      }

      AppLogger.success('Promotion code validated successfully: $code');
      AppLogger.function('PromotionService.validatePromotionCode', 'EXIT',
          result: promotion);

      return promotion;
    } catch (e, stack) {
      AppLogger.error('Failed to validate promotion code',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get user's usage count for a promotion
  Future<int> _getUserPromotionUsageCount(
      String userId, String promotionId) async {
    try {
      final response = await _dbService.client
          .from('promotion_usage')
          .select('id')
          .eq('user_id', userId)
          .eq('promotion_id', promotionId);

      return (response as List).length;
    } catch (e) {
      AppLogger.warning('Failed to get user promotion usage count: $e');
      return 0;
    }
  }

  /// Record promotion usage
  Future<void> recordPromotionUsage({
    required String userId,
    required String promotionId,
    required String orderId,
    required double discountAmount,
  }) async {
    AppLogger.function('PromotionService.recordPromotionUsage', 'ENTER',
        params: {
          'userId': userId,
          'promotionId': promotionId,
          'orderId': orderId,
          'discountAmount': discountAmount,
        });

    try {
      // Record usage
      await _dbService.client.from('promotion_usage').insert({
        'user_id': userId,
        'promotion_id': promotionId,
        'order_id': orderId,
        'discount_amount': discountAmount,
        'used_at': DateTime.now().toIso8601String(),
      });

      // Increment usage count
      await _dbService.client.rpc('increment_promotion_usage', params: {
        'promotion_id': promotionId,
      });

      AppLogger.success('Promotion usage recorded successfully');
      AppLogger.function('PromotionService.recordPromotionUsage', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to record promotion usage',
          error: e, stack: stack);
      // Don't rethrow - this shouldn't block order placement
    }
  }

  /// Get user's promotion history
  Future<List<Map<String, dynamic>>> getUserPromotionHistory(
      String userId) async {
    AppLogger.function('PromotionService.getUserPromotionHistory', 'ENTER',
        params: {'userId': userId});

    try {
      final response = await _dbService.client
          .from('promotion_usage')
          .select('''
            *,
            promotion:promotion_id (
              code,
              title,
              promotion_type
            )
          ''')
          .eq('user_id', userId)
          .order('used_at', ascending: false)
          .limit(50);

      AppLogger.success('Fetched promotion history');
      AppLogger.function('PromotionService.getUserPromotionHistory', 'EXIT',
          result: (response as List).length);

      return (response).cast<Map<String, dynamic>>();
    } catch (e, stack) {
      AppLogger.error('Failed to get user promotion history',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Check if user has any first-time user promotions available
  Future<List<Promotion>> getFirstOrderPromotions() async {
    AppLogger.function('PromotionService.getFirstOrderPromotions', 'ENTER');

    try {
      final response = await _dbService.client
          .from('promotions')
          .select()
          .eq('status', 'active')
          .eq('is_first_order_only', true)
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String());

      final promotions = (response as List)
          .map((json) => Promotion.fromJson(json as Map<String, dynamic>))
          .where((p) => p.isValid)
          .toList();

      AppLogger.success('Fetched ${promotions.length} first order promotions');
      AppLogger.function('PromotionService.getFirstOrderPromotions', 'EXIT',
          result: promotions.length);

      return promotions;
    } catch (e, stack) {
      AppLogger.error('Failed to get first order promotions',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get promotion by ID
  Future<Promotion?> getPromotionById(String promotionId) async {
    AppLogger.function('PromotionService.getPromotionById', 'ENTER',
        params: {'promotionId': promotionId});

    try {
      final response = await _dbService.client
          .from('promotions')
          .select()
          .eq('id', promotionId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('Promotion not found: $promotionId');
        return null;
      }

      final promotion = Promotion.fromJson(response as Map<String, dynamic>);
      AppLogger.success('Promotion fetched successfully');
      AppLogger.function('PromotionService.getPromotionById', 'EXIT',
          result: promotion);

      return promotion;
    } catch (e, stack) {
      AppLogger.error('Failed to get promotion by ID', error: e, stack: stack);
      rethrow;
    }
  }

  /// Get recommended promotions for user
  Future<List<Promotion>> getRecommendedPromotions({
    required String userId,
    String? restaurantId,
    double? orderAmount,
  }) async {
    AppLogger.function('PromotionService.getRecommendedPromotions', 'ENTER',
        params: {
          'userId': userId,
          'restaurantId': restaurantId,
          'orderAmount': orderAmount,
        });

    try {
      final promotions = await getActivePromotions(restaurantId: restaurantId);

      // Filter and sort promotions
      final recommended = promotions.where((p) {
        // Filter by order amount if provided
        if (orderAmount != null && p.minOrderAmount != null) {
          return orderAmount >= p.minOrderAmount!;
        }
        return true;
      }).toList();

      // Sort by discount value
      recommended.sort((a, b) {
        final aDiscount = orderAmount != null
            ? a.calculateDiscount(orderAmount)
            : a.discountValue;
        final bDiscount = orderAmount != null
            ? b.calculateDiscount(orderAmount)
            : b.discountValue;
        return bDiscount.compareTo(aDiscount);
      });

      AppLogger.success('Found ${recommended.length} recommended promotions');
      AppLogger.function('PromotionService.getRecommendedPromotions', 'EXIT',
          result: recommended.length);

      return recommended;
    } catch (e, stack) {
      AppLogger.error('Failed to get recommended promotions',
          error: e, stack: stack);
      rethrow;
    }
  }
}
