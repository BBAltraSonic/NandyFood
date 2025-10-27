import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

import 'package:food_delivery_app/features/onboarding/models/onboarding_page_data.dart';
import 'package:food_delivery_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:food_delivery_app/features/onboarding/widgets/onboarding_page_widget.dart';

/// Main onboarding screen with swipeable pages
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    ref.read(onboardingPageIndexProvider.notifier).state = page;
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go(RoutePaths.home);
    }
  }

  void _nextPage() {
    if (_currentPage < OnboardingPages.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == OnboardingPages.pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // PageView with onboarding pages
          Semantics(
            label: 'Onboarding page \\${_currentPage + 1} of \\${OnboardingPages.pages.length}',
            hint: 'Swipe left or right to navigate onboarding pages',
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: OnboardingPages.pages.length,
              itemBuilder: (context, index) {
                return OnboardingPageWidget(
                  pageData: OnboardingPages.pages[index],
                  onLocationPermissionGranted: isLastPage ? _completeOnboarding : null,
                );
              },
            ),
          ),

          // Top skip button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  button: true,
                  label: 'Skip onboarding',
                  hint: 'Skips onboarding and opens the home screen',
                  child: TextButton(
                    onPressed: _completeOnboarding,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom navigation controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        OnboardingPages.pages.length,
                        (index) => _buildPageIndicator(index),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        if (_currentPage > 0)
                          Semantics(
                            button: true,
                            label: 'Previous onboarding page',
                            hint: 'Navigates to the previous onboarding page',
                            child: IconButton(
                              onPressed: _previousPage,
                              icon: const Icon(Icons.arrow_back),
                              color: Colors.white,
                              iconSize: 32,
                              padding: const EdgeInsets.all(12),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 56),

                        // Next/Get Started button
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Semantics(
                              button: true,
                              label: isLastPage ? 'Get started' : 'Next page',
                              hint: isLastPage
                                  ? 'Completes onboarding and opens the home screen'
                                  : 'Moves to the next onboarding page',
                              child: ElevatedButton(
                                onPressed: _nextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: OnboardingPages.pages[_currentPage]
                                      .backgroundColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  isLastPage ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Placeholder to keep button centered
                        if (_currentPage > 0)
                          const SizedBox(width: 56)
                        else
                          const SizedBox(width: 56),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    final color = OnboardingPages.pages[_currentPage].backgroundColor;

    return Semantics(
      label:
          'Onboarding progress: page \\${index + 1} of \\${OnboardingPages.pages.length}',
      selected: isActive,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 32 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(4),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
