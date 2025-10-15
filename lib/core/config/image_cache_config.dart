import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Configuration for image caching and loading optimization
class ImageCacheConfig {
  /// Configure image cache settings for optimal performance
  static void configure() {
    // Default cache manager is already configured, but we can customize
    // No additional configuration needed for basic setup
    // cached_network_image handles this automatically
  }

  /// Custom cache manager with optimized settings
  static CacheManager get customCacheManager => CacheManager(
        Config(
          'customCacheKey',
          stalePeriod: const Duration(days: 7), // Cache for 7 days
          maxNrOfCacheObjects: 200, // Max 200 images in cache
          repo: JsonCacheInfoRepository(databaseName: 'customCacheKey'),
          fileService: HttpFileService(),
        ),
      );

  /// Memory cache configuration
  static const int maxMemoryCacheSize = 100; // 100 MB
  static const int maxMemoryCacheCount = 100; // 100 images

  /// Disk cache configuration  
  static const int maxDiskCacheSize = 1024 * 1024 * 100; // 100 MB
  static const Duration cacheDuration = Duration(days: 7);

  /// Progressive image loading settings
  static const Duration fadeInDuration = Duration(milliseconds: 300);
  static const Duration fadeOutDuration = Duration(milliseconds: 100);

  /// Image quality settings
  static const int thumbnailQuality = 50; // 50% quality for thumbnails
  static const int fullImageQuality = 85; // 85% quality for full images

  /// Network timeout settings
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
