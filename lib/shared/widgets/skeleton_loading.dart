import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/widgets/shimmer_widget.dart';

/// Skeleton loading widget for restaurant cards
class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          const ShimmerBox(
            width: double.infinity,
            height: 180,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant name
                const ShimmerBox(
                  width: 200,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 8),
                // Cuisine type
                const ShimmerBox(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                const SizedBox(height: 12),
                // Rating and delivery info
                Row(
                  children: [
                    const ShimmerBox(
                      width: 60,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const SizedBox(width: 16),
                    const ShimmerBox(
                      width: 80,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    const Spacer(),
                    ShimmerBox(
                      width: 50,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loading widget for menu item cards
class MenuItemCardSkeleton extends StatelessWidget {
  const MenuItemCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Menu item image
            const ShimmerBox(
              width: 80,
              height: 80,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  const ShimmerBox(
                    width: double.infinity,
                    height: 18,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  const SizedBox(height: 8),
                  // Description
                  const ShimmerBox(
                    width: double.infinity,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  const SizedBox(height: 4),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 14,
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                  ),
                  const SizedBox(height: 8),
                  // Price
                  const ShimmerBox(
                    width: 60,
                    height: 16,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading widget for review cards
class ReviewCardSkeleton extends StatelessWidget {
  const ReviewCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // User avatar
                const ShimmerBox(
                  width: 40,
                  height: 40,
                  shape: BoxShape.circle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name
                      const ShimmerBox(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                      const SizedBox(height: 4),
                      // Date and rating
                      ShimmerBox(
                        width: 80,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Review text
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 6),
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 6),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading widget for order cards
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Order number
                const ShimmerBox(
                  width: 100,
                  height: 18,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                // Status badge
                ShimmerBox(
                  width: 70,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Restaurant name
            const ShimmerBox(
              width: 150,
              height: 16,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 8),
            // Order date
            const ShimmerBox(
              width: 100,
              height: 14,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 12),
            // Price
            const ShimmerBox(
              width: 80,
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading widget for promotion cards
class PromotionCardSkeleton extends StatelessWidget {
  const PromotionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Discount badge
                ShimmerBox(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
                // Expiry
                const ShimmerBox(
                  width: 60,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Promotion title
            const ShimmerBox(
              width: double.infinity,
              height: 18,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 8),
            // Description
            const ShimmerBox(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 4),
            ShimmerBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 14,
              borderRadius: const BorderRadius.all(Radius.circular(4)),
            ),
            const SizedBox(height: 12),
            // Apply button
            ShimmerBox(
              width: double.infinity,
              height: 40,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget to show multiple skeleton cards in a list
class SkeletonList extends StatelessWidget {
  final Widget skeletonCard;
  final int itemCount;

  const SkeletonList({
    super.key,
    required this.skeletonCard,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => skeletonCard,
    );
  }
}
