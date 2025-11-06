import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Customer setup onboarding screen for new customers
class CustomerSetupScreen extends ConsumerStatefulWidget {
  const CustomerSetupScreen({super.key});

  @override
  ConsumerState<CustomerSetupScreen> createState() => _CustomerSetupScreenState();
}

class _CustomerSetupScreenState extends ConsumerState<CustomerSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<CustomerSetupStep> _setupSteps = [
    CustomerSetupStep(
      title: 'Welcome to NandyFood!',
      subtitle: 'Discover amazing food from local restaurants',
      icon: Icons.restaurant_menu,
      backgroundColor: Colors.orange,
    ),
    CustomerSetupStep(
      title: 'Personalize Your Experience',
      subtitle: 'Tell us about your food preferences',
      icon: Icons.favorite,
      backgroundColor: Colors.red,
    ),
    CustomerSetupStep(
      title: 'Set Your Location',
      subtitle: 'Find restaurants near you',
      icon: Icons.location_on,
      backgroundColor: Colors.blue,
    ),
    CustomerSetupStep(
      title: 'Ready to Order!',
      subtitle: 'Your personalized food journey starts now',
      icon: Icons.local_shipping,
      backgroundColor: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with skip button
            _buildHeader(),
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _setupSteps.length,
                itemBuilder: (context, index) {
                  return _buildSetupPage(_setupSteps[index]);
                },
              ),
            ),
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Setup ${_currentPage + 1}/${_setupSteps.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          TextButton(
            onPressed: _skipSetup,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage(CustomerSetupStep step) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: step.backgroundColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              color: step.backgroundColor,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            step.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Step-specific content
          _buildStepContent(_currentPage),
        ],
      ),
    );
  }

  Widget _buildStepContent(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return _buildWelcomeContent();
      case 1:
        return _buildPreferencesContent();
      case 2:
        return _buildLocationContent();
      case 3:
        return _buildReadyContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeContent() {
    return Column(
      children: [
        const Text(
          'Get started in 3 simple steps:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _buildWelcomeStep('1', 'Browse restaurants', Icons.search),
        _buildWelcomeStep('2', 'Place your order', Icons.shopping_cart),
        _buildWelcomeStep('3', 'Track delivery', Icons.local_shipping),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pro tip: Save your favorite restaurants for quicker ordering next time!',
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeStep(String number, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesContent() {
    final preferences = [
      {'name': 'Vegetarian', 'icon': Icons.eco, 'color': Colors.green},
      {'name': 'Vegan', 'icon': Icons.spa, 'color': Colors.lightGreen},
      {'name': 'Gluten-Free', 'icon': Icons.grain, 'color': Colors.amber},
      {'name': 'Halal', 'icon': Icons.restaurant, 'color': Colors.teal},
      {'name': 'Spicy Food', 'icon': Icons.local_fire_department, 'color': Colors.red},
      {'name': 'Quick Bites', 'icon': Icons.timer, 'color': Colors.blue},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your dietary preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: preferences.map((pref) {
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pref['icon'] as IconData,
                    size: 16,
                    color: pref['color'] as Color,
                  ),
                  const SizedBox(width: 6),
                  Text(pref['name'] as String),
                ],
              ),
              onSelected: (selected) {
                // TODO: Handle preference selection
              },
              backgroundColor: Colors.white,
              selectedColor: (pref['color'] as Color).withValues(alpha: 0.2),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Favorite cuisine types',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Italian', 'Chinese', 'Mexican', 'Indian', 'Japanese', 'Thai',
            'American', 'Mediterranean', 'French', 'Korean'
          ].map((cuisine) {
            return FilterChip(
              label: Text(cuisine),
              onSelected: (selected) {
                // TODO: Handle cuisine selection
              },
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationContent() {
    return Column(
      children: [
        const Text(
          'Set your delivery location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Use current location',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (value) {},
                    activeColor: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_location),
          label: const Text('Enter address manually'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your location is only used to find nearby restaurants and calculate delivery times.',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadyContent() {
    return Column(
      children: [
        const Text(
          'You\'re all set! 🎉',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 100,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'What you can do now:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildReadyAction('Browse restaurants near you', Icons.explore),
        _buildReadyAction('Search for your favorite cuisine', Icons.search),
        _buildReadyAction('Place your first order', Icons.shopping_cart),
        _buildReadyAction('Track delivery in real-time', Icons.local_shipping),
        _buildReadyAction('Save restaurants for later', Icons.favorite),
      ],
    );
  }

  Widget _buildReadyAction(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _setupSteps.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? AppTheme.primaryBlack
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Navigation buttons
            Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_currentPage == _setupSteps.length - 1
                        ? 'Get Started'
                        : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _setupSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete setup and navigate to home
      _completeSetup();
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

  void _skipSetup() {
    _completeSetup();
  }

  void _completeSetup() {
    // TODO: Save customer preferences to backend
    context.go(RoutePaths.home);
  }
}

/// Model for customer setup step
class CustomerSetupStep {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;

  const CustomerSetupStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
  });
}