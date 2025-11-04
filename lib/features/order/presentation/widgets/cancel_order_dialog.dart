import 'package:flutter/material.dart';

/// Cancel order dialog with reason selection
class CancelOrderDialog extends StatefulWidget {
  const CancelOrderDialog({
    required this.orderId,
    required this.onCancel,
    super.key,
  });

  final String orderId;
  final Future<void> Function(String reason, String? additionalNotes) onCancel;

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> {
  String? _selectedReason;
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  final List<String> _cancellationReasons = [
    'Changed my mind',
    'Ordered by mistake',
    'Found better option',
    'Taking too long',
    'Wrong delivery address',
    'Restaurant closed',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cancellation reason'),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await widget.onCancel(
        _selectedReason!,
        _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cancel_outlined, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          const Text('Cancel Order'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this order?',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please let us know why you\'re cancelling:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Cancellation Reasons
            ...List.generate(
              _cancellationReasons.length,
              (index) {
                final reason = _cancellationReasons[index];
                return RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: _selectedReason,
                  // ignore: deprecated_member_use
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          setState(() => _selectedReason = value);
                        },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              },
            ),

            const SizedBox(height: 16),

            // Additional Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Additional notes (optional)',
                hintText: 'Tell us more...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
              enabled: !_isProcessing,
            ),

            const SizedBox(height: 16),

            // Cancellation Policy
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.black87[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If the restaurant has already started preparing your order, you may be charged a cancellation fee.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Keep Order'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _handleCancel,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Cancel Order'),
        ),
      ],
    );
  }
}

/// Helper function to show cancel order dialog
Future<bool> showCancelOrderDialog({
  required BuildContext context,
  required String orderId,
  required Future<void> Function(String reason, String? notes) onCancel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => CancelOrderDialog(
      orderId: orderId,
      onCancel: onCancel,
    ),
  );
  
  return result ?? false;
}
