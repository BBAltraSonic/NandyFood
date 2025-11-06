import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/widgets/role_switcher_widget.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_role_indicator.dart';
import 'package:food_delivery_app/features/home/presentation/widgets/enhanced_discovery_widget.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Enhanced home screen focused on customer experience
class EnhancedHomeScreen extends ConsumerStatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  ConsumerState<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends ConsumerState<EnhancedHomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRoles = ref.watch(userRolesProvider);
    final isCustomerPrimary = ref.watch(primaryRoleProvider) == UserRoleType.consumer;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCustomerHome(),
              _buildSearchScreen(),
              _buildOrdersScreen(),
              _buildProfileScreen(),
            ],
          ),
          // Customer banner (for users with multiple roles)
          if (!isCustomerPrimary && userRoles.length > 1)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildCustomerBanner(),
            ),
        ],
      ),
      // Customer-specific bottom navigation
      bottomNavigationBar: _buildCustomerBottomNav(),
    );
  }

  Widget _buildCustomerBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.restaurant_menu, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You\'re viewing as a customer. Want to manage your restaurant?',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _switchToRestaurantRole(),
            child: const Text('Switch'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHome() {
    return CustomScrollView(
      slivers: [
        // Customer header
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text(
              'Good to see you!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'What would you like to eat today?',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.grey.shade50],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotifications(),
            ),
            if (userRoles.length > 1)
              const RoleSwitcherWidget(isCompact: true),
          ],
        ),
        // Main content
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Quick stats
              _buildCustomerStats(),
              // Enhanced discovery
              EnhancedDiscoveryWidget(),
              // Special offers
              _buildSpecialOffers(),
              // Popular items
              _buildPopularItems(),
              // Recommendations
              _buildPersonalizedRecommendations(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for food, restaurants...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: const Center(
        child: Text('Search results will appear here'),
      ),
    );
  }

  Widget _buildOrdersScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _filterOrders(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Your order history will appear here'),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/profile/settings'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Profile settings will appear here'),
      ),
    );
  }

  Widget _buildCustomerStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCustomerStatItem('Orders', '12', Icons.receipt_long),
          _buildCustomerStatItem('Favorites', '8', Icons.favorite),
          _buildCustomerStatItem('Points', '245', Icons.stars),
          _buildCustomerStatItem('Saved', '\$23', Icons.savings),
        ],
      ),
    );
  }

  Widget _buildCustomerStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlack, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialOffers() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                'Special Offers for You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/promotions'),
                child: const Text('See All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 300,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '50% OFF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.local_offer, color: Colors.red),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pizza Palace Special',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'On all large pizzas',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => context.push('/promotions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Order Now'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItems() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildPopularItemCard('Classic Burger', '\$12.99', '🍔'),
              _buildPopularItemCard('Margherita Pizza', '\$14.99', '🍕'),
              _buildPopularItemCard('Caesar Salad', '\$8.99', '🥗'),
              _buildPopularItemCard('Pasta Bowl', '\$11.99', '🍝'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItemCard(String name, String price, String emoji) {
    return Container(
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
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () => _addToCart(name),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 32),
              ),
              child: const Text('Add to Cart'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalizedRecommendations() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Based on your taste',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We noticed you love Italian food and quick delivery. Here are some recommendations:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _viewRecommendations(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlack,
            ),
            child: const Text('View Recommendations'),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem('Home', Icons.home_outlined, Icons.home_rounded, 0),
              _buildBottomNavItem('Search', Icons.search_outlined, Icons.search_rounded, 1),
              _buildBottomNavItem('Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded, 2),
              _buildBottomNavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(String label, IconData icon, IconData activeIcon, int index) {
    final isActive = _currentIndex == index;

    return InkWell(
      onTap: () => _onTabTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppTheme.primaryBlack : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppTheme.primaryBlack : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchToRestaurantRole() {
    // TODO: Switch to restaurant role
    context.go('/restaurant/dashboard');
  }

  void _showNotifications() {
    // TODO: Show notifications
  }

  void _filterOrders() {
    // TODO: Filter orders
  }

  void _addToCart(String itemName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName added to cart!'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push('/order/cart'),
        ),
      ),
    );
  }

  void _viewRecommendations() {
    // TODO: View personalized recommendations
    context.push('/recommendations');
  }
}