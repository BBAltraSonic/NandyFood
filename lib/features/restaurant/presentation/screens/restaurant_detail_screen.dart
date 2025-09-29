import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/menu_item_card.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantState = ref.watch(restaurantProvider);
    
    // Load menu items for this restaurant
    ref.listen<RestaurantState>(restaurantProvider, (previous, next) {
      if (previous?.selectedRestaurant?.id != restaurant.id && 
          next.selectedRestaurant?.id == restaurant.id) {
        ref.read(restaurantProvider.notifier).loadMenuItems(restaurant.id);
      }
    });

    // Select this restaurant in the provider
    ref.read(restaurantProvider.notifier).selectRestaurant(restaurant);

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name),
        centerTitle: true,
      ),
      body: restaurantState.isLoading
          ? const LoadingIndicator()
          : restaurantState.errorMessage != null
              ? ErrorMessageWidget(
                  message: restaurantState.errorMessage!,
                  onRetry: () => ref.read(restaurantProvider.notifier).loadMenuItems(restaurant.id),
                )
              : _buildRestaurantDetailContent(restaurantState, context),
    );
  }

  Widget _buildRestaurantDetailContent(RestaurantState restaurantState, BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Restaurant header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant image placeholder
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Restaurant info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurantState.selectedRestaurant?.name ?? restaurant.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${restaurantState.selectedRestaurant?.cuisineType ?? restaurant.cuisineType} • ${restaurantState.selectedRestaurant?.estimatedDeliveryTime ?? restaurant.estimatedDeliveryTime} min',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurantState.selectedRestaurant?.rating ?? restaurant.rating}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.location_on,
                                color: Colors.grey,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '2.5 km',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.deepOrange),
                      ),
                      child: const Text(
                        'Free delivery',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Restaurant description
                Text(
                  restaurantState.selectedRestaurant?.description ?? restaurant.description ?? 'No description available',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Menu section
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Menu items list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= restaurantState.menuItems.length) {
                return const SizedBox.shrink();
              }
              
              final menuItem = restaurantState.menuItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: MenuItemCard(
                  menuItem: menuItem,
                  onAddToCart: () {
                    // TODO: Add to cart functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart')),
                    );
                  },
                ),
              );
            },
            childCount: restaurantState.menuItems.length,
          ),
        ),
      ],
    );
  }
}