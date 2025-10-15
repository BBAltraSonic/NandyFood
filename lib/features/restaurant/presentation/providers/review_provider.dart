import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/review_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/review.dart';

/// Review state
class ReviewState {
  final List<Review> reviews;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? stats;
  final bool hasMore;

  ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.errorMessage,
    this.stats,
    this.hasMore = true,
  });

  ReviewState copyWith({
    List<Review>? reviews,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? stats,
    bool? hasMore,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Review notifier
class ReviewNotifier extends StateNotifier<ReviewState> {
  ReviewNotifier() : super(ReviewState());

  final ReviewService _reviewService = ReviewService();
  String? _currentRestaurantId;
  int _offset = 0;
  static const int _limit = 20;

  /// Load reviews for a restaurant
  Future<void> loadReviews(String restaurantId, {bool refresh = false}) async {
    AppLogger.function('ReviewNotifier.loadReviews', 'ENTER', params: {
      'restaurantId': restaurantId,
      'refresh': refresh,
    });

    if (refresh) {
      _offset = 0;
      _currentRestaurantId = restaurantId;
      state = ReviewState(isLoading: true);
    } else {
      if (state.isLoading || !state.hasMore) return;
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      // Load reviews and stats in parallel
      final results = await Future.wait([
        _reviewService.getRestaurantReviews(
          restaurantId,
          limit: _limit,
          offset: _offset,
          orderBy: 'created_at',
          ascending: false,
        ),
        if (refresh) _reviewService.getReviewStats(restaurantId),
      ]);

      final newReviews = results[0] as List<Review>;
      final stats = results.length > 1 ? results[1] as Map<String, dynamic> : state.stats;

      final allReviews = refresh ? newReviews : [...state.reviews, ...newReviews];
      _offset += newReviews.length;

      state = state.copyWith(
        reviews: allReviews,
        isLoading: false,
        stats: stats,
        hasMore: newReviews.length == _limit,
      );

      AppLogger.success('Loaded ${newReviews.length} reviews');
      AppLogger.function('ReviewNotifier.loadReviews', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load reviews', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load reviews. Please try again.',
      );
    }
  }

  /// Load more reviews (pagination)
  Future<void> loadMore() async {
    if (_currentRestaurantId != null) {
      await loadReviews(_currentRestaurantId!, refresh: false);
    }
  }

  /// Refresh reviews
  Future<void> refresh() async {
    if (_currentRestaurantId != null) {
      await loadReviews(_currentRestaurantId!, refresh: true);
    }
  }

  /// Add a new review
  Future<bool> addReview({
    required String restaurantId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    AppLogger.function('ReviewNotifier.addReview', 'ENTER');

    try {
      final review = await _reviewService.createReview(
        restaurantId: restaurantId,
        userId: userId,
        rating: rating,
        comment: comment,
      );

      // Add to beginning of list
      state = state.copyWith(
        reviews: [review, ...state.reviews],
      );

      // Reload stats
      final stats = await _reviewService.getReviewStats(restaurantId);
      state = state.copyWith(stats: stats);

      AppLogger.success('Review added successfully');
      AppLogger.function('ReviewNotifier.addReview', 'EXIT', result: true);

      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to add review', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to submit review. Please try again.',
      );
      return false;
    }
  }

  /// Update a review
  Future<bool> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
  }) async {
    AppLogger.function('ReviewNotifier.updateReview', 'ENTER');

    try {
      final updatedReview = await _reviewService.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );

      // Update in list
      final updatedReviews = state.reviews.map((r) {
        return r.id == reviewId ? updatedReview : r;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);

      // Reload stats
      if (_currentRestaurantId != null) {
        final stats = await _reviewService.getReviewStats(_currentRestaurantId!);
        state = state.copyWith(stats: stats);
      }

      AppLogger.success('Review updated successfully');
      AppLogger.function('ReviewNotifier.updateReview', 'EXIT', result: true);

      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to update review', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to update review. Please try again.',
      );
      return false;
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId) async {
    AppLogger.function('ReviewNotifier.deleteReview', 'ENTER');

    try {
      await _reviewService.deleteReview(reviewId);

      // Remove from list
      final updatedReviews = state.reviews.where((r) => r.id != reviewId).toList();
      state = state.copyWith(reviews: updatedReviews);

      // Reload stats
      if (_currentRestaurantId != null) {
        final stats = await _reviewService.getReviewStats(_currentRestaurantId!);
        state = state.copyWith(stats: stats);
      }

      AppLogger.success('Review deleted successfully');
      AppLogger.function('ReviewNotifier.deleteReview', 'EXIT', result: true);

      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to delete review', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to delete review. Please try again.',
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state
  void reset() {
    _currentRestaurantId = null;
    _offset = 0;
    state = ReviewState();
  }
}

/// Review provider
final reviewProvider = StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier();
});

/// Provider to check if user has reviewed a restaurant
final userReviewProvider = FutureProvider.autoDispose
    .family<Review?, (String, String)>((ref, params) async {
  final restaurantId = params.$1;
  final userId = params.$2;
  
  return ReviewService().getUserReview(restaurantId, userId);
});
