import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/delivery.dart';

class DeliveryTrackingWidget extends StatelessWidget {
  final Delivery delivery;
  final int progress; // Progress percentage (0-100)

  const DeliveryTrackingWidget({
    super.key,
    required this.delivery,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(delivery.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    delivery.status.name,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated arrival: ${_formatTime(delivery.estimatedArrival ?? DateTime.now().add(const Duration(minutes: 20)))}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress bar
            Row(
              children: [
                Text(
                  '${progress > 100 ? 100 : progress}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(delivery.status)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Delivery status timeline
            _buildStatusTimeline(delivery.status),
          ],
        ),
      ),
    );
  }

  /// Build status timeline
  Widget _buildStatusTimeline(DeliveryStatus status) {
    final steps = [
      {'title': 'Order Assigned', 'status': DeliveryStatus.assigned},
      {'title': 'Picked Up', 'status': DeliveryStatus.pickedUp},
      {'title': 'In Transit', 'status': DeliveryStatus.inTransit},
      {'title': 'Delivered', 'status': DeliveryStatus.delivered},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final stepStatus = step['status'] as DeliveryStatus;
        final isCompleted = _isStepCompleted(status, stepStatus);
        final isCurrent = status == stepStatus;
        
        return Column(
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.deepOrange 
                        : (isCurrent ? Colors.orange : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 16),
                // Step title
                Expanded(
                  child: Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Colors.deepOrange : Colors.black,
                    ),
                  ),
                ),
                // Checkmark for completed steps
                if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: Colors.deepOrange,
                  ),
              ],
            ),
            // Connector line (except for last step)
            if (index < steps.length - 1)
              Container(
                height: 30,
                padding: const EdgeInsets.only(left: 15),
                child: VerticalDivider(
                  color: isCompleted ? Colors.deepOrange : Colors.grey.shade300,
                  width: 2,
                  thickness: 2,
                ),
              ),
          ],
        );
      }),
    );
  }

  /// Check if step is completed based on current delivery status
  bool _isStepCompleted(DeliveryStatus currentStatus, DeliveryStatus stepStatus) {
    final statusOrder = [
      DeliveryStatus.assigned,
      DeliveryStatus.pickedUp,
      DeliveryStatus.inTransit,
      DeliveryStatus.delivered,
    ];
    
    final currentIndex = statusOrder.indexOf(currentStatus);
    final stepIndex = statusOrder.indexOf(stepStatus);
    
    return stepIndex <= currentIndex;
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get color based on delivery status
  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
        return Colors.orange;
      case DeliveryStatus.inTransit:
        return Colors.deepOrange;
      case DeliveryStatus.delivered:
        return Colors.green;
    }
  }
}