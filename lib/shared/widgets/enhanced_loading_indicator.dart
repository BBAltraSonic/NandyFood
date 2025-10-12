import 'package:flutter/material.dart';

class EnhancedLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  final bool showSemantics;
  final bool isFullScreen;
  final Widget? child;

  const EnhancedLoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
    this.color,
    this.showSemantics = true,
    this.isFullScreen = false,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? Theme.of(context).primaryColor;

    final loadingContent = Semantics(
      label: 'Loading${message != null ? ': $message' : ''}',
      liveRegion: true,
      focused: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              strokeWidth: 4,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );

    if (isFullScreen) {
      return Scaffold(body: Center(child: loadingContent));
    }

    if (child != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          child!,
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: loadingContent,
          ),
        ],
      );
    }

    return loadingContent;
  }
}
