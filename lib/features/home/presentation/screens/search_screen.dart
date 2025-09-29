import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/restaurant_card.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantState = ref.watch(restaurantProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Search app bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                return FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for restaurants or dishes...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        if (value.length > 2) {
                          setState(() {
                            _isSearching = true;
                          });
                          // In a real implementation, this would trigger a search
                          // For now, we'll just use the existing restaurant list
                        } else if (value.isEmpty) {
                          setState(() {
                            _isSearching = false;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        if (value.length > 2) {
                          // Perform search
                          ref.read(restaurantProvider.notifier).loadRestaurants();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Search results or categories
          if (!_isSearching)
            _buildCategoriesSection()
          else if (restaurantState.isLoading)
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: const LoadingIndicator(),
              ),
            )
          else if (restaurantState.errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorMessageWidget(
                  message: restaurantState.errorMessage!,
                  onRetry: () => ref.read(restaurantProvider.notifier).loadRestaurants(),
                ),
              ),
            )
          else if (restaurantState.restaurants.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Try adjusting your search',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _buildSearchResults(restaurantState),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Pizza', 'icon': Icons.local_pizza},
      {'name': 'Burgers', 'icon': Icons.fastfood},
      {'name': 'Sushi', 'icon': Icons.restaurant_menu},
      {'name': 'Salads', 'icon': Icons.eco},
      {'name': 'Desserts', 'icon': Icons.cake},
      {'name': 'Chinese', 'icon': Icons.lunch_dining},
      {'name': 'Indian', 'icon': Icons.ramen_dining},
      {'name': 'Healthy', 'icon': Icons.health_and_safety},
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Popular Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            color: Colors.deepOrange,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Recent searches section
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time, size: 16),
                  SizedBox(width: 8),
                  Text('Pizza'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(restaurantState) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= restaurantState.restaurants.length) {
            return const SizedBox.shrink();
          }
          
          final restaurant = restaurantState.restaurants[index];
          return RestaurantCard(
            restaurant: restaurant,
            onTap: () {
              // Navigate to restaurant detail
              Navigator.of(context).pushNamed(
                '/restaurant/${restaurant.id}',
                arguments: restaurant,
              );
            },
          );
        },
        childCount: restaurantState.restaurants.length,
      ),
    );
  }
}