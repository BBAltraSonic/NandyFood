import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

class RestaurantMenuScreen extends ConsumerStatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  ConsumerState<RestaurantMenuScreen> createState() =>
      _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends ConsumerState<RestaurantMenuScreen> {
  String? _restaurantId;
  List<MenuItem> _menuItems = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _searchQuery;

  final _restaurantService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    _loadRestaurantAndMenu();
  }

  Future<void> _loadRestaurantAndMenu() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);
      if (restaurants.isEmpty) return;

      setState(() => _restaurantId = restaurants.first);
      await _loadMenu();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadMenu() async {
    if (_restaurantId == null) return;

    setState(() => _isLoading = true);
    try {
      final items = await _restaurantService.getMenuItems(_restaurantId!);
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  List<MenuItem> get _filteredItems {
    var items = _menuItems;

    // Filter by category
    if (_selectedCategory != 'All') {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      items = items.where((item) {
        return item.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
            (item.description?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false);
      }).toList();
    }

    return items;
  }

  List<String> get _categories {
    final cats = _menuItems.map((item) => item.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _restaurantId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'bulk') _enterBulkMode();
              if (value == 'export') _exportMenu();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'bulk', child: Text('Bulk Edit')),
              const PopupMenuItem(value: 'export', child: Text('Export Menu')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMenu,
                    child: ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildMenuItemCard(_filteredItems[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddItem(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToEditItem(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: Icon(Icons.restaurant, color: Colors.grey.shade600),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.restaurant, color: Colors.grey.shade600),
                      ),
              ),
              const SizedBox(width: 12),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'R ${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item.isAvailable
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Availability toggle
              Switch(
                value: item.isAvailable,
                onChanged: (value) => _toggleAvailability(item, value),
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      // No search results
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    // No items at all
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first menu item to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddItem(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(MenuItem item, bool isAvailable) async {
    try {
      await _restaurantService.updateMenuItem(item.id, {
        'is_available': isAvailable,
      });

      setState(() {
        final index = _menuItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _menuItems[index] = item.copyWith(isAvailable: isAvailable);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable
                  ? 'Item marked as available'
                  : 'Item marked as unavailable',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to update availability: $e');
    }
  }

  void _navigateToAddItem() {
    context.push('/restaurant/menu/add', extra: _restaurantId).then((_) {
      _loadMenu(); // Refresh list after adding
    });
  }

  void _navigateToEditItem(MenuItem item) {
    context.push('/restaurant/menu/edit/${item.id}', extra: item).then((_) {
      _loadMenu(); // Refresh list after editing
    });
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: MenuItemSearchDelegate(
        menuItems: _menuItems,
        onItemSelected: _navigateToEditItem,
      ),
    );
  }

  void _enterBulkMode() {
    // TODO: Implement bulk edit mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk edit coming soon')),
    );
  }

  void _exportMenu() {
    // TODO: Implement menu export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export menu coming soon')),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// Search delegate for menu items
class MenuItemSearchDelegate extends SearchDelegate<MenuItem?> {
  final List<MenuItem> menuItems;
  final Function(MenuItem) onItemSelected;

  MenuItemSearchDelegate({
    required this.menuItems,
    required this.onItemSelected,
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = menuItems.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) ||
          (item.description?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          leading: item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                )
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.restaurant),
                ),
          title: Text(item.name),
          subtitle: Text('R ${item.price.toStringAsFixed(2)}'),
          trailing: Icon(
            item.isAvailable ? Icons.check_circle : Icons.cancel,
            color: item.isAvailable ? Colors.green : Colors.red,
          ),
          onTap: () {
            close(context, item);
            onItemSelected(item);
          },
        );
      },
    );
  }
}
