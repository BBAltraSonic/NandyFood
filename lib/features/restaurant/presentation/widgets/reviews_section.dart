import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/review.dart';

class ReviewsSection extends StatefulWidget {
  final String restaurantId;
  final double overallRating;
  final Map<int, int> ratingBreakdown;
  final List<Review> initialReviews;
  final int totalReviews;
  final Future<List<Review>> Function(int offset) onLoadMore;

  const ReviewsSection({
    super.key,
    required this.restaurantId,
    required this.overallRating,
    required this.ratingBreakdown,
    required this.initialReviews,
    required this.totalReviews,
    required this.onLoadMore,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  late List<Review> _reviews;
  bool _isLoadingMore = false;
  bool _hasMoreReviews = true;

  @override
  void initState() {
    super.initState();
    _reviews = List.from(widget.initialReviews);
    _hasMoreReviews = _reviews.length < widget.totalReviews;
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMoreReviews) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newReviews = await widget.onLoadMore(_reviews.length);
      setState(() {
        _reviews.addAll(newReviews);
        _hasMoreReviews = _reviews.length < widget.totalReviews;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more reviews: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          const Text(
            'Reviews & Ratings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Overall rating and breakdown
          _buildRatingOverview(),
          const SizedBox(height: 24),

          // Reviews list
          if (_reviews.isEmpty)
            _buildEmptyState()
          else
            ..._reviews.map((review) => _buildReviewCard(review)),

          // Load more button
          if (_hasMoreReviews && !_isLoadingMore) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: _loadMoreReviews,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load More Reviews'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepOrange,
                  side: const BorderSide(color: Colors.deepOrange),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],

          // Loading indicator
          if (_isLoadingMore) ...[
            const SizedBox(height: 16),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    final totalReviews = widget.ratingBreakdown.values.reduce((a, b) => a + b);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall rating display
            Column(
              children: [
                Text(
                  widget.overallRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.overallRating.floor()
                          ? Icons.star
                          : (index < widget.overallRating
                              ? Icons.star_half
                              : Icons.star_border),
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Rating breakdown bars
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final starCount = 5 - index;
                  final count = widget.ratingBreakdown[starCount] ?? 0;
                  final percentage =
                      totalReviews > 0 ? count / totalReviews : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Text(
                          '$starCount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepOrange,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.deepOrange.shade100,
                  child: review.userAvatar != null
                      ? ClipOval(
                          child: Image.network(
                            review.userAvatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultAvatar(review.userName),
                          ),
                        )
                      : _buildDefaultAvatar(review.userName),
                ),
                const SizedBox(width: 12),

                // User name and time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'Anonymous',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating stars
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Review comment
            _buildReviewComment(review.comment),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(String? userName) {
    final initial = userName?.isNotEmpty == true ? userName![0].toUpperCase() : '?';
    return Text(
      initial,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.deepOrange,
      ),
    );
  }

  Widget _buildReviewComment(String comment) {
    // For now, show full comment. Can add "Read More" functionality later
    return Text(
      comment,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade700,
        height: 1.5,
      ),
      maxLines: null,
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
