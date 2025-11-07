import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCartTap;
  final int cartItemCount;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCartTap,
    this.cartItemCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    isActive: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                  _buildNavItem(
                    icon: Icons.favorite_outline,
                    activeIcon: Icons.favorite,
                    label: 'Favourites',
                    index: 1,
                    isActive: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                  _buildCartFAB(),
                  _buildNavItem(
                    icon: Icons.storefront_outlined,
                    activeIcon: Icons.storefront_rounded,
                    label: 'Pickup Orders',
                    index: 2,
                    isActive: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                  _buildNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                    isActive: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? BrandColors.primary : NeutralColors.textSecondary,
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? BrandColors.primary : NeutralColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartFAB() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [BrandColors.primary, BrandColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: ShadowTokens.primaryShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCartTap,
              borderRadius: BorderRadius.circular(32),
              child: const Icon(
                Icons.shopping_cart_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        if (cartItemCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BrandColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
