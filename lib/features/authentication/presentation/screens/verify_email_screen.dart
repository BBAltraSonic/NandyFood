import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            content: Text('Verification email sent.'),
            backgroundColor: Colors.green,
          ),
        );
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
              onPressed: auth.isLoading ? null : _resend,
              child: Text(auth.isLoading ? 'Sending…' : 'Resend verification email'),
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
