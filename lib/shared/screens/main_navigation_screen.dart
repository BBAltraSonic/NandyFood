import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

import 'package:food_delivery_app/features/home/presentation/screens/home_screen.dart';
import 'package:food_delivery_app/features/favourites/presentation/screens/favourites_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_history_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:food_delivery_app/shared/widgets/modern_bottom_navigation.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final cartItemCount = cartState.items.length;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: const [
          HomeScreen(),           // Index 0: Home
          FavouritesScreen(),     // Index 1: Favourites
          OrderHistoryScreen(),   // Index 2: Orders
          ProfileScreen(),        // Index 3: Profile
        ],
      ),
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        cartItemCount: cartItemCount,
        onCartTap: () {
          context.push(RoutePaths.orderCart);
        },
      ),
    );
  }
}
