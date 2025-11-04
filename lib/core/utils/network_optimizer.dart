import 'dart:async';
import 'dart:io';

/// Utility class for network request optimization
class NetworkOptimizer {
  static final NetworkOptimizer _instance = NetworkOptimizer._internal();
  factory NetworkOptimizer() => _instance;
  NetworkOptimizer._internal();

  // Cache for active requests to prevent duplicates
  final Map<String, Future> _activeRequests = {};

  // Cache for completed requests with TTL
  final Map<String, _CachedResponse> _responseCache = {};

  // Default cache duration
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  /// Execute a request with deduplication and caching
  Future<T> executeRequest<T>(
    String cacheKey,
    Future<T> Function() requestFunction, {
    Duration? cacheDuration,
    bool bypassCache = false,
  }) async {
    // Check cache first (unless bypassed)
    if (!bypassCache && _responseCache.containsKey(cacheKey)) {
      final cached = _responseCache[cacheKey]!;
      if (!cached.isExpired) {
        print('📦 Cache hit for: $cacheKey');
        return cached.data as T;
      } else {
        // Remove expired cache entry
        _responseCache.remove(cacheKey);
      }
    }

    // Check if request is already in progress
    if (_activeRequests.containsKey(cacheKey)) {
      print('⏳ Request deduplication for: $cacheKey');
      return await _activeRequests[cacheKey] as T;
    }

    // Execute request
    print('🌐 Executing new request: $cacheKey');
    final requestFuture = requestFunction();
    _activeRequests[cacheKey] = requestFuture;

    try {
      final result = await requestFuture;

      // Cache the result
      _responseCache[cacheKey] = _CachedResponse(
        data: result,
        timestamp: DateTime.now(),
        duration: cacheDuration ?? _defaultCacheDuration,
      );

      return result;
    } catch (e) {
      print('❌ Request failed for $cacheKey: $e');
      rethrow;
    } finally {
      // Clean up active request
      _activeRequests.remove(cacheKey);
    }
  }

  /// Clear all cache
  void clearCache() {
    _responseCache.clear();
    print('🧹 Network cache cleared');
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final expiredKeys = _responseCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _responseCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      print('🧹 Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'activeRequests': _activeRequests.length,
      'cachedResponses': _responseCache.length,
      'expiredResponses': _responseCache.values
          .where((response) => response.isExpired)
          .length,
    };
  }

  /// Check if cached response exists and is valid
  bool hasCachedResponse(String cacheKey) {
    final cached = _responseCache[cacheKey];
    return cached != null && !cached.isExpired;
  }

  /// Force refresh a specific cache key
  Future<T> refreshRequest<T>(
    String cacheKey,
    Future<T> Function() requestFunction, {
    Duration? cacheDuration,
  }) async {
    // Remove existing cache entry
    _responseCache.remove(cacheKey);

    // Execute request with bypassed cache
    return executeRequest(
      cacheKey,
      requestFunction,
      cacheDuration: cacheDuration,
      bypassCache: true,
    );
  }
}

/// Internal class to store cached responses with TTL
class _CachedResponse<T> {
  final T data;
  final DateTime timestamp;
  final Duration duration;

  _CachedResponse({
    required this.data,
    required this.timestamp,
    required this.duration,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > duration;

  int get ageInSeconds => DateTime.now().difference(timestamp).inSeconds;
}

/// HTTP response cache configuration
class HttpCacheConfig {
  static const Duration shortCache = Duration(minutes: 1);
  static const Duration mediumCache = Duration(minutes: 5);
  static const Duration longCache = Duration(minutes: 15);
  static const Duration extendedCache = Duration(hours: 1);

  /// Get appropriate cache duration based on content type
  static Duration getCacheDurationForEndpoint(String endpoint) {
    if (endpoint.contains('/restaurants')) {
      return mediumCache; // Restaurant data changes occasionally
    }
    if (endpoint.contains('/menu_items')) {
      return shortCache; // Menu items can change frequently
    }
    if (endpoint.contains('/promotions')) {
      return shortCache; // Promotions are time-sensitive
    }
    if (endpoint.contains('/orders/')) {
      return extendedCache; // Order history doesn't change often
    }
    if (endpoint.contains('/user/profile')) {
      return mediumCache; // User profile changes occasionally
    }

    return mediumCache; // Default cache duration
  }

  /// Check if endpoint should be cached based on HTTP method
  static bool shouldCacheEndpoint(String method, String endpoint) {
    // Only cache GET requests
    if (method.toUpperCase() != 'GET') return false;

    // Don't cache sensitive endpoints
    if (endpoint.contains('/auth/')) return false;
    if (endpoint.contains('/payment/')) return false;
    if (endpoint.contains('/admin/')) return false;

    return true;
  }
}

/// Network performance monitor
class NetworkPerformanceMonitor {
  static final NetworkPerformanceMonitor _instance = NetworkPerformanceMonitor._internal();
  factory NetworkPerformanceMonitor() => _instance;
  NetworkPerformanceMonitor._internal();

  final Map<String, List<int>> _requestTimes = {};
  final Map<String, int> _errorCounts = {};

  /// Record a successful request
  void recordSuccess(String endpoint, int durationMs) {
    _requestTimes.putIfAbsent(endpoint, () => []).add(durationMs);

    // Keep only last 100 requests per endpoint
    if (_requestTimes[endpoint]!.length > 100) {
      _requestTimes[endpoint]!.removeRange(0, _requestTimes[endpoint]!.length - 100);
    }
  }

  /// Record a failed request
  void recordError(String endpoint) {
    _errorCounts[endpoint] = (_errorCounts[endpoint] ?? 0) + 1;
  }

  /// Get performance statistics for an endpoint
  Map<String, dynamic> getStatsForEndpoint(String endpoint) {
    final times = _requestTimes[endpoint] ?? [];
    final errorCount = _errorCounts[endpoint] ?? 0;

    if (times.isEmpty) {
      return {
        'endpoint': endpoint,
        'requestCount': 0,
        'averageTime': 0,
        'minTime': 0,
        'maxTime': 0,
        'errorCount': errorCount,
        'errorRate': 0.0,
      };
    }

    final avgTime = times.reduce((a, b) => a + b) / times.length;
    final minTime = times.reduce((a, b) => a < b ? a : b);
    final maxTime = times.reduce((a, b) => a > b ? a : b);
    final totalRequests = times.length + errorCount;
    final errorRate = totalRequests > 0 ? errorCount / totalRequests : 0.0;

    return {
      'endpoint': endpoint,
      'requestCount': times.length,
      'errorCount': errorCount,
      'totalRequests': totalRequests,
      'averageTime': avgTime.round(),
      'minTime': minTime,
      'maxTime': maxTime,
      'errorRate': (errorRate * 100).toStringAsFixed(2) + '%',
    };
  }

  /// Get all performance statistics
  Map<String, dynamic> getAllStats() {
    final allEndpoints = <String>{..._requestTimes.keys, ..._errorCounts.keys};

    return {
      'endpoints': allEndpoints.map((endpoint) => getStatsForEndpoint(endpoint)).toList(),
      'totalEndpoints': allEndpoints.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all statistics
  void clearStats() {
    _requestTimes.clear();
    _errorCounts.clear();
  }
}