import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/order/presentation/providers/promotion_provider.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/promotion_card.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Promotions section widget for home screen
class PromotionsSection extends ConsumerStatefulWidget {
  const PromotionsSection({super.key});

  @override
  ConsumerState<PromotionsSection> createState() => _PromotionsSectionState();
}

class _PromotionsSectionState extends ConsumerState<PromotionsSection> {
  @override
  void initState() {
    super.initState();
    // Load promotions when widget initializes
    Future.microtask(() {
      ref.read(promotionProvider.notifier).loadPromotions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final promotionState = ref.watch(promotionProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Special Offers',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NeutralColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all promotions
                  context.push('/promotions');
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Promotions content
        if (promotionState.isLoading)
          _buildLoadingState()
        else if (promotionState.errorMessage != null)
          _buildErrorState(theme, promotionState.errorMessage!)
        else if (promotionState.availablePromotions.isEmpty)
          _buildEmptyState(theme)
        else
          _buildPromotionsList(promotionState.availablePromotions.take(3).toList()),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.secondary.withValues(alpha: 0.1),
              BrandColors.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BrandColors.secondary),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String errorMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () {
          // Retry loading promotions
          ref.read(promotionProvider.notifier).loadPromotions();
        },
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.1),
                Colors.red.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 32,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load promotions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.red.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to retry',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.secondary.withValues(alpha: 0.1),
              BrandColors.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 32,
                color: BrandColors.secondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 8),
              Text(
                'No active promotions',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: BrandColors.secondary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check back later for special offers',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: BrandColors.secondary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionsList(List promotions) {
    return Container(
      height: 180, // Reduced height to prevent overflow
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return Container(
            width: 300,
            child: PromotionCard(
              promotion: promotion,
              onApply: () {
                // Copy promotion code to clipboard
                _copyPromotionCode(context, promotion.code);
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Promotion code ${promotion.code} copied!'),
                    backgroundColor: BrandColors.primary,
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Mark promotion as applied in state
                ref.read(promotionProvider.notifier).applyPromotionCode(
                  promotion.code,
                  userId: '', // Will need current user ID
                  orderAmount: 0.0, // Will need actual order amount
                  isFirstOrder: promotion.isFirstOrderOnly,
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _copyPromotionCode(BuildContext context, String code) {
    // This would ideally use a clipboard service
    // For now, just show the code in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promotion Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Use this code at checkout to get your discount!',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}