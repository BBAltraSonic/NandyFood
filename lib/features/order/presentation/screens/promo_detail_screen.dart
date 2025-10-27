import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

import 'package:food_delivery_app/core/services/promotion_service.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

typedef PromotionLoader = Future<Promotion?> Function(String id);

class PromoDetailScreen extends ConsumerWidget {
  final String promoId;
  final PromotionService? service;
  final PromotionLoader? loader;
  const PromoDetailScreen({super.key, required this.promoId, this.service, this.loader});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promotion')),
      body: FutureBuilder<Promotion?>(
        future: loader != null
            ? loader!(promoId)
            : (service ?? PromotionService()).getPromotionById(promoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(
              message: 'Failed to load promotion.',
              onRetry: () => context.go(RoutePaths.promo(promoId)),
            );
          }
          final promo = snapshot.data;
          if (promo == null) {
            return _ErrorView(
              message: 'Promotion not found.',
              onRetry: () => context.go(RoutePaths.promo(promoId)),
            );
          }
          return _PromoContent(promotion: promo, onApply: (code) async {
            await ref.read(cartProvider.notifier).applyPromoCode(code);
            final cart = ref.read(cartProvider);
            if (cart.errorMessage != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(cart.errorMessage!)),
                );
              }
              return;
            }
            AppLogger.userAction('promo_apply_success', context: {
              'code': code,
              'subtotal': cart.subtotal,
              'discount': cart.discountAmount,
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Applied code $code')),
              );
              context.go(RoutePaths.orderCart);
            }
          });
        },
      ),
    );
  }
}

class _PromoContent extends ConsumerWidget {
  final Promotion promotion;
  final Future<void> Function(String code) onApply;
  const _PromoContent({required this.promotion, required this.onApply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final subtotal = cart.subtotal;

    final bool belowMin = promotion.minOrderAmount != null && subtotal < promotion.minOrderAmount!;
    final bool canApply = promotion.isValid && !belowMin;

    String? disabledReason;
    if (!promotion.isValid) {
      disabledReason = 'Promo is expired or inactive';
    } else if (belowMin) {
      disabledReason = 'Minimum order of R${promotion.minOrderAmount!.toStringAsFixed(2)} required. '
          'Your subtotal is R${subtotal.toStringAsFixed(2)}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            promotion.title,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            promotion.discountText,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.deepOrange, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            promotion.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                promotion.isValid ? 'Currently valid' : 'Expired or inactive',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
          if (promotion.minOrderAmount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Minimum order: R${promotion.minOrderAmount!.toStringAsFixed(2)}'),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canApply ? () => onApply(promotion.code) : null,
              icon: const Icon(Icons.local_offer_outlined),
              label: Text('Apply code ${promotion.code}'),
            ),
          ),
          if (disabledReason != null) ...[
            const SizedBox(height: 8),
            Text(
              disabledReason,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorView({required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
                const SizedBox(width: 12),
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

