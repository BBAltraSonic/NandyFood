import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/onboarding/providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    // Show splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check onboarding status first
      final onboardingStatus = await Future.microtask(
        () => ref.read(onboardingCompletedProvider),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => const AsyncValue.data(false),
      );

      // If user hasn't completed onboarding, show onboarding
      final hasCompletedOnboarding = onboardingStatus.value ?? false;
      if (!hasCompletedOnboarding) {
        if (mounted) {
          print('INFO: First-time user, navigating to onboarding');
          context.go('/onboarding');
        }
        return;
      }

      // Check auth status with timeout
      final authState =
          await Future.microtask(() => ref.read(authStateProvider)).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print(
                'WARNING: Auth provider initialization timed out. Using default state.',
              );
              return AuthState(isAuthenticated: false);
            },
          );

      if (mounted) {
        // Always navigate to home - authentication is optional
        // Users can browse as guests
        print(
          'INFO: Navigating to home (authenticated: ${authState.isAuthenticated})',
        );
        context.go('/home');
      }
    } catch (e) {
      print('ERROR checking auth/onboarding status: $e');
      if (mounted) {
        // On error, check if it's first launch by trying onboarding status
        try {
          final onboardingStatus = ref.read(onboardingCompletedProvider);
          final hasCompleted = onboardingStatus.value ?? false;
          if (!hasCompleted) {
            print('INFO: Error occurred, navigating to onboarding');
            context.go('/onboarding');
          } else {
            print('INFO: Error occurred, navigating to home as guest');
            context.go('/home');
          }
        } catch (e) {
          // If everything fails, go to onboarding for safety
          print('INFO: All checks failed, navigating to onboarding');
          context.go('/onboarding');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF6B35), Color(0xFFF7931E), Color(0xFFFFB84D)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'NandyFood',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Delicious food at your doorstep',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
