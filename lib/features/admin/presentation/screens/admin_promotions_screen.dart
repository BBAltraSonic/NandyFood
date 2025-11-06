import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/admin/presentation/providers/admin_promotion_provider.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/promotion_card.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';

/// Admin Promotions Management Screen
class AdminPromotionsScreen extends ConsumerStatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  ConsumerState<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends ConsumerState<AdminPromotionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load promotions when screen initializes
    Future.microtask(() {
      ref.read(adminPromotionProvider.notifier).loadAllPromotions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminPromotionState = ref.watch(adminPromotionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Promotions Management'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminPromotionProvider.notifier).loadAllPromotions();
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/admin/promotions/create');
            },
            tooltip: 'Create Promotion',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active', icon: Icon(Icons.local_offer)),
            Tab(text: 'Draft', icon: Icon(Icons.edit_note)),
            Tab(text: 'Expired', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPromotionsList(adminPromotionState.activePromotions, 'active'),
          _buildPromotionsList(adminPromotionState.draftPromotions, 'draft'),
          _buildPromotionsList(adminPromotionState.expiredPromotions, 'expired'),
        ],
      ),
    );
  }

  Widget _buildPromotionsList(List<Promotion> promotions, String status) {
    final theme = Theme.of(context);

    if (ref.watch(adminPromotionProvider).isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (promotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'active' ? Icons.local_offer_outlined :
              status == 'draft' ? Icons.edit_note_outlined :
              Icons.history_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${status} promotions',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == 'active' ? 'Create a new promotion to get started' :
              'No promotions found in this category',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (status == 'active') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/admin/promotions/create');
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Promotion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(adminPromotionProvider.notifier).loadAllPromotions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final promotion = promotions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                context.push('/admin/promotions/edit/${promotion.id}');
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status and actions
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Action buttons
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                context.push('/admin/promotions/edit/${promotion.id}');
                                break;
                              case 'duplicate':
                                _duplicatePromotion(promotion);
                                break;
                              case 'delete':
                                _deletePromotion(promotion);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy, size: 16),
                                  SizedBox(width: 8),
                                  Text('Duplicate'),
                                ],
                              ),
                            ),
                            if (status == 'draft')
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Promotion details
                    Text(
                      promotion.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promotion.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Discount info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BrandColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            promotion.discountText,
                            style: TextStyle(
                              color: BrandColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Code: ${promotion.code}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // Additional info
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      children: [
                        if (promotion.minOrderAmount != null)
                          _buildInfoChip(
                            Icons.shopping_cart,
                            'Min: R${promotion.minOrderAmount!.toStringAsFixed(2)}',
                          ),
                        if (promotion.isFirstOrderOnly)
                          _buildInfoChip(
                            Icons.star,
                            'First Order Only',
                          ),
                        if (promotion.usageLimit != null)
                          _buildInfoChip(
                            Icons.people,
                            '${promotion.usageLimit} uses left',
                          ),
                      ],
                    ),

                    // Date range
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(promotion.startDate)} - ${_formatDate(promotion.endDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'draft':
        return Colors.orange;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _duplicatePromotion(Promotion promotion) {
    // Create a copy of the promotion with modified title/code
    ref.read(adminPromotionProvider.notifier).duplicatePromotion(promotion);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Promotion duplicated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deletePromotion(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text('Are you sure you want to delete "${promotion.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(adminPromotionProvider.notifier).deletePromotion(promotion.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Promotion deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}