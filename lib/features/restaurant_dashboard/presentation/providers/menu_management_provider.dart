import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/image_upload_service.dart';
import 'package:food_delivery_app/core/services/menu_service.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

/// Menu management state
class MenuManagementState {
  final List<MenuItem> items;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;
  final String? searchQuery;

  const MenuManagementState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.searchQuery,
  });

  MenuManagementState copyWith({
    List<MenuItem>? items,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MenuManagementState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<MenuItem> get filteredItems {
    var filtered = items;

    // Filter by category
    if (selectedCategory != null && selectedCategory != 'All') {
      filtered = filtered.where((item) => item.category == selectedCategory).toList();
    }

    // Filter by search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.name.toLowerCase().contains(searchQuery!.toLowerCase()) ||
            (item.description?.toLowerCase().contains(searchQuery!.toLowerCase()) ?? false);
      }).toList();
    }

    return filtered;
  }

  List<String> get categories {
    final cats = items.map((item) => item.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }
}

/// Menu management notifier
class MenuManagementNotifier extends StateNotifier<MenuManagementState> {
  MenuManagementNotifier(this._restaurantId, this._menuService, this._imageUploadService)
      : super(const MenuManagementState()) {
    loadMenuItems();
  }

  final String _restaurantId;
  final MenuService _menuService;
  final ImageUploadService _imageUploadService;

  /// Load all menu items
  Future<void> loadMenuItems() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _menuService.getMenuItems(_restaurantId);
      state = state.copyWith(
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load menu items: ${e.toString()}',
      );
    }
  }

  /// Create new menu item
  Future<MenuItem?> createMenuItem(
    MenuItem item, {
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        // Create item first to get ID, then upload image
        final tempItem = await _menuService.createMenuItem(item.toJson());
        imageUrl = await _imageUploadService.uploadMenuItemImage(
          imageFile,
          tempItem.id,
        );

        // Update item with image URL
        final updatedItem = await _menuService.updateMenuItem(
          tempItem.id,
          {'image_url': imageUrl},
        );

        // Reload menu to get updated item
        await loadMenuItems();
        return updatedItem;
      } else {
        final createdItem = await _menuService.createMenuItem(item.toJson());

        // Add to local state
        final updatedItems = [...state.items, createdItem];
        state = state.copyWith(
          items: updatedItems,
          isLoading: false,
        );

        return createdItem;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create menu item: ${e.toString()}',
      );
      return null;
    }
  }

  /// Update menu item
  Future<bool> updateMenuItem(
    String itemId,
    Map<String, dynamic> updates, {
    File? newImageFile,
    String? oldImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Upload new image if provided
      if (newImageFile != null) {
        final imageUrl = await _imageUploadService.uploadMenuItemImage(
          newImageFile,
          itemId,
        );
        updates['image_url'] = imageUrl;

        // Delete old image if exists
        if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
          try {
            // Extract bucket and path from URL
            final uri = Uri.parse(oldImageUrl);
            final segments = uri.pathSegments;
            if (segments.length >= 2) {
              final filePath = 'menu-items/${segments.last}';
              await _imageUploadService.deleteImage('menu-items', filePath);
            }
          } catch (e) {
            // Ignore deletion errors
            print('Failed to delete old image: $e');
          }
        }
      }

      await _menuService.updateMenuItem(itemId, updates);

      // Reload menu items
      await loadMenuItems();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update menu item: ${e.toString()}',
      );
      return false;
    }
  }

  /// Delete menu item
  Future<bool> deleteMenuItem(String itemId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _menuService.deleteMenuItem(itemId);

      // Remove from local state
      final updatedItems = state.items.where((item) => item.id != itemId).toList();
      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete menu item: ${e.toString()}',
      );
      return false;
    }
  }

  /// Toggle menu item availability
  Future<bool> toggleAvailability(String itemId) async {
    try {
      final updatedItem = await _menuService.toggleMenuItemAvailability(itemId);

      if (updatedItem != null) {
        // Update local state
        final updatedItems = state.items.map((item) {
          if (item.id == itemId) {
            return updatedItem;
          }
          return item;
        }).toList();

        state = state.copyWith(items: updatedItems);
        return true;
      } else {
        state = state.copyWith(error: 'Failed to toggle availability');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to toggle availability: ${e.toString()}',
      );
      return false;
    }
  }

  /// Set category filter
  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Set search query
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Bulk update availability
  Future<bool> bulkUpdateAvailability(
    List<String> itemIds,
    bool isAvailable,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _menuService.bulkUpdateAvailability(itemIds, isAvailable);

      // Update local state
      final updatedItems = state.items.map((item) {
        if (itemIds.contains(item.id)) {
          return item.copyWith(isAvailable: isAvailable);
        }
        return item;
      }).toList();

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to bulk update: ${e.toString()}',
      );
      return false;
    }
  }
}

/// Menu management provider
final menuManagementProvider = StateNotifierProvider.family<
    MenuManagementNotifier,
    MenuManagementState,
    String>(
  (ref, restaurantId) {
    final menuService = ref.watch(menuServiceProvider);
    final imageUploadService = ref.watch(imageUploadServiceProvider);

    return MenuManagementNotifier(
      restaurantId,
      menuService,
      imageUploadService,
    );
  },
);

/// Provider for filtered items
final filteredMenuItemsProvider = Provider.family<List<MenuItem>, String>(
  (ref, restaurantId) {
    final state = ref.watch(menuManagementProvider(restaurantId));
    return state.filteredItems;
  },
);

/// Provider for categories
final menuCategoriesProvider = Provider.family<List<String>, String>(
  (ref, restaurantId) {
    final state = ref.watch(menuManagementProvider(restaurantId));
    return state.categories;
  },
);
