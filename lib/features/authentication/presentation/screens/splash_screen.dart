import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Simulate checking authentication status
    await Future.delayed(const Duration(seconds: 2));
    
    final authState = ref.read(authStateProvider);
    
    if (mounted) {
      if (authState.isAuthenticated) {
        // Navigate to home screen
        // For now, we'll just show a simple message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is authenticated')),
        );
      } else {
        // Navigate to login screen
        // For now, we'll just show a simple message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not authenticated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fastfood,
              size: 80,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Food Delivery App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}