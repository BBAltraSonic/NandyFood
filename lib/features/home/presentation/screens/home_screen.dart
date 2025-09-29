import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantState = ref.watch(restaurantProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to cart screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to profile screen
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh restaurant data
          await ref.read(restaurantProvider.notifier).loadRestaurants();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'What would you like to eat today?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants or dishes',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Categories
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryItem('Pizza', Icons.local_pizza),
                      const SizedBox(width: 16),
                      _buildCategoryItem('Burgers', Icons.fastfood),
                      const SizedBox(width: 16),
                      _buildCategoryItem('Sushi', Icons.restaurant_menu),
                      const SizedBox(width: 16),
                      _buildCategoryItem('Salads', Icons.eco),
                      const SizedBox(width: 16),
                      _buildCategoryItem('Desserts', Icons.cake),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Popular restaurants
                const Text(
                  'Popular Restaurants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                if (restaurantState.isLoading) ...[
                  const Center(child: CircularProgressIndicator()),
                ] else if (restaurantState.errorMessage != null) ...[
                  Center(
                    child: Column(
                      children: [
                        Text(restaurantState.errorMessage!),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(restaurantProvider.notifier).loadRestaurants();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: restaurantState.restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurantState.restaurants[index];
                      return _buildRestaurantCard(restaurant);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a category item
  Widget _buildCategoryItem(String name, IconData icon) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.deepOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.deepOrange,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(name),
      ],
    );
  }

  /// Build a restaurant card
  Widget _buildRestaurantCard(dynamic restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Restaurant image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant),
            ),
            const SizedBox(width: 12),
            
            // Restaurant details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${restaurant.cuisineType} • ${restaurant.estimatedDeliveryTime} min',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text('${restaurant.rating}'),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text('2.5 km'),
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
}