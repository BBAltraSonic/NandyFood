import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';

/// Restaurant category model
class RestaurantCategory {
  final String id;
  final String name;
  final String? iconName;
  final String? colorCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  RestaurantCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.colorCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      iconName: json['icon_name'] as String?,
      colorCode: json['color_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color_code': colorCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Service for managing restaurant categories
class CategoryService {
  final DatabaseService _dbService;
  final SupabaseClient _client;

  CategoryService(this._dbService) : _client = _dbService.client;

  /// Get all restaurant categories
  Future<List<RestaurantCategory>> getCategories() async {
    try {
      final response = await _client
          .from('restaurant_categories')
          .select()
          .order('name', ascending: true);

      return response.map((json) => RestaurantCategory.fromJson(json)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return _getDefaultCategories();
    }
  }

  /// Get categories with cuisine type counts
  Future<Map<String, int>> getCuisineTypeCounts() async {
    try {
      final response = await _client
          .from('restaurants')
          .select('cuisine_type')
          .eq('is_active', true);

      final Map<String, int> cuisineCounts = {};

      for (final restaurant in response) {
        final cuisineType = restaurant['cuisine_type'] as String?;
        if (cuisineType != null) {
          // Split multiple cuisine types if comma-separated
          final types = cuisineType.split(',').map((type) => type.trim().toLowerCase());
          for (final type in types) {
            cuisineCounts[type] = (cuisineCounts[type] ?? 0) + 1;
          }
        }
      }

      return cuisineCounts;
    } catch (e) {
      print('Error getting cuisine type counts: $e');
      return {};
    }
  }

  /// Get popular categories based on restaurant count
  Future<List<String>> getPopularCategories({int limit = 8}) async {
    try {
      final cuisineCounts = await getCuisineTypeCounts();

      // Sort by count and take top categories
      final sortedEntries = cuisineCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final popularCategories = sortedEntries
          .take(limit)
          .map((entry) => _formatCategoryName(entry.key))
          .toList();

      return ['All', ...popularCategories];
    } catch (e) {
      print('Error getting popular categories: $e');
      return _getDefaultCategoryNames();
    }
  }

  /// Create a new category (for admin use)
  Future<RestaurantCategory?> createCategory({
    required String name,
    String? iconName,
    String? colorCode,
  }) async {
    try {
      final response = await _client
          .from('restaurant_categories')
          .insert({
            'name': name,
            'icon_name': iconName,
            'color_code': colorCode,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return RestaurantCategory.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      return null;
    }
  }

  /// Update a category (for admin use)
  Future<RestaurantCategory?> updateCategory(
    String categoryId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _client
          .from('restaurant_categories')
          .update({
            ...updateData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', categoryId)
          .select()
          .single();

      return RestaurantCategory.fromJson(response);
    } catch (e) {
      print('Error updating category: $e');
      return null;
    }
  }

  /// Delete a category (for admin use)
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _client.from('restaurant_categories').delete().eq('id', categoryId);
      return true;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  /// Get category by ID
  Future<RestaurantCategory?> getCategoryById(String categoryId) async {
    try {
      final response = await _client
          .from('restaurant_categories')
          .select()
          .eq('id', categoryId)
          .single();

      return RestaurantCategory.fromJson(response);
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  /// Watch category changes in real-time
  Stream<List<RestaurantCategory>> watchCategories() {
    return _client
        .from('restaurant_categories')
        .select('*')
        .order('name', ascending: true)
        .asStream()
        .map((event) => (event as List)
            .map((json) => RestaurantCategory.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Format category name for display
  String _formatCategoryName(String category) {
    // Convert to title case and clean up formatting
    return category
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
        .join(' ');
  }

  /// Get default categories if database fails
  List<RestaurantCategory> _getDefaultCategories() {
    return [
      RestaurantCategory(
        id: 'all',
        name: 'All',
        iconName: 'restaurant',
        colorCode: '#9C27B0',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RestaurantCategory(
        id: 'pizza',
        name: 'Pizza',
        iconName: 'local_pizza',
        colorCode: '#212121',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RestaurantCategory(
        id: 'sushi',
        name: 'Sushi',
        iconName: 'set_meal',
        colorCode: '#E91E63',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RestaurantCategory(
        id: 'burgers',
        name: 'Burgers',
        iconName: 'lunch_dining',
        colorCode: '#212121',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      RestaurantCategory(
        id: 'healthy',
        name: 'Healthy',
        iconName: 'eco',
        colorCode: '#4CAF50',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Get default category names
  List<String> _getDefaultCategoryNames() {
    return [
      'All',
      'Pizza',
      'Burgers',
      'Sushi',
      'Asian',
      'Mexican',
      'Italian',
      'American',
      'Healthy',
    ];
  }

  /// Synchronize categories with restaurant cuisine types
  Future<void> syncCategoriesWithCuisines() async {
    try {
      final cuisineCounts = await getCuisineTypeCounts();
      final existingCategories = await getCategories();
      final existingNames = existingCategories.map((cat) => cat.name.toLowerCase()).toSet();

      // Create new categories for cuisine types that don't exist
      for (final cuisineEntry in cuisineCounts.entries) {
        final cuisineName = _formatCategoryName(cuisineEntry.key);

        if (!existingNames.contains(cuisineName.toLowerCase()) &&
            cuisineName.toLowerCase() != 'all') {
          await createCategory(
            name: cuisineName,
            iconName: _getIconForCuisine(cuisineEntry.key),
            colorCode: _getColorForCuisine(cuisineEntry.key),
          );
        }
      }
    } catch (e) {
      print('Error syncing categories: $e');
    }
  }

  /// Get appropriate icon for cuisine type
  String _getIconForCuisine(String cuisine) {
    final lowerCuisine = cuisine.toLowerCase();

    switch (lowerCuisine) {
      case 'pizza':
        return 'local_pizza';
      case 'sushi':
      case 'japanese':
        return 'set_meal';
      case 'burger':
      case 'american':
        return 'lunch_dining';
      case 'italian':
        return 'restaurant';
      case 'mexican':
        return 'local_fire_department';
      case 'chinese':
      case 'asian':
        return 'ramen_dining';
      case 'indian':
        return 'kebab_dining';
      case 'thai':
        return 'restaurant_menu';
      case 'healthy':
      case 'salad':
        return 'eco';
      case 'coffee':
      case 'cafe':
        return 'coffee';
      case 'dessert':
        return 'cake';
      case 'seafood':
        return 'set_meal';
      default:
        return 'restaurant';
    }
  }

  /// Get appropriate color for cuisine type
  String _getColorForCuisine(String cuisine) {
    final lowerCuisine = cuisine.toLowerCase();

    switch (lowerCuisine) {
      case 'pizza':
      case 'italian':
        return '#212121';
      case 'sushi':
      case 'japanese':
        return '#E91E63';
      case 'mexican':
        return '#FF5722';
      case 'indian':
        return '#FF9800';
      case 'thai':
        return '#9C27B0';
      case 'healthy':
      case 'salad':
        return '#4CAF50';
      case 'coffee':
      case 'cafe':
        return '#795548';
      case 'seafood':
        return '#2196F3';
      default:
        return '#212121';
    }
  }
}

/// Provider for CategoryService
final categoryServiceProvider = Provider<CategoryService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return CategoryService(dbService);
});