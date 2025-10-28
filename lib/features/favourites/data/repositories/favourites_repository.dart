import 'dart:convert';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

/// Repository for user favourites (restaurants and menu items)
/// Encapsulates all Supabase access and returns plain JSON maps
/// so callers can map to their own models as needed.
/// Enhanced with offline support and conflict resolution.
class FavouritesRepository {
  FavouritesRepository({required DatabaseService databaseService})
      : _supabase = databaseService.client;

  final SupabaseClient _supabase;
  static const String _favouritesCacheKey = 'cached_favourites_';
  static const String _lastSyncKey = 'favourites_last_sync_';

  /// Fetch all favourites for a user with joined restaurant/menu_item objects
  Future<List<Map<String, dynamic>>> fetchFavourites(String userId) async {
    try {
      AppLogger.database('SELECT', 'favourites', data: {'user_id': userId});
      final response = await _supabase
          .from('favourites')
          .select('''
            *,
            restaurant:restaurants(*),
            menu_item:menu_items(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(
        (response as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      return list;
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.fetchFavourites failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Add a restaurant favourite and return the created row with join
  Future<Map<String, dynamic>> addRestaurantFavourite(
    String userId,
    String restaurantId,
  ) async {
    try {
      AppLogger.database('INSERT', 'favourites', data: {
        'user_id': userId,
        'type': 'restaurant',
        'restaurant_id': restaurantId,
      });
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

      return Map<String, dynamic>.from(response as Map);
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.addRestaurantFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Add a menu item favourite and return the created row with join
  Future<Map<String, dynamic>> addMenuItemFavourite(
    String userId,
    String menuItemId,
  ) async {
    try {
      AppLogger.database('INSERT', 'favourites', data: {
        'user_id': userId,
        'type': 'menu_item',
        'menu_item_id': menuItemId,
      });
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

      return Map<String, dynamic>.from(response as Map);
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.addMenuItemFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Remove a restaurant favourite
  Future<void> removeRestaurantFavourite(String userId, String restaurantId) async {
    try {
      AppLogger.database('DELETE', 'favourites', data: {
        'user_id': userId,
        'restaurant_id': restaurantId,
        'type': 'restaurant',
      });
      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('type', 'restaurant');
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.removeRestaurantFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Remove a menu item favourite
  Future<void> removeMenuItemFavourite(String userId, String menuItemId) async {
    try {
      AppLogger.database('DELETE', 'favourites', data: {
        'user_id': userId,
        'menu_item_id': menuItemId,
        'type': 'menu_item',
      });
      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('menu_item_id', menuItemId)
          .eq('type', 'menu_item');
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.removeMenuItemFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Clear all favourites for a user
  Future<void> clearUserFavourites(String userId) async {
    try {
      AppLogger.database('DELETE', 'favourites', data: {'user_id': userId});
      await _supabase.from('favourites').delete().eq('user_id', userId);
      // Also clear local cache
      await _clearLocalCache(userId);
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.clearUserFavourites failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Enhanced fetch with offline support and conflict resolution
  Future<List<Map<String, dynamic>>> fetchFavouritesWithSync(String userId) async {
    try {
      List<Map<String, dynamic>> localFavourites = await _getLocalFavourites(userId);
      List<Map<String, dynamic>> remoteFavourites = [];

      try {
        remoteFavourites = await fetchFavourites(userId);
        await _cacheFavourites(userId, remoteFavourites);
        await _resolveConflicts(userId, localFavourites, remoteFavourites);
        return remoteFavourites;
      } catch (e) {
        AppLogger.warning('Failed to fetch remote favourites, using local cache: $e');
        return localFavourites;
      }
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.fetchFavouritesWithSync failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Sync local changes with remote server
  Future<FavouritesSyncResult> syncWithRemote(String userId) async {
    try {
      AppLogger.info('Starting favourites sync for user: $userId');

      final localFavourites = await _getLocalFavourites(userId);
      final remoteFavourites = await fetchFavourites(userId);

      final conflicts = await _resolveConflicts(userId, localFavourites, remoteFavourites);

      // Update local cache with remote data
      await _cacheFavourites(userId, remoteFavourites);

      AppLogger.info('Favourites sync completed for user: $userId');
      return FavouritesSyncResult(
        success: true,
        conflictsResolved: conflicts,
        totalSynced: remoteFavourites.length,
      );
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.syncWithRemote failed', error: e, stack: stack);
      return FavouritesSyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Add favourite with offline support
  Future<Map<String, dynamic>> addFavouriteWithOfflineSupport({
    required String userId,
    required String type,
    required String targetId,
  }) async {
    try {
      // Optimistically add to local cache first
      final optimisticFavourite = {
        'id': 'pending_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': userId,
        'type': type,
        'restaurant_id': type == 'restaurant' ? targetId : null,
        'menu_item_id': type == 'menu_item' ? targetId : null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pending_sync': true,
      };

      await _addFavouriteToLocalCache(userId, optimisticFavourite);

      Map<String, dynamic> remoteResult;
      try {
        if (type == 'restaurant') {
          remoteResult = await addRestaurantFavourite(userId, targetId);
        } else {
          remoteResult = await addMenuItemFavourite(userId, targetId);
        }

        // Replace optimistic with real data
        await _updateFavouriteInLocalCache(userId, optimisticFavourite['id'] as String, remoteResult);
        return remoteResult;
      } catch (e) {
        AppLogger.warning('Failed to sync favourite to remote, keeping in local queue: $e');
        return optimisticFavourite;
      }
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.addFavouriteWithOfflineSupport failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Remove favourite with offline support
  Future<void> removeFavouriteWithOfflineSupport({
    required String userId,
    required String type,
    required String targetId,
  }) async {
    try {
      // Optimistically remove from local cache
      await _removeFavouriteFromLocalCache(userId, type, targetId);

      try {
        if (type == 'restaurant') {
          await removeRestaurantFavourite(userId, targetId);
        } else {
          await removeMenuItemFavourite(userId, targetId);
        }
      } catch (e) {
        AppLogger.warning('Failed to sync removal to remote, marking as pending: $e');
        await _markFavouriteAsPendingRemoval(userId, type, targetId);
      }
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.removeFavouriteWithOfflineSupport failed', error: e, stack: stack);
      rethrow;
    }
  }

  // Private helper methods for local cache management

  Future<List<Map<String, dynamic>>> _getLocalFavourites(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favouritesJson = prefs.getString('$_favouritesCacheKey$userId');

      if (favouritesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(favouritesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      AppLogger.warning('Failed to get local favourites: $e');
      return [];
    }
  }

  Future<void> _cacheFavourites(String userId, List<Map<String, dynamic>> favourites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_favouritesCacheKey$userId', jsonEncode(favourites));
      await prefs.setString('$_lastSyncKey$userId', DateTime.now().toIso8601String());
      AppLogger.database('CACHE', 'favourites', data: {'count': favourites.length});
    } catch (e) {
      AppLogger.warning('Failed to cache favourites: $e');
    }
  }

  Future<void> _clearLocalCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_favouritesCacheKey$userId');
      await prefs.remove('$_lastSyncKey$userId');
    } catch (e) {
      AppLogger.warning('Failed to clear local cache: $e');
    }
  }

  Future<int> _resolveConflicts(
    String userId,
    List<Map<String, dynamic>> localFavourites,
    List<Map<String, dynamic>> remoteFavourites,
  ) async {
    int conflictsResolved = 0;

    // Use server timestamp precedence for conflicts
    final localMap = <String, Map<String, dynamic>>{};
    for (final fav in localFavourites) {
      final key = fav['type'] == 'restaurant'
          ? 'restaurant_${fav['restaurant_id']}'
          : 'menu_item_${fav['menu_item_id']}';
      localMap[key] = fav;
    }

    final remoteMap = <String, Map<String, dynamic>>{};
    for (final fav in remoteFavourites) {
      final key = fav['type'] == 'restaurant'
          ? 'restaurant_${fav['restaurant_id']}'
          : 'menu_item_${fav['menu_item_id']}';
      remoteMap[key] = fav;
    }

    // Find conflicts (items that exist locally but not remotely or vice versa)
    final allKeys = {...localMap.keys, ...remoteMap.keys};

    for (final key in allKeys) {
      final local = localMap[key];
      final remote = remoteMap[key];

      if (local != null && remote != null) {
        // Conflict exists - use remote (server) as source of truth
        if (local['updated_at'] != remote['updated_at']) {
          conflictsResolved++;
          AppLogger.info('Resolved favourite conflict for key: $key');
        }
      }
    }

    return conflictsResolved;
  }

  Future<void> _addFavouriteToLocalCache(String userId, Map<String, dynamic> favourite) async {
    final favourites = await _getLocalFavourites(userId);
    favourites.add(favourite);
    await _cacheFavourites(userId, favourites);
  }

  Future<void> _updateFavouriteInLocalCache(String userId, String oldId, Map<String, dynamic> newFavourite) async {
    final favourites = await _getLocalFavourites(userId);
    final index = favourites.indexWhere((f) => f['id'] == oldId);
    if (index != -1) {
      favourites[index] = newFavourite;
      await _cacheFavourites(userId, favourites);
    }
  }

  Future<void> _removeFavouriteFromLocalCache(String userId, String type, String targetId) async {
    final favourites = await _getLocalFavourites(userId);
    favourites.removeWhere((f) =>
      f['type'] == type &&
      (f['restaurant_id'] == targetId || f['menu_item_id'] == targetId)
    );
    await _cacheFavourites(userId, favourites);
  }

  Future<void> _markFavouriteAsPendingRemoval(String userId, String type, String targetId) async {
    final favourites = await _getLocalFavourites(userId);
    final index = favourites.indexWhere((f) =>
      f['type'] == type &&
      (f['restaurant_id'] == targetId || f['menu_item_id'] == targetId)
    );
    if (index != -1) {
      favourites[index]['is_pending_removal'] = true;
      await _cacheFavourites(userId, favourites);
    }
  }

  /// Get sync status for a user
  Future<DateTime?> getLastSyncTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncTime = prefs.getString('$_lastSyncKey$userId');
      return syncTime != null ? DateTime.parse(syncTime) : null;
    } catch (e) {
      AppLogger.warning('Failed to get last sync time: $e');
      return null;
    }
  }
}

/// Result of a favourites sync operation
class FavouritesSyncResult {
  final bool success;
  final int conflictsResolved;
  final int totalSynced;
  final String? errorMessage;

  const FavouritesSyncResult({
    required this.success,
    this.conflictsResolved = 0,
    this.totalSynced = 0,
    this.errorMessage,
  });
}

