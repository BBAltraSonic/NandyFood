import 'package:flutter/material.dart';

/// A reusable widget for displaying empty states throughout the app
/// 
/// Shows an icon, title, message, and optional action button when
/// a list or collection has no items to display.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    this.iconColor,
    this.iconSize = 80,
  });

  /// Empty state for no restaurants found
  factory EmptyStateWidget.noRestaurants({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.restaurant,
      title: 'No Restaurants Found',
      message: 'We couldn\'t find any restaurants in your area. Try adjusting your filters or search again.',
      actionText: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }

  /// Empty state for empty cart
  factory EmptyStateWidget.emptyCart({required VoidCallback onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'Your Cart is Empty',
      message: 'Add some delicious items from your favorite restaurants to get started!',
      actionText: 'Browse Restaurants',
      onAction: onBrowse,
    );
  }

  /// Empty state for no order history
  factory EmptyStateWidget.noOrders({required VoidCallback onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'No Orders Yet',
      message: 'You haven\'t placed any orders yet. Start exploring and order your first meal!',
      actionText: 'Explore Restaurants',
      onAction: onBrowse,
    );
  }

  /// Empty state for no reviews
  factory EmptyStateWidget.noReviews({VoidCallback? onWriteReview}) {
    return EmptyStateWidget(
      icon: Icons.rate_review_outlined,
      title: 'No Reviews Yet',
      message: onWriteReview != null
          ? 'Be the first to share your experience with this restaurant!'
          : 'This restaurant doesn\'t have any reviews yet.',
      actionText: onWriteReview != null ? 'Write a Review' : null,
      onAction: onWriteReview,
    );
  }

  /// Empty state for no promotions
  factory EmptyStateWidget.noPromotions({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.local_offer_outlined,
      title: 'No Promotions Available',
      message: 'There are no active promotions at the moment. Check back later for great deals!',
      actionText: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }

  /// Empty state for no saved addresses
  factory EmptyStateWidget.noAddresses({required VoidCallback onAddAddress}) {
    return EmptyStateWidget(
      icon: Icons.location_on_outlined,
      title: 'No Saved Addresses',
      message: 'Add a delivery address to start ordering food.',
      actionText: 'Add Address',
      onAction: onAddAddress,
    );
  }

  /// Empty state for no payment methods
  factory EmptyStateWidget.noPaymentMethods({required VoidCallback onAddPayment}) {
    return EmptyStateWidget(
      icon: Icons.payment_outlined,
      title: 'No Payment Methods',
      message: 'Add a payment method for faster checkout.',
      actionText: 'Add Payment Method',
      onAction: onAddPayment,
    );
  }

  /// Empty state for search with no results
  factory EmptyStateWidget.noSearchResults({required String query, VoidCallback? onClearSearch}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'We couldn\'t find any results for "$query". Try different keywords or filters.',
      actionText: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
    );
  }

  /// Empty state for no favorites
  factory EmptyStateWidget.noFavorites({required VoidCallback onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.favorite_border,
      title: 'No Favorites Yet',
      message: 'Save your favorite restaurants for quick access later.',
      actionText: 'Browse Restaurants',
      onAction: onBrowse,
    );
  }

  /// Empty state for no menu items
  factory EmptyStateWidget.noMenuItems() {
    return const EmptyStateWidget(
      icon: Icons.menu_book_outlined,
      title: 'No Menu Items',
      message: 'This restaurant hasn\'t added any menu items yet.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            // Action Button
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward),
                label: Text(actionText!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
