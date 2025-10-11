import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  int _cooldownSeconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider);
    final userEmail = auth.user?.email ?? '';

    Future<void> _resend() async {
      final email = userEmail;
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please sign in to resend verification.'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        return;
      }
      try {
        await ref.read(authStateProvider.notifier).resendVerificationEmail(email: email);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Check your inbox.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _startCooldown();
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Verify your email address',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              userEmail.isNotEmpty
                  ? 'We sent a verification link to $userEmail. Please check your inbox.'
                  : 'We sent a verification link to your email. Please check your inbox.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (auth.isLoading || _cooldownSeconds > 0) ? null : _resend,
              child: Text(
                auth.isLoading
                    ? 'Sending…'
                    : _cooldownSeconds > 0
                        ? 'Resend in ${_cooldownSeconds}s'
                        : 'Resend verification email',
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Back to login'),
            ),
            const Spacer(),
            if (ref.read(authStateProvider.notifier).isEmailVerified)
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Continue'),
              ),
          ],
        ),
      ),
    );
  }
}
