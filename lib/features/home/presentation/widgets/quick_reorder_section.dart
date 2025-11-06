import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

class QuickReorderSection extends ConsumerWidget {
  const QuickReorderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);

    // Get recent orders (should come from order service)
    final recentOrders = _getRecentOrders();

    if (recentOrders.isEmpty || authState.user == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [BrandColors.secondary, BrandColors.secondaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Reorder',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NeutralColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Order again in seconds',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NeutralColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to order history
                },
                child: Text(
                  'History',
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick reorder cards
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: recentOrders.length,
              itemBuilder: (context, index) {
                final order = recentOrders[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildReorderCard(context, order, theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderCard(BuildContext context, Map<String, dynamic> order, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(
          color: BrandColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Restaurant image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandColors.secondary.withValues(alpha: 0.1),
                    BrandColors.secondary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: order['image'] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      child: Image.network(
                        order['image'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.restaurant_outlined,
                            size: 32,
                            color: BrandColors.secondary,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.restaurant_outlined,
                      size: 32,
                      color: BrandColors.secondary,
                    ),
            ),
            const SizedBox(width: 16),

            // Order details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    order['restaurantName'],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order['items'],
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NeutralColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${order['total']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order['timeAgo'],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getRecentOrders() {
    // Return empty list for now - this should be connected to order service
    return [];
  }
}