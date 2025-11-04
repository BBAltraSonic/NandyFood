import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';

class StaffMemberCard extends StatelessWidget {
  final RestaurantStaff staff;
  final VoidCallback? onEdit;
  final Function(StaffStatus)? onUpdateStatus;
  final VoidCallback? onRemove;

  const StaffMemberCard({
    super.key,
    required this.staff,
    this.onEdit,
    this.onUpdateStatus,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: staff.userProfile?.avatarUrl != null
              ? CachedNetworkImageProvider(staff.userProfile!.avatarUrl!)
              : null,
          child: staff.userProfile?.avatarUrl == null
              ? Text(
                  _getInitials(staff.userProfile?.fullName),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                staff.userProfile?.fullName ?? 'Unknown',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildStatusChip(),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              staff.userProfile?.email ?? 'No email',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleChip(),
                const SizedBox(width: 8),
                _buildEmploymentTypeChip(),
              ],
            ),
            if (staff.notes != null && staff.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                staff.notes!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (staff.hiredDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hired: ${_formatDate(staff.hiredDate)}',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit?.call();
                break;
              case 'status':
                _showStatusMenu(context);
                break;
              case 'remove':
                onRemove?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'status',
              child: Row(
                children: [
                  Icon(Icons.swap_vert, size: 20),
                  SizedBox(width: 8),
                  Text('Change Status'),
                ],
              ),
            ),
            if (staff.status != StaffStatus.terminated)
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, size: 20, color: Colors.black87),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color color;
    IconData icon;

    switch (staff.status) {
      case StaffStatus.active:
        color = Colors.black54;
        icon = Icons.check_circle;
        break;
      case StaffStatus.onLeave:
        color = Colors.black54;
        icon = Icons.beach_access;
        break;
      case StaffStatus.suspended:
        color = Colors.black87;
        icon = Icons.block;
        break;
      case StaffStatus.terminated:
        color = Colors.grey;
        icon = Icons.person_off;
        break;
      case StaffStatus.pending:
        color = Colors.black54;
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            staff.statusDisplayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip() {
    Color color;
    IconData icon;

    switch (staff.role) {
      case StaffRoleType.manager:
        color = Colors.black54;
        icon = Icons.admin_panel_settings;
        break;
      case StaffRoleType.chef:
        color = Colors.black54;
        icon = Icons.restaurant;
        break;
      case StaffRoleType.cashier:
        color = Colors.black54;
        icon = Icons.point_of_sale;
        break;
      case StaffRoleType.server:
        color = Colors.black54;
        icon = Icons.room_service;
        break;
      case StaffRoleType.deliveryCoordinator:
        color = Colors.black54;
        icon = Icons.delivery_dining;
        break;
      case StaffRoleType.basicStaff:
        color = Colors.grey;
        icon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            staff.roleDisplayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentTypeChip() {
    Color color;
    IconData icon;

    switch (staff.employmentType) {
      case EmploymentType.fullTime:
        color = Colors.black54;
        icon = Icons.work;
        break;
      case EmploymentType.partTime:
        color = Colors.black54;
        icon = Icons.access_time;
        break;
      case EmploymentType.contractor:
        color = Colors.black54;
        icon = Icons.handshake;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            staff.employmentTypeDisplayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Change Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...StaffStatus.values.map((status) {
              if (status == staff.status) return const SizedBox.shrink();

              return ListTile(
                leading: _getStatusIcon(status),
                title: Text(status.name
                    .split('_')
                    .map((word) => word[0].toUpperCase() + word.substring(1))
                    .join(' ')),
                onTap: () {
                  Navigator.pop(context);
                  onUpdateStatus?.call(status);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Icon _getStatusIcon(StaffStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case StaffStatus.active:
        color = Colors.black54;
        icon = Icons.check_circle;
        break;
      case StaffStatus.onLeave:
        color = Colors.black54;
        icon = Icons.beach_access;
        break;
      case StaffStatus.suspended:
        color = Colors.black87;
        icon = Icons.block;
        break;
      case StaffStatus.terminated:
        color = Colors.grey;
        icon = Icons.person_off;
        break;
      case StaffStatus.pending:
        color = Colors.black54;
        icon = Icons.hourglass_empty;
        break;
    }

    return Icon(icon, color: color);
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return parts[0][0] + parts[1][0];
    } else {
      return name.substring(0, 1);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}