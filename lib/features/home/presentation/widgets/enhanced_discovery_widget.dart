import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Enhanced discovery widget for improved restaurant and food discovery
class EnhancedDiscoveryWidget extends ConsumerStatefulWidget {
  const EnhancedDiscoveryWidget({super.key});

  @override
  ConsumerState<EnhancedDiscoveryWidget> createState() =>
      _EnhancedDiscoveryWidgetState();
}

class _EnhancedDiscoveryWidgetState
    extends ConsumerState<EnhancedDiscoveryWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'Recommended';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchSection(),
        _buildFilterTabs(),
        _buildContentTabs(),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search restaurants, dishes, or cuisines...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.mic),
                onPressed: _voiceSearch,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onSubmitted: (value) => _performSearch(value),
          ),
          const SizedBox(height: 12),
          // Quick filter chips
          _buildQuickFilters(),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    final filters = [
      {'icon': Icons.local_fire_department, 'label': 'Trending Now', 'color': Colors.red},
      {'icon': Icons.new_releases, 'label': 'New Restaurants', 'color': Colors.green},
      {'icon': Icons.star, 'label': 'Top Rated', 'color': Colors.amber},
      {'icon': Icons.local_offer, 'label': 'Special Offers', 'color': Colors.orange},
      {'icon': Icons.delivery_dining, 'label': 'Free Delivery', 'color': Colors.blue},
      {'icon': Icons.schedule, 'label': 'Fast Delivery', 'color': Colors.purple},
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: filter['color'] as Color,
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              onSelected: (selected) {
                // TODO: Apply filter
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: (filter['color'] as Color).withValues(alpha: 0.2),
              checkmarkColor: filter['color'] as Color,
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'For You'),
          Tab(text: 'Categories'),
          Tab(text: 'Trending'),
        ],
        labelColor: AppTheme.primaryBlack,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: AppTheme.primaryBlack,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
    );
  }

  Widget _buildContentTabs() {
    return SizedBox(
      height: 400, // Adjust height as needed
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildForYouTab(),
          _buildCategoriesTab(),
          _buildTrendingTab(),
        ],
      ),
    );
  }

  Widget _buildForYouTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Personalized for You',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildRecommendationCard(
                  'Based on your recent orders',
                  Icons.history,
                  Colors.blue,
                  _buildRecommendationList([
                    'Italian cuisine you might love',
                    'Quick lunch options',
                    'Healthy choices nearby',
                  ]),
                ),
                const SizedBox(height: 16),
                _buildRecommendationCard(
                  'Trending in your area',
                  Icons.trending_up,
                  Colors.red,
                  _buildRecommendationList([
                    'Spicy Thai this week',
                    'BBQ joints nearby',
                    'Vegan options trending',
                  ]),
                ),
                const SizedBox(height: 16),
                _buildRecommendationCard(
                  'Special offers for you',
                  Icons.local_offer,
                  Colors.orange,
                  _buildRecommendationList([
                    '20% off at Pizza Palace',
                    'Free delivery on orders over \$30',
                    'Buy one get one at Burger Barn',
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final categories = [
      {'name': 'Italian', 'icon': '🍕', 'color': Colors.red},
      {'name': 'Chinese', 'icon': '🥡', 'color': Colors.orange},
      {'name': 'Japanese', 'icon': '🍱', 'color': Colors.pink},
      {'name': 'Indian', 'icon': '🍛', 'color': Colors.green},
      {'name': 'Mexican', 'icon': '🌮', 'color': Colors.yellow.shade700},
      {'name': 'Thai', 'icon': '🍜', 'color': Colors.purple},
      {'name': 'American', 'icon': '🍔', 'color': Colors.blue},
      {'name': 'Healthy', 'icon': '🥗', 'color': Colors.green},
      {'name': 'Desserts', 'icon': '🍰', 'color': Colors.pink},
      {'name': 'Coffee', 'icon': '☕', 'color': Colors.brown},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(
            category['name'] as String,
            category['icon'] as String,
            category['color'] as Color,
            () => _browseCategory(category['name'] as String),
          );
        },
      ),
    );
  }

  Widget _buildTrendingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Trending This Week',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildTrendingCard('Most Popular: Burger Palace', '🔥 234 orders today'),
                _buildTrendingCard('Rising Star: Sushi Express', '📈 45% increase'),
                _buildTrendingCard('Top Rated: The Garden', '⭐ 4.9 stars'),
                _buildTrendingCard('Hot Deal: Pizza World', '💰 50% off today'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, IconData icon, Color color, Widget content) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildRecommendationList(List<String> items) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard(String name, String emoji, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingCard(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
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

  void _voiceSearch() {
    // TODO: Implement voice search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice search coming soon!')),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    // TODO: Perform search
    context.push('/search?query=$query');
  }

  void _browseCategory(String category) {
    // TODO: Browse category
    context.push('/search?category=$category');
  }

  void _changeLocation() {
    // TODO: Change location
    context.push('/location');
  }

  void _viewRestaurant(int index) {
    // TODO: View restaurant details
    context.push('/restaurant/${index + 1}');
  }
}