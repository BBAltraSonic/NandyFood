import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Screen allowing restaurant owners to experience the app as a customer
class ViewAsCustomerScreen extends ConsumerStatefulWidget {
  const ViewAsCustomerScreen({super.key});

  @override
  ConsumerState<ViewAsCustomerScreen> createState() => _ViewAsCustomerScreenState();
}

class _ViewAsCustomerScreenState extends ConsumerState<ViewAsCustomerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSimulationMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRoles = ref.watch(userRolesProvider);
    final primaryRole = ref.watch(primaryRoleProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Owner context banner
          if (primaryRole != null) _buildOwnerContextBanner(primaryRole),
          // Customer simulation content
          Expanded(
            child: _buildCustomerExperience(),
          ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildOwnerContextBanner(UserRoleType primaryRole) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Text(
                'Owner View: Customer Experience',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const Spacer(),
              Switch(
                value: _isSimulationMode,
                onChanged: (value) {
                  setState(() {
                    _isSimulationMode = value;
                  });
                },
                activeColor: Colors.deepPurple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isSimulationMode
                ? 'You\'re simulating the customer experience. See how customers discover and order from your restaurant.'
                : 'Experience the app as a customer would. Browse restaurants and place orders.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepPurple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerExperience() {
    return Column(
      children: [
        // Customer search and discovery
        _buildSearchSection(),
        // Tab content
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildHomeTab(),
                      _buildSearchTab(),
                      _buildOrdersTab(),
                      _buildProfileTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for restaurants or dishes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick filters
          Row(
            children: [
              _buildFilterChip('Near Me', Icons.location_on),
              const SizedBox(width: 8),
              _buildFilterChip('Top Rated', Icons.star),
              const SizedBox(width: 8),
              _buildFilterChip('Fast Delivery', Icons.timer),
              const SizedBox(width: 8),
              _buildFilterChip('Budget', Icons.attach_money),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {},
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryBlack.withValues(alpha: 0.1),
      checkmarkColor: AppTheme.primaryBlack,
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Home'),
        Tab(text: 'Search'),
        Tab(text: 'Orders'),
        Tab(text: 'Profile'),
      ],
      labelColor: AppTheme.primaryBlack,
      unselectedLabelColor: Colors.grey.shade600,
      indicatorColor: AppTheme.primaryBlack,
    );
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome message
        _buildWelcomeMessage(),
        const SizedBox(height: 16),
        // Special offers section
        _buildSpecialOffersSection(),
        const SizedBox(height: 16),
        // Categories section
        _buildCategoriesSection(),
        const SizedBox(height: 16),
        // Popular restaurants
        _buildPopularRestaurantsSection(),
        const SizedBox(height: 16),
        // Personalized recommendations
        _buildRecommendationsSection(),
      ],
    );
  }

  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlack, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back, Customer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'What would you like to eat today?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Special Offers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '30% OFF',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Today Only',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Selected restaurants',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
      {'name': 'Italian', 'icon': '🍕'},
      {'name': 'Chinese', 'icon': '🥡'},
      {'name': 'Japanese', 'icon': '🍱'},
      {'name': 'Indian', 'icon': '🍛'},
      {'name': 'Mexican', 'icon': '🌮'},
      {'name': 'American', 'icon': '🍔'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category['icon'] as String,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPopularRestaurantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Near You',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return _buildRestaurantCard(index);
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restaurant, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Restaurant ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      Text('4.${(index + 1) % 5 + 5}'),
                    const SizedBox(width: 8),
                      Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                      Text('${20 + index * 5} min'),
                    ],
                  ),
                  Text(
                    'Italian • Pizza • Pasta',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _viewRestaurant(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Based on your preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'As a restaurant owner, you might want to see how your restaurant appears to customers or check out competitor offerings.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _exploreRecommendations(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Explore Recommendations'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search Results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Your search results will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Order History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Your past orders will appear here',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Customer Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Your customer profile settings',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _switchBackToOwner(),
                icon: const Icon(Icons.store),
                label: const Text('Back to Owner View'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _placeTestOrder(),
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Place Test Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewRestaurant(int index) {
    // TODO: Navigate to restaurant details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing Restaurant ${index + 1} as customer'),
        action: SnackBarAction(
          label: 'Order',
          onPressed: () => _placeTestOrder(),
        ),
      ),
    );
  }

  void _exploreRecommendations() {
    // TODO: Show recommendations for restaurant owners
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exploring recommendations for restaurant owners')),
    );
  }

  void _switchBackToOwner() {
    // Switch back to restaurant owner role
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(roleProvider.notifier).switchRole(userId, UserRoleType.restaurantOwner);
      context.go('/restaurant/dashboard');
    }
  }

  void _placeTestOrder() {
    // Place a test order to experience the customer journey
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This would start the customer ordering process'),
        duration: Duration(seconds: 3),
      ),
    );

    // TODO: Navigate to cart/checkout
    // context.push('/order/cart');
  }
}