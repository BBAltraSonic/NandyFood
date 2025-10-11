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
  
  DatabaseService._internal();

  bool _initialized = false;

  SupabaseClient get client {
    if (!_initialized && !_isTestMode) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    // In test mode, we don't initialize the client
    if (_isTestMode) {
      return;
    }
    
    if (_initialized) {
      return; // Already initialized
    }
    
    try {
      final url = Config.supabaseUrl;
      final key = Config.supabaseAnonKey;
      
      // Validate URL format
      if (url.contains('your-project') || url.isEmpty || !url.startsWith('http')) {
        print('WARNING: Invalid Supabase URL. Please configure .env file with valid credentials.');
        print('Current URL: $url');
        throw Exception('Invalid Supabase configuration');
      }
      
      await Supabase.initialize(
        url: url,
        anonKey: key,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      
      _initialized = true;
      print('✅ Supabase initialized successfully');
      print('📡 Connected to: $url');
    } catch (e) {
      print('ERROR: Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  // User Profile Operations
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
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
      final response = await client
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
      await client
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
      var query = client.from('restaurants').select().eq('is_active', true);

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
      final response = await client
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

  /// Search restaurants by name or cuisine type
  Future<List<Map<String, dynamic>>> searchRestaurants(String query) async {
    try {
      final searchQuery = query.trim().toLowerCase();
      final response = await client
          .from('restaurants')
          .select()
          .eq('is_active', true)
          .or('name.ilike.%$searchQuery%,cuisine_type.ilike.%$searchQuery%')
          .order('rating', ascending: false)
          .limit(50);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  /// Filter restaurants by category (cuisine type)
  Future<List<Map<String, dynamic>>> getRestaurantsByCategory(String category) async {
    try {
      if (category == 'all') {
        return getRestaurants();
      }
      
      final response = await client
          .from('restaurants')
          .select()
          .eq('is_active', true)
          .ilike('cuisine_type', '%$category%')
          .order('rating', ascending: false);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  // Menu Item Operations
  Future<List<Map<String, dynamic>>> getMenuItems(String restaurantId) async {
    try {
      final response = await client
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
      final response = await client
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
      final response = await client
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
      final response = await client
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
      final response = await client
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
      final response = await client
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
      final now = DateTime.now().toIso8601String();
      final response = await client
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
      final now = DateTime.now().toIso8601String();
      final response = await client
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
  GoTrueClient get auth => client.auth;
  
  // Dispose method to clean up resources
  Future<void> dispose() async {
    // In test mode, there's nothing to dispose
    if (_isTestMode || !_initialized) {
      return;
    }
    
    // Sign out to clean up auth resources and stop auto-refresh timers
    await client.auth.signOut();
    // Note: Supabase client doesn't have a direct dispose method
    // but signing out stops the auto-refresh timers
  }
}
