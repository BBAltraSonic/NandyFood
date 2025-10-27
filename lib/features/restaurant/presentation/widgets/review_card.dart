import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/review.dart';
import 'package:food_delivery_app/shared/widgets/rating_stars.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Card widget to display a single review
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isUserReview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onHelpful;
  final int helpfulCount;
  final bool isMarkedHelpful;

  const ReviewCard({
    Key? key,
    required this.review,
    this.isUserReview = false,
    this.onEdit,
    this.onDelete,
    this.onHelpful,
    this.helpfulCount = 0,
    this.isMarkedHelpful = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userAvatar != null
                      ? CachedNetworkImageProvider(review.userAvatar!)
                      : null,
                  child: review.userAvatar == null
                      ? Text(
                          (review.userName ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // User name and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        review.timeAgo,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rating
                RatingStars(
                  rating: review.rating,
                  size: 18,
                ),
                // Actions menu for user's own reviews
                if (isUserReview)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit' && onEdit != null) {
                        onEdit!();
                      } else if (value == 'delete' && onDelete != null) {
                        _showDeleteConfirmation(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Review comment
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            // Helpful button
            if (!isUserReview)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onHelpful,
                    icon: Icon(
                      isMarkedHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 18,
                    ),
                    label: Text(
                      helpfulCount > 0 ? 'Helpful ($helpfulCount)' : 'Helpful',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Compact review summary card for lists
class ReviewSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;
  final VoidCallback? onTap;

  const ReviewSummaryCard({
    Key? key,
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rating score
              Column(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RatingStars(
                    rating: averageRating.round(),
                    size: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews reviews',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Rating distribution
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = distribution[stars] ?? 0;
                    final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.end,
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
      ),
    );
  }
}
