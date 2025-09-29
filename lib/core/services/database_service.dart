import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/constants/config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  
  // Test mode flag to disable client initialization in tests
  static bool _isTestMode = false;
  
  // Method to enable test mode
  static void enableTestMode() {
    _isTestMode = true;
  }
  
  // Method to disable test mode
  static void disableTestMode() {
    _isTestMode = false;
  }
  
  DatabaseService._internal() {
    // Initialize the client immediately to avoid late initialization errors
    // In test mode, we don't initialize the client to avoid pending timers
    if (!_isTestMode) {
      _client = SupabaseClient(Config.supabaseUrl, Config.supabaseAnonKey);
    }
  }

  SupabaseClient? _client;

  SupabaseClient get client {
    if (_client == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  Future<void> initialize() async {
    // In test mode, we don't initialize the client
    if (_isTestMode) {
      return;
    }
    
    // Already initialized in constructor for non-test mode
    // This method exists for backward compatibility but does nothing
    if (_client == null) {
      _client = SupabaseClient(Config.supabaseUrl, Config.supabaseAnonKey);
    }
  }

  // User Profile Operations
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  Future<Map<String, dynamic>> createUserProfile(Map<String, dynamic> data) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('user_profiles')
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      await _client!
          .from('user_profiles')
          .update(data)
          .eq('id', userId);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Restaurant Operations
  Future<List<Map<String, dynamic>>> getRestaurants({String? cuisineType, double? minRating, int? maxDeliveryTime}) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      var query = _client!.from('restaurants').select().eq('is_active', true);

      if (cuisineType != null) {
        query = query.ilike('cuisine_type', '%$cuisineType%');
      }
      if (minRating != null) {
        query = query.gte('rating', minRating);
      }
      if (maxDeliveryTime != null) {
        query = query.lte('estimated_delivery_time', maxDeliveryTime);
      }

      final response = await query.order('rating', ascending: false);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  Future<Map<String, dynamic>?> getRestaurant(String restaurantId) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();
      return response;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  // Menu Item Operations
  Future<List<Map<String, dynamic>>> getMenuItems(String restaurantId) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMenuItemsByCategory(String restaurantId, String category) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('category', category)
          .eq('is_available', true);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  // Order Operations
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('placed_at', ascending: false);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrder(String orderId) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      return response;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  Future<String> createOrder(Map<String, dynamic> orderData) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();
      return response['id'];
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Delivery Operations
  Future<Map<String, dynamic>?> getDelivery(String orderId) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final response = await _client!
          .from('deliveries')
          .select()
          .eq('order_id', orderId)
          .single();
      return response;
    } catch (e) {
      // Handle error
      return null;
    }
  }

  // Promotion Operations
  Future<List<Map<String, dynamic>>> getActivePromotions() async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final now = DateTime.now().toIso8601String();
      final response = await _client!
          .from('promotions')
          .select()
          .eq('is_active', true)
          .gte('valid_from', now)
          .lte('valid_until', now);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPromotionByCode(String code) async {
    try {
      if (_client == null) {
        throw StateError('DatabaseService not initialized. Call initialize() first.');
      }
      
      final now = DateTime.now().toIso8601String();
      final response = await _client!
          .from('promotions')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .lte('valid_from', now)
          .gte('valid_until', now)
          .single();
      return response;
    } catch (e) {
      // Promotion not found or not active
      return null;
    }
  }

  // Auth Operations
  GoTrueClient get auth {
    if (_client == null) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return _client!.auth;
  }
  
  // Dispose method to clean up resources
  Future<void> dispose() async {
    // In test mode, there's nothing to dispose
    if (_isTestMode || _client == null) {
      return;
    }
    
    // Sign out to clean up auth resources and stop auto-refresh timers
    await _client!.auth.signOut();
    // Note: Supabase client doesn't have a direct dispose method
    // but signing out stops the auto-refresh timers
  }
}