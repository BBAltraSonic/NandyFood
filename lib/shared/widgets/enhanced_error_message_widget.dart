import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class EnhancedErrorMessageWidget extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isPersistent;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double iconSize;
  final bool showSemantics;

  const EnhancedErrorMessageWidget({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.onDismiss,
    this.isPersistent = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize = 48.0,
    this.showSemantics = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: 'Error message${title != null ? ': $title' : ''}. $message',
      focusable: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title!,
                        style: textTheme.titleMedium?.copyWith(
                          color: textColor ?? colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isPersistent && onDismiss != null)
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: textColor ?? colorScheme.onErrorContainer,
                        ),
                        onPressed: onDismiss,
                        tooltip: 'Dismiss error message',
                      ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      icon,
                      color: textColor ?? colorScheme.onErrorContainer,
                      size: iconSize,
                    ),
                  ),
                Expanded(
                  child: Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: textColor ?? colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (onRetry != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onError,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
