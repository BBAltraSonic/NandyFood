import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/features/delivery/presentation/providers/delivery_orders_provider.dart';
import 'package:food_delivery_app/shared/widgets/order_history_item_widget.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(deliveryOrdersProvider);
    final notifier = ref.read(deliveryOrdersProvider.notifier);

    if (!ordersState.isLoadingHistory && ordersState.historyOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No past orders yet', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(RoutePaths.home),
                child: const Text('Browse restaurants'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order History'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          await notifier.refreshHistoryOrders();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200 &&
                !ordersState.isLoadingHistory) {
              notifier.loadMoreHistory();
            }
            return false;
          },
          child: ListView.builder(
            itemCount: ordersState.historyOrders.length + 1,
            itemBuilder: (context, index) {
              if (index < ordersState.historyOrders.length) {
                final order = ordersState.historyOrders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OrderHistoryItemWidget(
                        order: order,
                        onTap: () {
                          // Navigate to order tracking/details
                          context.push(RoutePaths.orderTrackWithId(order.id));
                        },
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Reorder'),
                          onPressed: () async {
                            final newOrderId = await notifier.reorder(order.id);
                            if (newOrderId != null && context.mounted) {
                              context.go(RoutePaths.orderTrackWithId(newOrderId));
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to reorder. Please try again.')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Footer: loading spinner or Load More button
              if (ordersState.isLoadingHistory) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () => notifier.loadMoreHistory(),
                    child: const Text('Load more'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
