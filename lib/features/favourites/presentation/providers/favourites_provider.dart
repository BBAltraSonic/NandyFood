import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/database_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/restaurant.dart';
import '../../../../shared/models/menu_item.dart';

import '../../../../core/services/cache_service.dart';

/// Favourite type enum
enum FavouriteType {
  restaurant,
  menuItem,
}

/// Favourite item model
class FavouriteItem {
  const FavouriteItem({
    required this.id,
    required this.userId,
    required this.type,
    this.restaurantId,
    this.menuItemId,
    required this.createdAt,
    this.restaurant,
    this.menuItem,
  });

  final String id;
  final String userId;
  final FavouriteType type;
  final String? restaurantId;
  final String? menuItemId;
  final DateTime createdAt;
  final Restaurant? restaurant;
  final MenuItem? menuItem;

  factory FavouriteItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = typeStr == 'restaurant'
        ? FavouriteType.restaurant
        : FavouriteType.menuItem;

    return FavouriteItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: type,
      restaurantId: json['restaurant_id'] as String?,
      menuItemId: json['menu_item_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      restaurant: json['restaurant'] != null
          ? Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>)
          : null,
      menuItem: json['menu_item'] != null
          ? MenuItem.fromJson(json['menu_item'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type == FavouriteType.restaurant ? 'restaurant' : 'menu_item',
      'restaurant_id': restaurantId,
      'menu_item_id': menuItemId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  FavouriteItem copyWith({
    String? id,
    String? userId,
    FavouriteType? type,
    String? restaurantId,
    String? menuItemId,
    DateTime? createdAt,
    Restaurant? restaurant,
    MenuItem? menuItem,
  }) {
    return FavouriteItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      restaurantId: restaurantId ?? this.restaurantId,
      menuItemId: menuItemId ?? this.menuItemId,
      createdAt: createdAt ?? this.createdAt,
      restaurant: restaurant ?? this.restaurant,
      menuItem: menuItem ?? this.menuItem,
    );
  }
}

/// Favourites state
class FavouritesState {
  const FavouritesState({
    this.favourites = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final List<FavouriteItem> favourites;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  List<FavouriteItem> get restaurantFavourites =>
      favourites.where((f) => f.type == FavouriteType.restaurant).toList();

  List<FavouriteItem> get menuItemFavourites =>
      favourites.where((f) => f.type == FavouriteType.menuItem).toList();

  bool isRestaurantFavourite(String restaurantId) {
    return favourites.any(
      (f) => f.type == FavouriteType.restaurant && f.restaurantId == restaurantId,
    );
  }

  bool isMenuItemFavourite(String menuItemId) {
    return favourites.any(
      (f) => f.type == FavouriteType.menuItem && f.menuItemId == menuItemId,
    );
  }

  FavouritesState copyWith({
    List<FavouriteItem>? favourites,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return FavouritesState(
      favourites: favourites ?? this.favourites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Favourites provider
class FavouritesNotifier extends StateNotifier<FavouritesState> {
  FavouritesNotifier({
    required this.databaseService,
  }) : super(const FavouritesState()) {
    _initialize();
  }

  final DatabaseService databaseService;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize favourites
  Future<void> _initialize() async {
    await loadFavourites();
  }

  /// Load all favourites for current user
  Future<void> loadFavourites() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated',
        );
        return;
      }

      AppLogger.info('Loading favourites for user: $userId');

      // 1) Try cache first for immediate UX
      final cached = CacheService.instance.getCachedFavourites(userId);
      if (cached != null) {
        final cachedFavourites = <FavouriteItem>[];
        for (final item in cached) {
          try {
            cachedFavourites.add(FavouriteItem.fromJson(item));
          } catch (e) {
            AppLogger.error('Error parsing cached favourite item', error: e);
          }
        }
        if (cachedFavourites.isNotEmpty) {
          state = state.copyWith(
            favourites: cachedFavourites,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        }
      }

      // 2) Fetch fresh data from Supabase
      final response = await _supabase
          .from('favourites')
          .select('''
            *,
            restaurant:restaurants(*),
            menu_item:menu_items(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<FavouriteItem> favourites = [];

      for (final item in response) {
        try {
          favourites.add(FavouriteItem.fromJson(item));
        } catch (e) {
          AppLogger.error('Error parsing favourite item', error: e);
        }
      }

      state = state.copyWith(
        favourites: favourites,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      // 3) Update cache with fresh payload
      try {
        final List<Map<String, dynamic>> rawList =
            List<Map<String, dynamic>>.from((response as List).map((e) => Map<String, dynamic>.from(e as Map)));
        await CacheService.instance.cacheFavourites(userId, rawList);
      } catch (e) {
        AppLogger.error('Failed to cache favourites after fetch', error: e);
      }

      AppLogger.success('Loaded ${favourites.length} favourites');
    } catch (e, stack) {
      AppLogger.error('Failed to load favourites', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load favourites: $e',
      );
    }
  }

  /// Add restaurant to favourites
  Future<bool> addRestaurantFavourite(String restaurantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favourite
      if (state.isRestaurantFavourite(restaurantId)) {
        AppLogger.warning('Restaurant already in favourites');
        return true;
      }

      AppLogger.info('Adding restaurant to favourites: $restaurantId');

      final response = await _supabase
          .from('favourites')
          .insert({
            'user_id': userId,
            'type': 'restaurant',
            'restaurant_id': restaurantId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            restaurant:restaurants(*)
          ''')
          .single();

      final favourite = FavouriteItem.fromJson(response);

      state = state.copyWith(
        favourites: [favourite, ...state.favourites],
        lastUpdated: DateTime.now(),
      );

      // Update cache
      try {
        await CacheService.instance.cacheFavourites(
          userId,
          state.favourites.map((f) => f.toJson()).toList(),
        );
      } catch (e) {
        AppLogger.error('Failed to update favourites cache after adding restaurant', error: e);
      }

      AppLogger.success('Restaurant added to favourites');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to add restaurant to favourites', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to add to favourites: $e');
      return false;
    }
  }

  /// Add menu item to favourites
  Future<bool> addMenuItemFavourite(String menuItemId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favourite
      if (state.isMenuItemFavourite(menuItemId)) {
        AppLogger.warning('Menu item already in favourites');
        return true;
      }

      AppLogger.info('Adding menu item to favourites: $menuItemId');

      final response = await _supabase
          .from('favourites')
          .insert({
            'user_id': userId,
            'type': 'menu_item',
            'menu_item_id': menuItemId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            menu_item:menu_items(*)
          ''')
          .single();

      final favourite = FavouriteItem.fromJson(response);

      state = state.copyWith(
        favourites: [favourite, ...state.favourites],
        lastUpdated: DateTime.now(),
      );

      // Update cache
      try {
        await CacheService.instance.cacheFavourites(
          userId,
          state.favourites.map((f) => f.toJson()).toList(),
        );
      } catch (e) {
        AppLogger.error('Failed to update favourites cache after adding menu item', error: e);
      }

      AppLogger.success('Menu item added to favourites');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to add menu item to favourites', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to add to favourites: $e');
      return false;
    }
  }

  /// Remove restaurant from favourites
  Future<bool> removeRestaurantFavourite(String restaurantId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Removing restaurant from favourites: $restaurantId');

      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('type', 'restaurant');

      state = state.copyWith(
        favourites: state.favourites
            .where((f) => !(f.type == FavouriteType.restaurant && f.restaurantId == restaurantId))
            .toList(),
        lastUpdated: DateTime.now(),
      );

      // Update cache
      try {
        await CacheService.instance.cacheFavourites(
          userId,
          state.favourites.map((f) => f.toJson()).toList(),
        );
      } catch (e) {
        AppLogger.error('Failed to update favourites cache after removing restaurant', error: e);
      }

      AppLogger.success('Restaurant removed from favourites');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to remove restaurant from favourites', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to remove from favourites: $e');
      return false;
    }
  }

  /// Remove menu item from favourites
  Future<bool> removeMenuItemFavourite(String menuItemId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Removing menu item from favourites: $menuItemId');

      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('menu_item_id', menuItemId)
          .eq('type', 'menu_item');

      state = state.copyWith(
        favourites: state.favourites
            .where((f) => !(f.type == FavouriteType.menuItem && f.menuItemId == menuItemId))
            .toList(),
        lastUpdated: DateTime.now(),
      );

      // Update cache
      try {
        await CacheService.instance.cacheFavourites(
          userId,
          state.favourites.map((f) => f.toJson()).toList(),
        );
      } catch (e) {
        AppLogger.error('Failed to update favourites cache after removing menu item', error: e);
      }

      AppLogger.success('Menu item removed from favourites');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to remove menu item from favourites', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to remove from favourites: $e');
      return false;
    }
  }

  /// Toggle restaurant favourite
  Future<bool> toggleRestaurantFavourite(String restaurantId) async {
    if (state.isRestaurantFavourite(restaurantId)) {
      return await removeRestaurantFavourite(restaurantId);
    } else {
      return await addRestaurantFavourite(restaurantId);
    }
  }

  /// Toggle menu item favourite
  Future<bool> toggleMenuItemFavourite(String menuItemId) async {
    if (state.isMenuItemFavourite(menuItemId)) {
      return await removeMenuItemFavourite(menuItemId);
    } else {
      return await addMenuItemFavourite(menuItemId);
    }
  }

  /// Clear all favourites
  Future<bool> clearAllFavourites() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.warning('Clearing all favourites for user: $userId');

      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId);

      state = state.copyWith(
        favourites: [],
        lastUpdated: DateTime.now(),
      );

      // Update cache
      try {
        await CacheService.instance.cacheFavourites(
          userId,
          const [],
        );
      } catch (e) {
        AppLogger.error('Failed to update favourites cache after clearing', error: e);
      }

      AppLogger.success('All favourites cleared');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to clear favourites', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to clear favourites: $e');
      return false;
    }
  }

  /// Refresh favourites
  Future<void> refresh() async {
    await loadFavourites();
  }
}

/// Provider for favourites
final favouritesProvider = StateNotifierProvider<FavouritesNotifier, FavouritesState>(
  (ref) {
    final databaseService = ref.watch(databaseServiceProvider);
    return FavouritesNotifier(databaseService: databaseService);
  },
);

/// Provider to check if restaurant is favourite
final isRestaurantFavouriteProvider = Provider.family<bool, String>(
  (ref, restaurantId) {
    final favourites = ref.watch(favouritesProvider);
    return favourites.isRestaurantFavourite(restaurantId);
  },
);

/// Provider to check if menu item is favourite
final isMenuItemFavouriteProvider = Provider.family<bool, String>(
  (ref, menuItemId) {
    final favourites = ref.watch(favouritesProvider);
    return favourites.isMenuItemFavourite(menuItemId);
  },
);
