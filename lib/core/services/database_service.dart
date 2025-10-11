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
      throw StateError(
        'DatabaseService not initialized. Call initialize() first.',
      );
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
      if (url.contains('your-project') ||
          url.isEmpty ||
          !url.startsWith('http')) {
        print(
          'WARNING: Invalid Supabase URL. Please configure .env file with valid credentials.',
        );
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

  Future<Map<String, dynamic>> createUserProfile(
    Map<String, dynamic> data,
  ) async {
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

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await client.from('user_profiles').update(data).eq('id', userId);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  // Restaurant Operations
  Future<List<Map<String, dynamic>>> getRestaurants({
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
  }) async {
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
  Future<List<Map<String, dynamic>>> getRestaurantsByCategory(
    String category,
  ) async {
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

  Future<List<Map<String, dynamic>>> getMenuItemsByCategory(
    String restaurantId,
    String category,
  ) async {
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

  /// Get popular menu items for a restaurant
  /// Returns top items based on order frequency (simulated by rating for now)
  /// In a real app, this would query order_items to count orders
  Future<List<Map<String, dynamic>>> getPopularMenuItems(
    String restaurantId, {
    int limit = 5,
  }) async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order(
            'price',
            ascending: false,
          ) // Simulate popularity (high-end items tend to be ordered more)
          .limit(limit);
      return response;
    } catch (e) {
      // Handle error
      return [];
    }
  }

  /// Get a single menu item by ID
  Future<Map<String, dynamic>?> getMenuItemById(String menuItemId) async {
    try {
      final response = await client
          .from('menu_items')
          .select()
          .eq('id', menuItemId)
          .single();
      return response;
    } catch (e) {
      // Handle error
      return null;
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

  /// Get restaurants the user has ordered from recently (for Order Again section)
  /// Returns up to 10 unique restaurants ordered by most recent order
  Future<List<Map<String, dynamic>>> getUserRecentRestaurants(
    String userId,
  ) async {
    try {
      // Get recent orders with restaurant data
      final orders = await client
          .from('orders')
          .select(
            'restaurant_id, placed_at, restaurants(id, name, cuisine_type, rating, estimated_delivery_time, is_active)',
          )
          .eq('user_id', userId)
          .order('placed_at', ascending: false)
          .limit(50); // Get more orders to ensure variety after filtering

      // Extract unique restaurants (most recent first)
      final Map<String, Map<String, dynamic>> uniqueRestaurants = {};

      for (var order in orders) {
        final restaurantId = order['restaurant_id'] as String;
        final restaurantData = order['restaurants'] as Map<String, dynamic>?;

        // Skip if restaurant data is missing or restaurant is inactive
        if (restaurantData == null || restaurantData['is_active'] != true) {
          continue;
        }

        // Add if not already in map (keeps most recent)
        if (!uniqueRestaurants.containsKey(restaurantId)) {
          uniqueRestaurants[restaurantId] = restaurantData;
        }

        // Stop once we have 10 unique restaurants
        if (uniqueRestaurants.length >= 10) {
          break;
        }
      }

      return uniqueRestaurants.values.toList();
    } catch (e) {
      print('Error getting recent restaurants: $e');
      return [];
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

  // Review Operations
  /// Get reviews for a restaurant with pagination
  /// Returns reviews with user information joined
  Future<List<Map<String, dynamic>>> getRestaurantReviews(
    String restaurantId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await client
          .from('reviews')
          .select(
            'id, restaurant_id, user_id, rating, comment, created_at, user_profiles!reviews_user_id_fkey(full_name, avatar_url)',
          )
          .eq('restaurant_id', restaurantId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Transform the response to flatten user data
      return response.map<Map<String, dynamic>>((review) {
        final userProfile = review['user_profiles'] as Map<String, dynamic>?;
        return {
          'id': review['id'],
          'restaurant_id': review['restaurant_id'],
          'user_id': review['user_id'],
          'rating': review['rating'],
          'comment': review['comment'],
          'created_at': review['created_at'],
          'user_name': userProfile?['full_name'] ?? 'Anonymous',
          'user_avatar': userProfile?['avatar_url'],
        };
      }).toList();
    } catch (e) {
      print('Error getting restaurant reviews: $e');
      return [];
    }
  }

  /// Get rating breakdown for a restaurant
  /// Returns count for each rating (1-5 stars)
  Future<Map<int, int>> getRestaurantRatingBreakdown(
    String restaurantId,
  ) async {
    try {
      final reviews = await client
          .from('reviews')
          .select('rating')
          .eq('restaurant_id', restaurantId);

      final Map<int, int> breakdown = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (var review in reviews) {
        final rating = review['rating'] as int;
        breakdown[rating] = (breakdown[rating] ?? 0) + 1;
      }

      return breakdown;
    } catch (e) {
      print('Error getting rating breakdown: $e');
      return {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    }
  }

  /// Get total count of reviews for a restaurant
  Future<int> getRestaurantReviewsCount(String restaurantId) async {
    try {
      final response = await client
          .from('reviews')
          .select('id')
          .eq('restaurant_id', restaurantId)
          .count();

      // The count is returned in the response
      return response.count;
    } catch (e) {
      print('Error getting reviews count: $e');
      return 0;
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
