import 'package:flutter/material.dart';

/// Represents a single page/step in the onboarding flow
class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color? backgroundColor;
  final String? lottieAsset;
  final bool isLocationPermission;

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    this.backgroundColor,
    this.lottieAsset,
    this.isLocationPermission = false,
  });
}

/// Predefined onboarding pages based on PRD requirements
class OnboardingPages {
  static final List<OnboardingPageData> pages = [
    const OnboardingPageData(
      title: 'Discover Great Food',
      description:
          'Browse through hundreds of restaurants and find your favorite dishes with our interactive map view',
      icon: Icons.restaurant_menu_rounded,
      backgroundColor: Color(0xFFFF6B35),
      lottieAsset: 'assets/animations/discover_food.json',
    ),
    const OnboardingPageData(
      title: 'Order with Ease',
      description:
          'Customize your order, add to cart, and checkout securely with multiple payment options',
      icon: Icons.shopping_cart_rounded,
      backgroundColor: Color(0xFFF7931E),
      lottieAsset: 'assets/animations/easy_order.json',
    ),
    const OnboardingPageData(
      title: 'Track in Real-Time',
      description:
          'Watch your order come to life! Track your delivery driver in real-time on the map',
      icon: Icons.delivery_dining_rounded,
      backgroundColor: Color(0xFFFFB84D),
      lottieAsset: 'assets/animations/real_time_tracking.json',
    ),
    const OnboardingPageData(
      title: 'Location Access',
      description:
          'To show restaurants near you and provide accurate delivery, we need access to your location. You can change this anytime in settings.',
      icon: Icons.location_on_rounded,
      backgroundColor: Color(0xFF4CAF50),
      isLocationPermission: true,
    ),
  ];
}
