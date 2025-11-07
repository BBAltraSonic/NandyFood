import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/menu_service.dart';
import 'package:food_delivery_app/core/services/restaurant_service.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Restaurant menu management screen
class RestaurantMenuScreen extends ConsumerStatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  ConsumerState<RestaurantMenuScreen> createState() =>
      _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends ConsumerState<RestaurantMenuScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle(userRole ?? UserRoleType.consumer, staffData)),
        actions: [
          if (isOwner || _canEditMenu(staffData))
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('${RoutePaths.restaurantMenu}/add'),
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'categories',
                  child: ListTile(
                    leading: Icon(Icons.category),
                    title: Text('Manage Categories'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.upload_file),
                    title: Text('Import Menu'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Export Menu'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          _buildCategoryTabs(),
          // Menu items
          Expanded(
            child: _buildMenuItems(),
          ),
        ],
      ),
      floatingActionButton: isOwner || _canEditMenu(staffData)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('${RoutePaths.restaurantMenu}/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              backgroundColor: AppTheme.primaryBlack,
            )
          : null,
    );
  }

  String _getScreenTitle(UserRoleType role, staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return 'Menu Management';
      case UserRoleType.restaurantStaff:
        final staffRole = staffData?.role?.toLowerCase();
        switch (staffRole) {
          case 'chef':
            return 'Kitchen Menu';
          case 'cashier':
            return 'POS Menu';
          case 'server':
            return 'Service Menu';
          default:
            return 'Menu';
        }
      default:
        return 'Menu';
    }
  }

  bool _canEditMenu(staffData) {
    final staffRole = staffData?.role?.toLowerCase();
    return ['chef', 'manager'].contains(staffRole);
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', 'Appetizers', 'Main Courses', 'Desserts', 'Beverages'];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category || (index == 0 && _selectedCategory == null);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: AppTheme.primaryBlack.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryBlack,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItems() {
    final authState = ref.watch(authStateProvider);
    final menuService = ref.watch(menuServiceProvider);

    if (authState == null) {
      return _buildEmptyState('User not authenticated', false);
    }

    return FutureBuilder<List<MenuItem>>(
      future: _getMenuItemsForUser(authState.user?.id ?? '', menuService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildEmptyState('Error loading menu: ${snapshot.error}', false);
        }

        final menuItems = snapshot.data ?? [];

        if (menuItems.isEmpty) {
          final userRole = ref.watch(primaryRoleProvider);
          final isOwner = userRole == UserRoleType.restaurantOwner;
          return _buildEmptyState('No menu items yet', isOwner);
        }

        // Filter by selected category
        final filteredItems = _selectedCategory == null
            ? menuItems
            : menuItems.where((item) => item.category == _selectedCategory).toList();

        if (filteredItems.isEmpty) {
          return _buildEmptyState('No items in $_selectedCategory', false);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            return _buildMenuItemCard(filteredItems[index]);
          },
        );
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem menuItem) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);
    final canEdit = isOwner || _canEditMenu(staffData);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu item image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade200,
              ),
              child: menuItem.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        menuItem.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.restaurant, color: Colors.grey.shade400);
                        },
                      ),
                    )
                  : Icon(Icons.restaurant, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),

            // Menu item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          menuItem.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Availability indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: menuItem.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          menuItem.isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: menuItem.isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  if (menuItem.description != null) ...[
                    Text(
                      menuItem.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    children: [
                      Text(
                        '\$${menuItem.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Category tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          menuItem.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      if (menuItem.preparationTime > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(
                              '${menuItem.preparationTime}min',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  // Dietary restrictions if any
                  if (menuItem.dietaryRestrictions != null && menuItem.dietaryRestrictions!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: menuItem.dietaryRestrictions!.take(3).map((dietary) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dietary,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            if (canEdit)
              PopupMenuButton<String>(
                onSelected: (value) => _handleItemAction(value, menuItem.id),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: menuItem.isAvailable ? 'unavailable' : 'available',
                    child: ListTile(
                      leading: Icon(
                        menuItem.isAvailable ? Icons.visibility_off : Icons.visibility,
                      ),
                      title: Text(menuItem.isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: const Icon(Icons.copy),
                      title: const Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete, color: Colors.red),
                      title: const Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMenuItemCard(bool canEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Icon(Icons.restaurant_menu, size: 30, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No menu items yet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add menu items to get started',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.blue.shade600),
                onPressed: () => context.push('${RoutePaths.restaurantMenu}/add'),
              ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: MenuSearchDelegate(),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'categories':
        context.push('/restaurant/menu/categories');
        break;
      case 'import':
        _showImportDialog();
        break;
      case 'export':
        _showExportDialog();
        break;
    }
  }

  void _handleItemAction(String action, String itemName) {
    switch (action) {
      case 'edit':
        context.push('${RoutePaths.restaurantMenu}/edit/$itemName');
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicating $itemName...')),
        );
        break;
      case 'available':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName marked as available')),
        );
        break;
      case 'unavailable':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$itemName marked as unavailable')),
        );
        break;
      case 'delete':
        _showDeleteConfirmDialog(itemName);
        break;
    }
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Menu'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Import menu items from a file (CSV, Excel)'),
            SizedBox(height: 16),
            LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Menu'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format:'),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('CSV')),
                Expanded(child: Text('Excel')),
                Expanded(child: Text('PDF')),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "$itemName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$itemName deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Get menu items for the current user's restaurant
  Future<List<MenuItem>> _getMenuItemsForUser(String userId, MenuService menuService) async {
    try {
      // First, get the user's restaurant (this would depend on your user-restaurant relationship)
      // For now, we'll assume we need to get restaurant_id from user profile or another service
      // This is a placeholder - you'll need to implement the actual logic

      // Option 1: If user has a direct restaurant_id in their profile
      // Option 2: If you have a separate user_restaurants table
      // Option 3: If restaurant owners are linked differently

      // For demonstration, let's assume we have a method to get the restaurant ID
      // This would typically be in a UserProfileService or similar
      final restaurantId = await _getUserRestaurantId(userId);

      if (restaurantId == null) {
        throw Exception('User does not have an associated restaurant');
      }

      // Get menu items for the restaurant
      final menuItems = await menuService.getMenuItems(restaurantId);

      // Load categories for filtering
      _loadCategories(restaurantId, menuService);

      return menuItems;
    } catch (e) {
      print('Error getting menu items: $e');
      throw e;
    }
  }

  /// Get restaurant ID for the current user
  Future<String?> _getUserRestaurantId(String userId) async {
    try {
      // This is a placeholder implementation
      // You would typically:
      // 1. Query user_profiles for restaurant_id
      // 2. Query a restaurants table where owner_id = userId
      // 3. Query a user_restaurants join table

      // For now, return null and let the calling code handle it
      // In a real implementation, this would be:
      // final userProfile = await _userProfileService.getUserProfile(userId);
      // return userProfile?.restaurantId;

      // Or query restaurants directly:
      // final restaurants = await _restaurantService.getRestaurantsByOwner(userId);
      // return restaurants.isNotEmpty ? restaurants.first.id : null;

      return null; // Placeholder
    } catch (e) {
      print('Error getting user restaurant ID: $e');
      return null;
    }
  }

  /// Load categories for the restaurant
  Future<void> _loadCategories(String restaurantId, MenuService menuService) async {
    try {
      final categories = await menuService.getMenuCategories(restaurantId);
      // You could update state or store categories for filtering
      // For now, we'll just log them
      print('Available categories: $categories');
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  /// Build empty state with message
  Widget _buildEmptyState(String message, bool canEdit) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            canEdit ? 'Add menu items to get started' : 'No menu items available',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          if (canEdit) ...[
            const SizedBox(height: 16),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.blue.shade600),
              onPressed: () => context.push('${RoutePaths.restaurantMenu}/add'),
            ),
          ],
        ],
      ),
    );
  }
}

class MenuSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: Implement search results
    return const Center(
      child: Text('Search results will appear here'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: Implement search suggestions
    return const Center(
      child: Text('Start typing to search menu items'),
    );
  }
}