import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/order.dart';

class OrderPreparationTimelineWidget extends StatelessWidget {
  final Order order;
  final int remainingMinutes;

  const OrderPreparationTimelineWidget({
    Key? key,
    required this.order,
    required this.remainingMinutes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final stages = _getPreparationStages();
    final currentStageIndex = _getCurrentStageIndex();

    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isCompleted = index < currentStageIndex;
        final isCurrent = index == currentStageIndex;
        final isUpcoming = index > currentStageIndex;

        return Column(
          children: [
            _TimelineItem(
              title: stage.title,
              subtitle: stage.subtitle,
              icon: stage.icon,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isUpcoming: isUpcoming,
              time: stage.time,
              showProgress: isCurrent && stage.showProgress,
              progress: isCurrent && stage.showProgress ? _getProgressPercentage() : null,
            ),
            if (index < stages.length - 1)
              _TimelineConnector(
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              ),
          ],
        );
      }),
    );
  }

  List<PreparationStage> _getPreparationStages() {
    final now = DateTime.now();

    return [
      PreparationStage(
        title: 'Order Placed',
        subtitle: 'Your order has been received',
        icon: Icons.shopping_cart,
        time: _formatTime(order.placedAt),
        showProgress: false,
      ),
      PreparationStage(
        title: 'Order Confirmed',
        subtitle: 'Restaurant has confirmed your order',
        icon: Icons.check_circle,
        time: order.confirmedAt != null ? _formatTime(order.confirmedAt!) : null,
        showProgress: false,
      ),
      PreparationStage(
        title: 'Preparing',
        subtitle: remainingMinutes > 0
            ? 'Your order is being prepared ($remainingMinutes min remaining)'
            : 'Your order is being prepared',
        icon: Icons.restaurant,
        time: order.preparingAt != null ? _formatTime(order.preparingAt!) : null,
        showProgress: order.status == OrderStatus.preparing,
      ),
      PreparationStage(
        title: 'Ready for Pickup',
        subtitle: 'Your order is ready to be collected',
        icon: Icons.check,
        time: order.readyAt != null ? _formatTime(order.readyAt!) : null,
        showProgress: false,
      ),
    ];
  }

  int _getCurrentStageIndex() {
    switch (order.status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready_for_pickup:
        return 3;
      case OrderStatus.cancelled:
        return -1; // Show all as incomplete
    }
  }

  double _getProgressPercentage() {
    if (order.estimatedPreparationTime <= 0) return 0.0;
    if (remainingMinutes <= 0) return 1.0;

    final totalMinutes = order.estimatedPreparationTime.toDouble();
    final elapsedMinutes = totalMinutes - remainingMinutes;
    return (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final bool isCurrent;
  final bool isUpcoming;
  final String? time;
  final bool showProgress;
  final double? progress;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.isCurrent,
    required this.isUpcoming,
    this.time,
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color backgroundColor;

    if (isCompleted) {
      color = Colors.green;
      backgroundColor = Colors.green.withValues(alpha: 0.1);
    } else if (isCurrent) {
      color = Colors.purple;
      backgroundColor = Colors.purple.withValues(alpha: 0.1);
    } else {
      color = Colors.grey;
      backgroundColor = Colors.grey.withValues(alpha: 0.1);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon and circle
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),
              if (isCurrent && showProgress)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent || isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isUpcoming ? Colors.grey.shade600 : null,
                    ),
                  ),
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isUpcoming
                      ? Colors.grey.shade500
                      : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isCompleted;
  final bool isCurrent;

  const _TimelineConnector({
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Container(
        width: 2,
        height: 20,
        color: isCompleted
            ? Colors.green
            : isCurrent
                ? Colors.purple.withValues(alpha: 0.5)
                : Colors.grey.shade300,
      ),
    );
  }
}

class PreparationStage {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? time;
  final bool showProgress;

  PreparationStage({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.time,
    required this.showProgress,
  });
}