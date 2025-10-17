import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

class RestaurantCardWidget extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCardWidget({super.key, required this.restaurant, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant image with rounded design
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.warmCream,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: restaurant.imageUrl != null && restaurant.imageUrl!.isNotEmpty
                      ? Image.network(
                          restaurant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.restaurant,
                            color: AppTheme.oliveGreen,
                            size: 44,
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: AppTheme.oliveGreen,
                          size: 44,
                        ),
                ),
              ),
              const SizedBox(width: 18),
              // Restaurant details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      restaurant.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Cuisine type
                    Text(
                      restaurant.cuisineType,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Rating and delivery info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.mutedGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                restaurant.rating.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.estimatedDeliveryTime} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
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
      ),
    );
  }
}
