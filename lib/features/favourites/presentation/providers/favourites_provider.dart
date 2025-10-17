import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

class FavouritesState {
  final List<MenuItem> items;
  final List<Restaurant> restaurants;
  final bool isLoading;
  final String? error;

  const FavouritesState({
    this.items = const [],
    this.restaurants = const [],
    this.isLoading = false,
    this.error,
  });

  FavouritesState copyWith({
    List<MenuItem>? items,
    List<Restaurant>? restaurants,
    bool? isLoading,
    String? error,
  }) => FavouritesState(
        items: items ?? this.items,
        restaurants: restaurants ?? this.restaurants,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final favouritesProvider = StateNotifierProvider<FavouritesNotifier, FavouritesState>((ref) {
  return FavouritesNotifier();
});

class FavouritesNotifier extends StateNotifier<FavouritesState> {
  FavouritesNotifier() : super(const FavouritesState());

  static const _spItemKeyPrefix = 'fav_items_';
  static const _spRestaurantKeyPrefix = 'fav_restaurants_';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String?> _userId() async => _supabase.auth.currentUser?.id;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId = await _userId();
      if (userId == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final items = await _loadFavoriteItems(userId);
      final restaurants = await _loadFavoriteRestaurants(userId);

      state = state.copyWith(items: items, restaurants: restaurants, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<MenuItem>> _loadFavoriteItems(String userId) async {
    try {
      final response = await _supabase
          .from('favorite_items')
          .select('item_id')
          .eq('user_id', userId);

      final ids = (response as List).map((e) => e['item_id'] as String).toList();
      final db = DatabaseService();
      final results = <MenuItem>[];
      for (final id in ids) {
        final json = await db.getMenuItemById(id);
        if (json != null) results.add(MenuItem.fromJson(json));
      }
      return results;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_spItemKeyPrefix$userId');
      final ids = data != null ? (jsonDecode(data) as List).cast<String>() : <String>[];
      final db = DatabaseService();
      final results = <MenuItem>[];
      for (final id in ids) {
        final json = await db.getMenuItemById(id);
        if (json != null) results.add(MenuItem.fromJson(json));
      }
      return results;
    }
  }

  Future<List<Restaurant>> _loadFavoriteRestaurants(String userId) async {
    try {
      final response = await _supabase
          .from('favorite_restaurants')
          .select('restaurant_id')
          .eq('user_id', userId);

      final ids = (response as List).map((e) => e['restaurant_id'] as String).toList();
      final db = DatabaseService();
      final results = <Restaurant>[];
      for (final id in ids) {
        final json = await db.getRestaurant(id);
        if (json != null) results.add(Restaurant.fromJson(json));
      }
      return results;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('$_spRestaurantKeyPrefix$userId');
      final ids = data != null ? (jsonDecode(data) as List).cast<String>() : <String>[];
      final db = DatabaseService();
      final results = <Restaurant>[];
      for (final id in ids) {
        final json = await db.getRestaurant(id);
        if (json != null) results.add(Restaurant.fromJson(json));
      }
      return results;
    }
  }

  Future<void> toggleItem(String itemId) async {
    final userId = await _userId();
    if (userId == null) return;
    try {
      // Try Supabase
      final existing = await _supabase
          .from('favorite_items')
          .select('id')
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .maybeSingle();
      if (existing != null) {
        await _supabase.from('favorite_items').delete().eq('id', existing['id']);
      } else {
        await _supabase.from('favorite_items').insert({'user_id': userId, 'item_id': itemId});
      }
    } catch (_) {
      // Fallback to local
      final prefs = await SharedPreferences.getInstance();
      final key = '$_spItemKeyPrefix$userId';
      final current = prefs.getString(key);
      final ids = current != null ? (jsonDecode(current) as List).cast<String>() : <String>[];
      if (ids.contains(itemId)) {
        ids.remove(itemId);
      } else {
        ids.add(itemId);
      }
      await prefs.setString(key, jsonEncode(ids));
    }
    await load();
  }

  Future<void> toggleRestaurant(String restaurantId) async {
    final userId = await _userId();
    if (userId == null) return;
    try {
      final existing = await _supabase
          .from('favorite_restaurants')
          .select('id')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .maybeSingle();
      if (existing != null) {
        await _supabase.from('favorite_restaurants').delete().eq('id', existing['id']);
      } else {
        await _supabase
            .from('favorite_restaurants')
            .insert({'user_id': userId, 'restaurant_id': restaurantId});
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_spRestaurantKeyPrefix$userId';
      final current = prefs.getString(key);
      final ids = current != null ? (jsonDecode(current) as List).cast<String>() : <String>[];
      if (ids.contains(restaurantId)) {
        ids.remove(restaurantId);
      } else {
        ids.add(restaurantId);
      }
      await prefs.setString(key, jsonEncode(ids));
    }
    await load();
  }
}
