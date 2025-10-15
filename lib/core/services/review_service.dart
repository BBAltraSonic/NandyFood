import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/review.dart';
import 'package:uuid/uuid.dart';

/// Service for managing restaurant reviews
class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final DatabaseService _dbService = DatabaseService();
  final Uuid _uuid = const Uuid();

  /// Get reviews for a restaurant
  Future<List<Review>> getRestaurantReviews(
    String restaurantId, {
    int limit = 20,
    int offset = 0,
    String? orderBy = 'created_at',
    bool ascending = false,
  }) async {
    AppLogger.function('ReviewService.getRestaurantReviews', 'ENTER', params: {
      'restaurantId': restaurantId,
      'limit': limit,
      'offset': offset,
    });

    try {
      final response = await _dbService.client
          .from('reviews')
          .select('''
            *,
            user:user_id (
              id,
              full_name,
              avatar_url
            )
          ''')
          .eq('restaurant_id', restaurantId)
          .order(orderBy!, ascending: ascending)
          .range(offset, offset + limit - 1);

      final reviews = (response as List).map((json) {
        // Flatten user data
        if (json['user'] != null) {
          json['user_name'] = json['user']['full_name'];
          json['user_avatar'] = json['user']['avatar_url'];
        }
        return Review.fromJson(json as Map<String, dynamic>);
      }).toList();

      AppLogger.success('Fetched ${reviews.length} reviews');
      AppLogger.function('ReviewService.getRestaurantReviews', 'EXIT',
          result: reviews.length);

      return reviews;
    } catch (e, stack) {
      AppLogger.error('Failed to get restaurant reviews',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get review statistics for a restaurant
  Future<Map<String, dynamic>> getReviewStats(String restaurantId) async {
    AppLogger.function('ReviewService.getReviewStats', 'ENTER',
        params: {'restaurantId': restaurantId});

    try {
      final response = await _dbService.client
          .from('reviews')
          .select('rating')
          .eq('restaurant_id', restaurantId);

      final reviews = response as List;
      
      if (reviews.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        };
      }

      // Calculate average
      final ratings = reviews.map((r) => r['rating'] as int).toList();
      final sum = ratings.reduce((a, b) => a + b);
      final average = sum / ratings.length;

      // Calculate distribution
      final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      for (final rating in ratings) {
        distribution[rating] = (distribution[rating] ?? 0) + 1;
      }

      final stats = {
        'averageRating': double.parse(average.toStringAsFixed(1)),
        'totalReviews': reviews.length,
        'ratingDistribution': distribution,
      };

      AppLogger.success('Review stats calculated', details: stats.toString());
      AppLogger.function('ReviewService.getReviewStats', 'EXIT', result: stats);

      return stats;
    } catch (e, stack) {
      AppLogger.error('Failed to get review stats', error: e, stack: stack);
      rethrow;
    }
  }

  /// Create a new review
  Future<Review> createReview({
    required String restaurantId,
    required String userId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    AppLogger.function('ReviewService.createReview', 'ENTER', params: {
      'restaurantId': restaurantId,
      'userId': userId,
      'rating': rating,
    });

    try {
      // Validate rating
      if (rating < 1 || rating > 5) {
        throw ArgumentError('Rating must be between 1 and 5');
      }

      // Validate comment
      if (comment.trim().isEmpty) {
        throw ArgumentError('Comment cannot be empty');
      }

      final reviewId = _uuid.v4();
      final now = DateTime.now();

      final reviewData = {
        'id': reviewId,
        'restaurant_id': restaurantId,
        'user_id': userId,
        'rating': rating,
        'comment': comment.trim(),
        'photo_urls': photoUrls ?? [],
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _dbService.client.from('reviews').insert(reviewData);

      AppLogger.success('Review created successfully');

      // Fetch the created review with user data
      final reviews = await getRestaurantReviews(restaurantId, limit: 1);
      final createdReview = reviews.firstWhere(
        (r) => r.id == reviewId,
        orElse: () => Review(
          id: reviewId,
          restaurantId: restaurantId,
          userId: userId,
          rating: rating,
          comment: comment,
          createdAt: now,
        ),
      );

      AppLogger.function('ReviewService.createReview', 'EXIT',
          result: createdReview);

      return createdReview;
    } catch (e, stack) {
      AppLogger.error('Failed to create review', error: e, stack: stack);
      rethrow;
    }
  }

  /// Update an existing review
  Future<Review> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<String>? photoUrls,
  }) async {
    AppLogger.function('ReviewService.updateReview', 'ENTER',
        params: {'reviewId': reviewId});

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) {
        if (rating < 1 || rating > 5) {
          throw ArgumentError('Rating must be between 1 and 5');
        }
        updateData['rating'] = rating;
      }

      if (comment != null) {
        if (comment.trim().isEmpty) {
          throw ArgumentError('Comment cannot be empty');
        }
        updateData['comment'] = comment.trim();
      }

      if (photoUrls != null) {
        updateData['photo_urls'] = photoUrls;
      }

      final response = await _dbService.client
          .from('reviews')
          .update(updateData)
          .eq('id', reviewId)
          .select()
          .single();

      final updatedReview = Review.fromJson(response);

      AppLogger.success('Review updated successfully');
      AppLogger.function('ReviewService.updateReview', 'EXIT',
          result: updatedReview);

      return updatedReview;
    } catch (e, stack) {
      AppLogger.error('Failed to update review', error: e, stack: stack);
      rethrow;
    }
  }

  /// Delete a review
  Future<void> deleteReview(String reviewId) async {
    AppLogger.function('ReviewService.deleteReview', 'ENTER',
        params: {'reviewId': reviewId});

    try {
      await _dbService.client.from('reviews').delete().eq('id', reviewId);

      AppLogger.success('Review deleted successfully');
      AppLogger.function('ReviewService.deleteReview', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to delete review', error: e, stack: stack);
      rethrow;
    }
  }

  /// Check if user has already reviewed a restaurant
  Future<Review?> getUserReview(String restaurantId, String userId) async {
    AppLogger.function('ReviewService.getUserReview', 'ENTER', params: {
      'restaurantId': restaurantId,
      'userId': userId,
    });

    try {
      final response = await _dbService.client
          .from('reviews')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        AppLogger.info('No existing review found');
        return null;
      }

      final review = Review.fromJson(response);
      AppLogger.success('Found existing review');
      AppLogger.function('ReviewService.getUserReview', 'EXIT', result: review);

      return review;
    } catch (e, stack) {
      AppLogger.error('Failed to get user review', error: e, stack: stack);
      rethrow;
    }
  }

  /// Mark review as helpful
  Future<void> markReviewHelpful(String reviewId, String userId) async {
    AppLogger.function('ReviewService.markReviewHelpful', 'ENTER', params: {
      'reviewId': reviewId,
      'userId': userId,
    });

    try {
      // Check if already marked helpful
      final existing = await _dbService.client
          .from('review_helpful')
          .select()
          .eq('review_id', reviewId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Already marked, unmark it
        await _dbService.client
            .from('review_helpful')
            .delete()
            .eq('review_id', reviewId)
            .eq('user_id', userId);
        AppLogger.info('Unmarked review as helpful');
      } else {
        // Mark as helpful
        await _dbService.client.from('review_helpful').insert({
          'id': _uuid.v4(),
          'review_id': reviewId,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        });
        AppLogger.info('Marked review as helpful');
      }

      AppLogger.function('ReviewService.markReviewHelpful', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to mark review as helpful',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get helpful count for a review
  Future<int> getHelpfulCount(String reviewId) async {
    try {
      final response = await _dbService.client
          .from('review_helpful')
          .select('id')
          .eq('review_id', reviewId);

      return (response as List).length;
    } catch (e) {
      AppLogger.warning('Failed to get helpful count: $e');
      return 0;
    }
  }
}
