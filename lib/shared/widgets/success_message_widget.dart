import 'package:flutter/material.dart';

class SuccessMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onContinue;

  const SuccessMessageWidget({
    super.key,
    required this.message,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.black54, size: 60),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          if (onContinue != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        ],
      ),
    );
  }
}
