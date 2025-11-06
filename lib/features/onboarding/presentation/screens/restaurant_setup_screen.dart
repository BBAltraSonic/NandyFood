import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Restaurant setup onboarding screen for new restaurant owners
class RestaurantSetupScreen extends ConsumerStatefulWidget {
  const RestaurantSetupScreen({super.key});

  @override
  ConsumerState<RestaurantSetupScreen> createState() => _RestaurantSetupScreenState();
}

class _RestaurantSetupScreenState extends ConsumerState<RestaurantSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantNameController = TextEditingController();
  final _restaurantTypeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedCuisineType = 'American';
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _cuisineTypes = [
    'American', 'Italian', 'Chinese', 'Japanese', 'Mexican',
    'Indian', 'Thai', 'French', 'Mediterranean', 'Other'
  ];

  final List<SetupStep> _setupSteps = [
    SetupStep(
      title: 'Restaurant Information',
      description: 'Let\'s start with your restaurant details',
      icon: Icons.store,
    ),
    SetupStep(
      title: 'Operating Hours',
      description: 'Set your restaurant\'s availability',
      icon: Icons.schedule,
    ),
    SetupStep(
      title: 'Menu Setup',
      description: 'Add your first menu items',
      icon: Icons.restaurant_menu,
    ),
    SetupStep(
      title: 'Ready to Go!',
      description: 'Your restaurant dashboard is ready',
      icon: Icons.check_circle,
    ),
  ];

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantTypeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Restaurant Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          // Step content
          Expanded(
            child: _buildCurrentStep(),
          ),
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Step indicators
          Row(
            children: _setupSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: index < _currentStep ? () => _goToStep(index) : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? Colors.green
                              : isActive
                                  ? Colors.deepPurple
                                  : Colors.grey.shade300,
                          border: Border.all(
                            color: isActive ? Colors.deepPurple : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : isActive
                                ? Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                      ),
                    ),
                    if (index < _setupSteps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted ? Colors.green : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            _setupSteps[_currentStep].title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _setupSteps[_currentStep].description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildRestaurantInfoStep();
      case 1:
        return _buildOperatingHoursStep();
      case 2:
        return _buildMenuSetupStep();
      case 3:
        return _buildCompletionStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRestaurantInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _restaurantNameController,
              decoration: const InputDecoration(
                labelText: 'Restaurant Name *',
                hintText: 'Enter your restaurant name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter restaurant name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCuisineType,
              decoration: const InputDecoration(
                labelText: 'Cuisine Type *',
                border: OutlineInputBorder(),
              ),
              items: _cuisineTypes.map((cuisine) {
                return DropdownMenuItem(
                  value: cuisine,
                  child: Text(cuisine),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCuisineType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                hintText: 'Restaurant address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter restaurant address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Contact phone number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pro Tip',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure your restaurant name is exactly as customers will search for it. You can always update these details later in your dashboard.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatingHoursStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Set Your Hours',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Customers can only order during your operating hours. You can customize this later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Quick hour selection templates
          _buildHourTemplates(),
          const SizedBox(height: 24),
          // Custom hours (simplified for setup)
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Standard Hours',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: Colors.deepPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDayHours('Monday - Friday', '9:00 AM', '10:00 PM'),
                _buildDayHours('Saturday - Sunday', '10:00 AM', '11:00 PM'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTemplateCard('Breakfast Spot', '6:00 AM - 2:00 PM'),
            _buildTemplateCard('Lunch & Dinner', '11:00 AM - 10:00 PM'),
            _buildTemplateCard('Late Night', '4:00 PM - 2:00 AM'),
            _buildTemplateCard('24/7', 'Always Open'),
          ],
        ),
      ],
    );
  }

  Widget _buildTemplateCard(String title, String hours) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              hours,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayHours(String days, String openTime, String closeTime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            days,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(openTime),
              ),
              const SizedBox(width: 8),
              Text('to'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(closeTime),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSetupStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Add Your First Menu Items',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start with a few popular items. You can add more later in your dashboard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Menu item suggestions
          _buildMenuSuggestions(),
          const SizedBox(height: 24),
          // Quick add buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Custom Item'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Menu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSuggestions() {
    final suggestions = [
      {'name': 'Burger & Fries', 'price': '\$12.99', 'category': 'Main Course'},
      {'name': 'Caesar Salad', 'price': '\$8.99', 'category': 'Appetizer'},
      {'name': 'Soda', 'price': '\$2.99', 'category': 'Beverage'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Popular Items',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...suggestions.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item['category'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  item['price'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {},
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCompletionStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Congratulations! 🎉',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your restaurant dashboard is ready!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade700,
                ),
            ),
          const SizedBox(height: 24),
          Text(
            'Here\'s what you can do next:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildNextStepItem('View and manage orders', Icons.list_alt),
          _buildNextStepItem('Add more menu items', Icons.restaurant_menu),
          _buildNextStepItem('Customize your restaurant profile', Icons.store),
          _buildNextStepItem('Set up payment methods', Icons.payment),
          _buildNextStepItem('Invite staff members', Icons.people),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.deepPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
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
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Previous'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep == 3 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_currentStep == 3 ? 'Go to Dashboard' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Complete setup and navigate to dashboard
      await _completeSetup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save restaurant data to backend
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId != null) {
        // TODO: Save restaurant information
        await Future.delayed(const Duration(seconds: 2)); // Simulate API call

        if (mounted) {
          // Navigate to restaurant dashboard
          context.go(RoutePaths.restaurantDashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Setup?'),
        content: const Text(
          'You can complete your restaurant setup later from your dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Setup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(RoutePaths.restaurantDashboard);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

/// Model for setup step
class SetupStep {
  final String title;
  final String description;
  final IconData icon;

  const SetupStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}