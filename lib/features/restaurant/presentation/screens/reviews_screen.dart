import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/review_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/write_review_screen.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/review_card.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';
import 'package:food_delivery_app/shared/widgets/skeleton_loading.dart';

/// Screen to display all reviews for a restaurant
class ReviewsScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ReviewsScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load reviews on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadReviews(widget.restaurantId, refresh: true);
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(reviewProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);
    final authState = ref.watch(authStateProvider);
    final userReviewAsync = authState.user != null
        ? ref.watch(userReviewProvider((widget.restaurantId, authState.user!.id)))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(reviewProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Stats summary
            if (reviewState.stats != null)
              SliverToBoxAdapter(
                child: ReviewSummaryCard(
                  averageRating: reviewState.stats!['averageRating'],
                  totalReviews: reviewState.stats!['totalReviews'],
                  distribution: Map<int, int>.from(
                    reviewState.stats!['ratingDistribution'],
                  ),
                ),
              ),
            // Write review button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: userReviewAsync?.when(
                  data: (existingReview) {
                    return ElevatedButton.icon(
                      onPressed: () => _navigateToWriteReview(existingReview),
                      icon: Icon(existingReview != null ? Icons.edit : Icons.rate_review),
                      label: Text(existingReview != null ? 'Edit Your Review' : 'Write a Review'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ) ??
                    const SizedBox.shrink(),
              ),
            ),
            // Reviews list
            if (reviewState.isLoading && reviewState.reviews.isEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ReviewCardSkeleton(),
                  childCount: 5,
                ),
              )
            else if (reviewState.errorMessage != null && reviewState.reviews.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        reviewState.errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(reviewProvider.notifier).refresh();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (reviewState.reviews.isEmpty)
              SliverFillRemaining(
                child: EmptyStateWidget.noReviews(
                  onWriteReview: authState.user != null ? () => _navigateToWriteReview(null) : null,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < reviewState.reviews.length) {
                      final review = reviewState.reviews[index];
                      final isUserReview = authState.user?.id == review.userId;

                      return ReviewCard(
                        review: review,
                        isUserReview: isUserReview,
                        onEdit: isUserReview
                            ? () => _navigateToWriteReview(review)
                            : null,
                        onDelete: isUserReview
                            ? () => _deleteReview(review.id)
                            : null,
                      );
                    } else if (reviewState.hasMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: reviewState.reviews.length + (reviewState.hasMore ? 1 : 0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToWriteReview(existingReview) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          existingReview: existingReview,
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh reviews after submission
      ref.read(reviewProvider.notifier).refresh();
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(reviewProvider.notifier).deleteReview(reviewId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
