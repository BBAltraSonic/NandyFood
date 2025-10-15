import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/promotion_provider.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/promotion_card.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';

/// Screen to browse and select promotions
class PromotionsScreen extends ConsumerStatefulWidget {
  final String? restaurantId;
  final double? orderAmount;

  const PromotionsScreen({
    Key? key,
    this.restaurantId,
    this.orderAmount,
  }) : super(key: key);

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load promotions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      if (authState.user != null) {
        ref.read(promotionProvider.notifier).loadRecommendedPromotions(
              userId: authState.user!.id,
              restaurantId: widget.restaurantId,
              orderAmount: widget.orderAmount,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final promotionState = ref.watch(promotionProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Available promotions tab
          _buildAvailablePromotions(promotionState, authState),
          // History tab
          _buildPromotionHistory(authState),
        ],
      ),
    );
  }

  Widget _buildAvailablePromotions(
    PromotionState promotionState,
    AuthState authState,
  ) {
    if (promotionState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (promotionState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              promotionState.errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (authState.user != null) {
                  ref.read(promotionProvider.notifier).loadRecommendedPromotions(
                        userId: authState.user!.id,
                        restaurantId: widget.restaurantId,
                        orderAmount: widget.orderAmount,
                      );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (promotionState.availablePromotions.isEmpty) {
      return EmptyStateWidget.noPromotions(
        onRefresh: authState.user != null
            ? () {
                ref.read(promotionProvider.notifier).loadRecommendedPromotions(
                      userId: authState.user!.id,
                      restaurantId: widget.restaurantId,
                      orderAmount: widget.orderAmount,
                    );
              }
            : null,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (authState.user != null) {
          await ref.read(promotionProvider.notifier).loadRecommendedPromotions(
                userId: authState.user!.id,
                restaurantId: widget.restaurantId,
                orderAmount: widget.orderAmount,
              );
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: promotionState.availablePromotions.length,
        itemBuilder: (context, index) {
          final promotion = promotionState.availablePromotions[index];
          final isApplied = promotionState.appliedPromotion?.id == promotion.id;

          return PromotionCard(
            promotion: promotion,
            isApplied: isApplied,
            onApply: () async {
              if (authState.user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to apply promotions')),
                );
                return;
              }

              if (widget.orderAmount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Order amount required to apply promotion')),
                );
                return;
              }

              final success = await ref.read(promotionProvider.notifier).applyPromotionCode(
                    promotion.code,
                    userId: authState.user!.id,
                    orderAmount: widget.orderAmount!,
                    restaurantId: widget.restaurantId,
                  );

              if (success && mounted) {
                Navigator.pop(context, promotion);
              } else if (mounted) {
                final errorMsg = ref.read(promotionProvider).errorMessage;
                if (errorMsg != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMsg)),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildPromotionHistory(AuthState authState) {
    if (authState.user == null) {
      return const Center(
        child: Text('Please login to view promotion history'),
      );
    }

    final historyAsync = ref.watch(userPromotionHistoryProvider(authState.user!.id));

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No promotion history',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applied promotions will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final item = history[index];
            final promotion = item['promotion'];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Icon(Icons.check, color: Colors.green[700]),
                ),
                title: Text(
                  promotion['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code: ${promotion['code']}'),
                    Text(
                      'Saved: R${item['discount_amount'].toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
                trailing: Text(
                  _formatDate(DateTime.parse(item['used_at'])),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Failed to load history'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(userPromotionHistoryProvider(authState.user!.id));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
