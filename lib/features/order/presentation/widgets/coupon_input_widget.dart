import 'package:flutter/material.dart';

/// Widget for entering and applying coupon codes
class CouponInputWidget extends StatefulWidget {
  final Function(String) onApply;
  final VoidCallback? onRemove;
  final String? appliedCode;
  final bool isLoading;

  const CouponInputWidget({
    Key? key,
    required this.onApply,
    this.onRemove,
    this.appliedCode,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends State<CouponInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.appliedCode != null) {
      _controller.text = widget.appliedCode!;
    }
  }

  @override
  void didUpdateWidget(CouponInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.appliedCode != oldWidget.appliedCode) {
      if (widget.appliedCode != null) {
        _controller.text = widget.appliedCode!;
      } else {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAppliedCode = widget.appliedCode != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Have a coupon code?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !hasAppliedCode && !widget.isLoading,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: hasAppliedCode
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.black87[600],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (hasAppliedCode)
                  OutlinedButton(
                    onPressed: widget.isLoading ? null : () {
                      _controller.clear();
                      widget.onRemove?.call();
                      _focusNode.requestFocus();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black87),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Remove'),
                  )
                else
                  ElevatedButton(
                    onPressed: widget.isLoading || _controller.text.trim().isEmpty
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            widget.onApply(_controller.text.trim().toUpperCase());
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Apply'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
