import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Driver info card widget
class DriverInfoCard extends StatelessWidget {
  const DriverInfoCard({
    required this.driverName,
    required this.vehicleType,
    required this.vehicleNumber,
    this.driverPhoto,
    this.driverRating,
    this.driverPhone,
    this.distanceAway,
    super.key,
  });

  final String driverName;
  final String vehicleType;
  final String vehicleNumber;
  final String? driverPhoto;
  final double? driverRating;
  final String? driverPhone;
  final double? distanceAway; // in kilometers

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.delivery_dining,
                  color: Colors.black87,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Delivery Driver',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Driver photo
                _buildDriverAvatar(),
                const SizedBox(width: 16),

                // Driver info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (driverRating != null) _buildRating(),
                      const SizedBox(height: 8),
                      _buildVehicleInfo(context),
                      if (distanceAway != null) ...[
                        const SizedBox(height: 4),
                        _buildDistanceInfo(context),
                      ],
                    ],
                  ),
                ),

                // Action buttons
                Column(
                  children: [
                    _buildCallButton(context),
                    const SizedBox(height: 8),
                    _buildMessageButton(context),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverAvatar() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: ClipOval(
        child: driverPhoto != null
            ? CachedNetworkImage(
                imageUrl: driverPhoto!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 32, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, size: 32, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person, size: 32, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildRating() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.black87, size: 16),
        const SizedBox(width: 4),
        Text(
          driverRating!.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getVehicleIcon(),
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$vehicleType • $vehicleNumber',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
              ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo(BuildContext context) {
    final distance = distanceAway!;
    final distanceText = distance < 1
        ? '${(distance * 1000).round()}m away'
        : '${distance.toStringAsFixed(1)} km away';

    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: distance < 0.5 ? Colors.black87 : Colors.black87,
        ),
        const SizedBox(width: 4),
        Text(
          distanceText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: distance < 0.5 ? Colors.black87 : Colors.black87,
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon() {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
      case 'bicycle':
        return Icons.pedal_bike;
      case 'motorcycle':
      case 'scooter':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.delivery_dining;
    }
  }

  Widget _buildCallButton(BuildContext context) {
    return ElevatedButton(
      onPressed: driverPhone != null ? () => _makePhoneCall(context) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
      child: const Icon(Icons.phone, size: 20),
    );
  }

  Widget _buildMessageButton(BuildContext context) {
    return ElevatedButton(
      onPressed: driverPhone != null ? () => _sendMessage(context) : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
      child: const Icon(Icons.message, size: 20),
    );
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    if (driverPhone == null) return;

    final phoneNumber = driverPhone!.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showError(context, 'Could not launch phone dialer');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error making phone call: $e');
      }
    }
  }

  Future<void> _sendMessage(BuildContext context) async {
    if (driverPhone == null) return;

    final phoneNumber = driverPhone!.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'sms', path: phoneNumber);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          _showError(context, 'Could not launch messaging app');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error sending message: $e');
      }
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
