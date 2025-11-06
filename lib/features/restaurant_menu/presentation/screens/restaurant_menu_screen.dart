import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
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
    // TODO: Implement actual menu items from backend
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6, // Mock data
      itemBuilder: (context, index) {
        return _buildMenuItemCard(index);
      },
    );
  }

  Widget _buildMenuItemCard(int index) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);
    final canEdit = isOwner || _canEditMenu(staffData);

    final mockItems = [
      {'name': 'Classic Burger', 'price': 12.99, 'category': 'Main Courses', 'available': true},
      {'name': 'Caesar Salad', 'price': 8.99, 'category': 'Appetizers', 'available': true},
      {'name': 'Grilled Salmon', 'price': 18.99, 'category': 'Main Courses', 'available': false},
      {'name': 'Chocolate Cake', 'price': 6.99, 'category': 'Desserts', 'available': true},
      {'name': 'Fresh Orange Juice', 'price': 3.99, 'category': 'Beverages', 'available': true},
      {'name': 'French Fries', 'price': 4.99, 'category': 'Appetizers', 'available': true},
    ];

    final item = mockItems[index % mockItems.length];
    final isAvailable = item['available'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant_menu, size: 30),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item['name'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: !isAvailable ? TextDecoration.lineThrough : null,
                  color: !isAvailable ? Colors.grey : null,
                ),
              ),
            ),
            if (!isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '\$${(item['price'] as double).toStringAsFixed(2)} • ${item['category']}',
          style: TextStyle(
            color: !isAvailable ? Colors.grey.shade500 : null,
          ),
        ),
        trailing: canEdit
            ? PopupMenuButton<String>(
                onSelected: (value) => _handleItemAction(value, item['name'] as String),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text('Edit Item'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy, color: Colors.green),
                      title: Text('Duplicate Item'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: isAvailable ? 'unavailable' : 'available',
                    child: ListTile(
                      leading: Icon(
                        isAvailable ? Icons.visibility_off : Icons.visibility,
                        color: isAvailable ? Colors.orange : Colors.green,
                      ),
                      title: Text(isAvailable ? 'Mark Unavailable' : 'Mark Available'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete Item'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              )
            : null,
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