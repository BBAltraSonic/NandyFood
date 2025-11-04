import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

class RestaurantCardWidget extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCardWidget({super.key, required this.restaurant, this.onTap});

  // Pre-computed styles for better performance
  static const _restaurantNameStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const _cuisineStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const _ratingStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const _deliveryInfoStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant image with caching
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: restaurant.coverImageUrl?.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: restaurant.coverImageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => Icon(
                            Icons.restaurant,
                            color: Colors.grey.shade600,
                            size: 40,
                          ),
                        )
                      : Icon(
                          Icons.restaurant,
                          color: Colors.grey.shade600,
                          size: 40,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Restaurant details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      restaurant.name,
                      style: _restaurantNameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Cuisine type and rating
                    Row(
                      children: [
                        Text(
                          restaurant.cuisineType,
                          style: _cuisineStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.black54, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toStringAsFixed(1),
                          style: _ratingStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Delivery info
                    Row(
                      children: [
                        const Icon(
                          Icons.delivery_dining,
                          color: Colors.black87,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.estimatedDeliveryTime} min',
                          style: _deliveryInfoStyle,
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.location_on,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant.deliveryRadius.toStringAsFixed(1)} km',
                          style: _deliveryInfoStyle,
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
