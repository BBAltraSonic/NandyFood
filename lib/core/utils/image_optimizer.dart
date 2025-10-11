import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Image optimization utilities for better performance
class ImageOptimizer {
  /// Cache manager configuration
  static const int maxCacheObjects = 100;
  static const int maxCacheSizeBytes = 50 * 1024 * 1024; // 50MB
  
  /// Optimized network image with caching and placeholders
  static Widget optimizedNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    bool fadeIn = true,
    Duration fadeDuration = const Duration(milliseconds: 300),
    Map<String, String>? headers,
  }) {
    // Use low-quality placeholder for faster initial load
    final lowQualityImageUrl = _generateLowQualityImageUrl(imageUrl);
    
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(width, height),
      fadeInDuration: fadeIn ? fadeDuration : Duration.zero,
      fadeOutDuration: fadeIn ? fadeDuration : Duration.zero,
      httpHeaders: headers,
      memCacheWidth: _calculateCacheWidth(width),
      memCacheHeight: _calculateCacheHeight(height),
      maxHeightDiskCache: _calculateDiskCacheHeight(height),
      maxWidthDiskCache: _calculateDiskCacheWidth(width),
    );
  }
  
  /// Optimized asset image with proper sizing
  static Widget optimizedAssetImage({
    required String assetName,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      assetName,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth ?? _calculateCacheWidth(width),
      cacheHeight: cacheHeight ?? _calculateCacheHeight(height),
      filterQuality: FilterQuality.medium,
    );
  }
  
  /// Preload images to improve perceived performance
  static Future<void> preloadImages(List<String> imageUrls) async {
    if (kIsWeb) return; // Preloading not needed on web
    
    // Preload images in background
    for (final url in imageUrls) {
      try {
        await CacheManager(Config('customCache')).getSingleFile(url);
      } catch (e) {
        // Ignore preload errors
        debugPrint('Failed to preload image: $url, error: $e');
      }
    }
  }
  
  /// Clear image cache to free memory
  static Future<void> clearImageCache() async {
    // Clear the cache using the cache manager
    await DefaultCacheManager().emptyCache();
    // Also clear image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }
  
  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    // In a real implementation, we would get actual cache stats
    // For now, return dummy data
    return {
      'cacheSize': 0,
      'cachedObjects': 0,
      'maxCacheSize': maxCacheSizeBytes,
      'maxCacheObjects': maxCacheObjects,
    };
  }
  
  /// Generate low-quality image URL for placeholder
  static String _generateLowQualityImageUrl(String originalUrl) {
    // In a real implementation, this would generate a low-quality version
    // For now, we'll just return the original URL
    return originalUrl;
  }
  
  /// Default placeholder widget
  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image,
        color: Colors.grey,
        size: 40,
      ),
    );
  }
  
  /// Default error widget
  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.broken_image,
        color: Colors.red,
        size: 40,
      ),
    );
  }
  
  /// Calculate memory cache width
  static int? _calculateCacheWidth(double? width) {
    if (width == null) return null;
    return width.toInt().clamp(50, 2000);
  }
  
  /// Calculate memory cache height
  static int? _calculateCacheHeight(double? height) {
    if (height == null) return null;
    return height.toInt().clamp(50, 2000);
  }
  
  /// Calculate disk cache width
  static int? _calculateDiskCacheWidth(double? width) {
    if (width == null) return null;
    return (width * 1.5).toInt().clamp(100, 3000);
  }
  
  /// Calculate disk cache height
  static int? _calculateDiskCacheHeight(double? height) {
    if (height == null) return null;
    return (height * 1.5).toInt().clamp(100, 3000);
  }
}

/// Memory-efficient image widget
class MemoryEfficientImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCache;
  final int? cacheWidth;
  final int? cacheHeight;

  const MemoryEfficientImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.enableCache = true,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  State<MemoryEfficientImage> createState() => _MemoryEfficientImageState();
}

class _MemoryEfficientImageState extends State<MemoryEfficientImage> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until widget is visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return widget.placeholder ?? 
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey.shade300,
          );
    }

    if (widget.enableCache) {
      return ImageOptimizer.optimizedNetworkImage(
        imageUrl: widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: widget.placeholder,
        errorWidget: widget.errorWidget,
        // cacheWidth: widget.cacheWidth,  // Removed since it's not a valid parameter for optimizedNetworkImage
        // cacheHeight: widget.cacheHeight,  // Removed since it's not a valid parameter for optimizedNetworkImage
      );
    } else {
      return Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }
  }
}