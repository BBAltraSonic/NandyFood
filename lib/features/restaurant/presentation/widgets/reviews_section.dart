import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/review_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/reviews_screen.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/review_card.dart';

class ReviewsSection extends ConsumerStatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const ReviewsSection({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  @override
  void initState() {
    super.initState();
    // Load reviews on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadReviews(widget.restaurantId, refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);
    final stats = reviewState.stats;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with view all button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Reviews & Ratings',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewsScreen(
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                      ),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Overall rating and breakdown
          if (stats != null) ...[
            ReviewSummaryCard(
              averageRating: stats['averageRating'],
              totalReviews: stats['totalReviews'],
              distribution: Map<int, int>.from(stats['ratingDistribution']),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewsScreen(
                      restaurantId: widget.restaurantId,
                      restaurantName: widget.restaurantName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],

          // Show first 3 reviews
          if (reviewState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (reviewState.reviews.isEmpty)
            _buildEmptyState()
          else ...[
            ...reviewState.reviews.take(3).map((review) => ReviewCard(
                  review: review,
                  isUserReview: false,
                )),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewsScreen(
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.rate_review),
                label: const Text('See All Reviews'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black87),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to review this restaurant!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
