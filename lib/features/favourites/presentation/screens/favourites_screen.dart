import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';
import 'package:food_delivery_app/shared/widgets/menu_item_card_widget.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/favourites/presentation/providers/favourites_provider.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(favouritesProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.sageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favourites',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your saved items and restaurants',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.oliveGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: 'Food Items'),
                  Tab(text: 'Restaurants'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFoodItemsTab(),
                  _buildRestaurantsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItemsTab() {
    final favState = ref.watch(favouritesProvider);
    final List<MenuItem> favouriteItems = favState.items;

    if (favState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favouriteItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'No Favourite Items Yet',
        message: 'Start adding your favourite dishes!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: favouriteItems.length,
      itemBuilder: (context, index) {
        final item = favouriteItems[index];
        return MenuItemCardWidget(
          menuItem: item,
          isFavorite: true,
          calories: null,
          onTap: () {
            // Navigate to item detail
          },
          onAddToCart: () {
            // Add to cart
          },
        );
      },
    );
  }

  Widget _buildRestaurantsTab() {
    final favState = ref.watch(favouritesProvider);
    final favouriteRestaurants = favState.restaurants;

    if (favState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favouriteRestaurants.isEmpty) {
      return _buildEmptyState(
        icon: Icons.restaurant_outlined,
        title: 'No Favourite Restaurants Yet',
        message: 'Save your favourite restaurants for quick access!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: favouriteRestaurants.length,
      itemBuilder: (context, index) {
        final r = favouriteRestaurants[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.restaurant)),
          title: Text(r.name),
          subtitle: Text('${r.cuisineType} • ${r.estimatedDeliveryTime} min'),
          onTap: () => context.push('/restaurant/${r.id}')
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.warmCream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppTheme.oliveGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/home');
              },
              child: const Text('Browse Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
