import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../providers/order_tracking_provider.dart';

/// Order status timeline widget showing visual progress
class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    required this.currentStatus,
    required this.statusHistory,
    super.key,
  });

  final OrderStatus currentStatus;
  final List<OrderStatusUpdate> statusHistory;

  @override
  Widget build(BuildContext context) {
    final steps = _getTimelineSteps();
    final currentStep = currentStatus.stepNumber;

    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Progress',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted = step.stepNumber <= currentStep;
            final isCurrent = step.stepNumber == currentStep;
            final isLast = index == steps.length - 1;

            // Find timestamp for this step
            final update = statusHistory.firstWhere(
              (u) => u.status == step.status,
              orElse: () => OrderStatusUpdate(
                status: step.status,
                timestamp: DateTime.now(),
              ),
            );

            return _TimelineStep(
              icon: step.icon,
              title: step.title,
              description: step.description,
              timestamp: isCompleted ? update.timestamp : null,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  List<_TimelineStepData> _getTimelineSteps() {
    return [
      _TimelineStepData(
        stepNumber: 0,
        status: OrderStatus.placed,
        icon: Icons.receipt_long,
        title: 'Order Placed',
        description: 'We received your order',
      ),
      _TimelineStepData(
        stepNumber: 1,
        status: OrderStatus.confirmed,
        icon: Icons.check_circle_outline,
        title: 'Order Confirmed',
        description: 'Restaurant confirmed',
      ),
      _TimelineStepData(
        stepNumber: 2,
        status: OrderStatus.preparing,
        icon: Icons.restaurant,
        title: 'Preparing',
        description: 'Your food is being prepared',
      ),
      _TimelineStepData(
        stepNumber: 3,
        status: OrderStatus.ready,
        icon: Icons.shopping_bag_outlined,
        title: 'Ready',
        description: 'Order is ready for pickup',
      ),
      _TimelineStepData(
        stepNumber: 4,
        status: OrderStatus.pickedUp,
        icon: Icons.local_shipping_outlined,
        title: 'Picked Up',
        description: 'Driver has your order',
      ),
      _TimelineStepData(
        stepNumber: 5,
        status: OrderStatus.onTheWay,
        icon: Icons.two_wheeler,
        title: 'On the Way',
        description: 'Your order is arriving',
      ),
      _TimelineStepData(
        stepNumber: 7,
        status: OrderStatus.delivered,
        icon: Icons.done_all,
        title: 'Delivered',
        description: 'Enjoy your meal!',
      ),
    ];
  }
}

/// Timeline step data
class _TimelineStepData {
  const _TimelineStepData({
    required this.stepNumber,
    required this.status,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int stepNumber;
  final OrderStatus status;
  final IconData icon;
  final String title;
  final String description;
}

/// Individual timeline step widget
class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    this.timestamp,
  });

  final IconData icon;
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final greyColor = Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: Icon and line
        Column(
          children: [
            // Icon circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? primaryColor
                    : isCurrent
                        ? primaryColor.withOpacity(0.2)
                        : greyColor,
                border: Border.all(
                  color: isCompleted || isCurrent ? primaryColor : greyColor,
                  width: 2.w,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        key: const ValueKey('check'),
                        color: Colors.white,
                        size: 24.sp,
                      )
                    : isCurrent
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              key: const ValueKey('loading'),
                              strokeWidth: 2.w,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          )
                        : Icon(
                            icon,
                            key: ValueKey(icon),
                            color: Colors.grey.shade400,
                            size: 24.sp,
                          ),
              ),
            ),
            // Connecting line
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 2.w,
                height: 60.h,
                color: isCompleted ? primaryColor : greyColor,
                margin: EdgeInsets.symmetric(vertical: 4.h),
              ),
          ],
        ),
        SizedBox(width: 16.w),
        // Right side: Text content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isCompleted || isCurrent
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                    if (timestamp != null && isCompleted)
                      Text(
                        _formatTime(timestamp!),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isCompleted || isCurrent
                        ? Colors.grey.shade700
                        : Colors.grey.shade400,
                  ),
                ),
                if (isCurrent) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'In Progress',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }
}

/// Compact horizontal timeline for smaller spaces
class CompactOrderTimeline extends StatelessWidget {
  const CompactOrderTimeline({
    required this.currentStatus,
    super.key,
  });

  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final currentStep = currentStatus.stepNumber;
    final totalSteps = 7;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final isCompleted = index <= currentStep;
              final isCurrent = index == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(index == 0 ? 4.r : 0),
                            right: Radius.circular(
                              index == totalSteps - 1 ? 4.r : 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentStatus.displayName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              Text(
                'Step ${currentStep + 1} of $totalSteps',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
