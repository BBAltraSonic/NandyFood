import 'package:flutter/material.dart';

/// A widget that provides a Hero animation with a custom tag
class AnimatedHero extends StatelessWidget {
  final Widget child;
  final String tag;
  final Duration duration;
  final Curve flightCurve;
  final bool createRectTween;
  final RectTween? rectTween;

  const AnimatedHero({
    super.key,
    required this.child,
    required this.tag,
    this.duration = const Duration(milliseconds: 300),
    this.flightCurve = Curves.easeInOut,
    this.createRectTween = false,
    this.rectTween,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromContext,
        BuildContext toContext,
      ) {
        return AnimatedContainer(
          duration: duration,
          curve: flightCurve,
          child: child,
        );
      },
      placeholderBuilder: (context, size, child) {
        return Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
      transitionBuilder: (context, animation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: flightCurve,
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// A specialized Hero for restaurant images
class RestaurantHero extends StatelessWidget {
  final String restaurantId;
  final String? imageUrl;
  final String restaurantName;
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const RestaurantHero({
    super.key,
    required this.restaurantId,
    this.imageUrl,
    required this.restaurantName,
    this.height = 200,
    this.width = double.infinity,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'restaurant_$restaurantId';

    return AnimatedHero(
      tag: tag,
      duration: const Duration(milliseconds: 400),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            color: Colors.grey.shade300,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black87,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
                // Center icon
                Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                // Optional image overlay
                if (imageUrl != null)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black87,
                              Colors.black87,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    },
                  ),
                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
                // Restaurant name overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    restaurantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A specialized Hero for menu item images
class MenuItemHero extends StatelessWidget {
  final String menuItemId;
  final String? imageUrl;
  final String itemName;
  final double height;
  final double width;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const MenuItemHero({
    super.key,
    required this.menuItemId,
    this.imageUrl,
    required this.itemName,
    this.height = 120,
    this.width = double.infinity,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tag = 'menu_item_$menuItemId';

    return AnimatedHero(
      tag: tag,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Placeholder gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black87,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
                // Center icon
                Center(
                  child: Icon(
                    Icons.local_dining,
                    size: 32,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                // Optional image overlay
                if (imageUrl != null)
                  Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black87,
                              Colors.black87,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_dining,
                            size: 32,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}