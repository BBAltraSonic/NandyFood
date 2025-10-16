# 🏪 Restaurant Functionality Implementation Plan
**NandyFood - Complete Restaurant Owner Experience**

**Date Created:** January 2025  
**Last Updated:** January 2025  
**Current Completion:** 55% → Target: 100%  
**Estimated Timeline:** 3.5 weeks  
**Total Effort:** ~86 hours

---

## 📊 Executive Summary

### Current Status Analysis

**What's Working (55% Complete):**
- ✅ Database schema complete (restaurants, menu_items, orders, analytics, staff)
- ✅ Restaurant registration flow (multi-step, polished)
- ✅ Dashboard with real-time stats (today's orders, revenue, ratings)
- ✅ Order management screen (tabbed by status, update orders)
- ✅ Analytics framework (charts, date ranges, metrics)
- ✅ Backend services complete (RestaurantManagementService)

**Critical Gaps (45% Missing):**
- ❌ **No restaurant signup option during authentication** (must switch roles manually)
- ❌ Menu management UI (service exists, no screens)
- ❌ Restaurant profile editing (can't update info after registration)
- ❌ Operating hours editor (stuck with registration settings)
- ❌ Real-time order notifications (missing new order alerts)
- ❌ Staff management (database ready, zero UI)
- ❌ Image uploads (no UI for restaurant/menu photos)
- ⚠️ Settings screens are placeholder navigation only

### Success Criteria
By completion, restaurant owners should be able to:
1. ✅ Register and onboard their restaurant
2. ✅ Add, edit, and manage their complete menu with photos
3. ✅ Receive instant notifications for new orders
4. ✅ Update restaurant info, hours, and delivery settings
5. ✅ Invite and manage staff with role-based permissions
6. ✅ View comprehensive analytics and insights

---

## 🎯 Implementation Priorities

### **PRIORITY 0: Auth Integration - Restaurant Signup (FOUNDATIONAL)** 🔴
**Impact:** CRITICAL - Restaurant owners cannot sign up directly  
**Effort:** 6 hours  
**Timeline:** 1 day  
**Blocking:** YES - Poor user acquisition for restaurants

---

#### **Current Problem**
Users can only sign up as consumers by default. There's no option to register as a restaurant owner during signup. Restaurant owners must:
1. Sign up as consumer
2. Navigate to profile
3. Switch role to restaurant owner
4. Then register restaurant

This creates a **poor onboarding experience** and **low conversion** for restaurant signups.

---

#### **Task 0.1: Add Role Selector to Signup Screen** (2.5 hours)
**File to Modify:** `lib/features/authentication/presentation/screens/signup_screen.dart`

**Changes:**

1. **Add role state variable:**
```dart
class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // NEW: Role selection
  late UserRoleType _selectedRole;
  
  @override
  void initState() {
    super.initState();
    // Check if role was pre-selected via URL parameter
    _selectedRole = widget.preselectedRole ?? UserRoleType.consumer;
  }
  
  // ... existing code ...
}
```

2. **Add role selector widget:**
```dart
Widget _buildRoleSelector() {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 16),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: _buildRoleChip(
            title: 'Order Food',
            subtitle: 'I\'m a customer',
            icon: Icons.shopping_bag_rounded,
            role: UserRoleType.consumer,
            isSelected: _selectedRole == UserRoleType.consumer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleChip(
            title: 'Sell Food',
            subtitle: 'I own a restaurant',
            icon: Icons.store_rounded,
            role: UserRoleType.restaurantOwner,
            isSelected: _selectedRole == UserRoleType.restaurantOwner,
          ),
        ),
      ],
    ),
  );
}

Widget _buildRoleChip({
  required String title,
  required String subtitle,
  required IconData icon,
  required UserRoleType role,
  required bool isSelected,
}) {
  return GestureDetector(
    onTap: () => setState(() => _selectedRole = role),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
```

3. **Insert role selector in build method:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... existing header (logo, title, subtitle) ...
              
              // NEW: Role selector (insert after subtitle, before form fields)
              _buildRoleSelector(),
              
              // Existing form fields (name, email, password, etc.)
              // ... rest of form ...
            ],
          ),
        ),
      ),
    ),
  );
}
```

4. **Update signup handler to use selected role:**
```dart
void _handleSignup() async {
  if (_formKey.currentState!.validate()) {
    try {
      ref.read(authStateProvider.notifier).clearErrorMessage();
      
      // Sign up user with selected role
      await ref.read(authStateProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        initialRole: _selectedRole, // NEW: Pass selected role
      );

      if (!mounted) return;

      // Navigate based on role
      if (_selectedRole == UserRoleType.restaurantOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Let\'s set up your restaurant.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/restaurant/register?fromSignup=true');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
```

5. **Add constructor parameter for pre-selected role:**
```dart
class SignupScreen extends ConsumerStatefulWidget {
  final UserRoleType? preselectedRole;
  
  const SignupScreen({
    super.key,
    this.preselectedRole,
  });

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}
```

**Acceptance Criteria:**
- [x] Role selector displays two options: Consumer and Restaurant Owner
- [x] Selected role is highlighted visually
- [x] Tapping changes selection
- [x] Signup creates account with selected role
- [x] Restaurant owners redirect to registration
- [x] Consumers redirect to home

---

#### **Task 0.2: Update AuthProvider** (1.5 hours)
**File to Modify:** `lib/core/providers/auth_provider.dart`

**Add initialRole parameter to signUp method:**

```dart
Future<void> signUp({
  required String email,
  required String password,
  required String fullName,
  UserRoleType initialRole = UserRoleType.consumer, // NEW parameter
}) async {
  try {
    // Create auth user
    final response = await _authService.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    
    final userId = response.user!.id;
    
    // Create user_profile
    await _createUserProfile(userId, email, fullName);
    
    // Assign specified role (not just default consumer)
    await _roleService.assignRole(
      userId, 
      initialRole, 
      isPrimary: true,
    );
    
    // Update state with user and role
    state = state.copyWith(
      user: response.user, 
      isAuthenticated: true,
      primaryRole: UserRole(
        userId: userId,
        role: initialRole,
        isPrimary: true,
      ),
    );
  } catch (e) {
    state = state.copyWith(errorMessage: e.toString());
    rethrow;
  }
}
```

**Verify RoleService.assignRole method exists:**
```dart
// Should already exist in lib/core/services/role_service.dart
Future<void> assignRole(
  String userId,
  UserRoleType roleType, {
  bool isPrimary = false,
}) async {
  await _supabase.from('user_roles').insert({
    'user_id': userId,
    'role': roleType.toString().split('.').last,
    'is_primary': isPrimary,
  });
}
```

**Acceptance Criteria:**
- [x] AuthProvider accepts initialRole parameter
- [x] User profile created successfully
- [x] Correct role assigned in user_roles table
- [x] Primary role set correctly
- [x] State updated with role information

---

#### **Task 0.3: Add Restaurant CTA on Login Screen** (1 hour)
**File to Modify:** `lib/features/authentication/presentation/screens/login_screen.dart`

**Add after existing "Sign up" link:**

```dart
// After "Don't have an account? Sign up" section:

const SizedBox(height: 24),
const Divider(),
const SizedBox(height: 24),

// Restaurant owner CTA
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.orange.shade50,
        Colors.deepOrange.shade50,
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.orange.shade200),
  ),
  child: Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_rounded, color: Colors.orange.shade700, size: 28),
          const SizedBox(width: 8),
          Text(
            'Own a Restaurant?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Join NandyFood and grow your business with our platform',
        style: TextStyle(
          fontSize: 13,
          color: Colors.orange.shade700,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.go('/auth/signup?role=restaurant'),
          icon: const Icon(Icons.restaurant_menu),
          label: const Text('Register Your Restaurant'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ],
  ),
),
```

**Acceptance Criteria:**
- [x] CTA banner displays on login screen
- [x] Banner is visually distinct and attractive
- [x] Tapping button navigates to signup with restaurant pre-selected
- [x] Works on all screen sizes

---

#### **Task 0.4: Update Router for Pre-selected Role** (30 min)
**File to Modify:** `lib/main.dart`

**Update signup route to accept role parameter:**

```dart
GoRoute(
  path: '/auth/signup',
  builder: (context, state) {
    // Check for role query parameter
    final roleParam = state.uri.queryParameters['role'];
    final preselectedRole = roleParam == 'restaurant' 
      ? UserRoleType.restaurantOwner 
      : null; // null = default to consumer
    
    return SignupScreen(preselectedRole: preselectedRole);
  },
),
```

**Update restaurant registration route:**

```dart
GoRoute(
  path: '/restaurant/register',
  builder: (context, state) {
    final fromSignup = state.uri.queryParameters['fromSignup'] == 'true';
    return RestaurantRegistrationScreen(fromSignup: fromSignup);
  },
),
```

**Acceptance Criteria:**
- [x] `/auth/signup?role=restaurant` pre-selects restaurant role
- [x] `/auth/signup` defaults to consumer role
- [x] `/restaurant/register?fromSignup=true` shows welcome banner
- [x] Navigation works correctly

---

#### **Task 0.5: Enhance Restaurant Registration Welcome** (30 min)
**File to Modify:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_registration_screen.dart`

**Add constructor parameter:**
```dart
class RestaurantRegistrationScreen extends ConsumerStatefulWidget {
  final bool fromSignup;
  
  const RestaurantRegistrationScreen({
    super.key,
    this.fromSignup = false,
  });

  @override
  ConsumerState<RestaurantRegistrationScreen> createState() =>
      _RestaurantRegistrationScreenState();
}
```

**Add welcome banner:**
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Register Your Restaurant'),
      // Don't allow back navigation if coming from signup
      automaticallyImplyLeading: !widget.fromSignup,
    ),
    body: Column(
      children: [
        // NEW: Welcome banner for new signups
        if (widget.fromSignup) _buildWelcomeBanner(),
        
        // Existing content
        _buildProgressIndicator(),
        Expanded(child: PageView(...)),
        _buildNavigationButtons(),
      ],
    ),
  );
}

Widget _buildWelcomeBanner() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green.shade50, Colors.blue.shade50],
      ),
    ),
    child: Column(
      children: [
        Icon(Icons.celebration, color: Colors.green.shade700, size: 32),
        const SizedBox(height: 8),
        Text(
          'Welcome to NandyFood! 🎉',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Let\'s get your restaurant set up in just 5 easy steps',
          style: TextStyle(color: Colors.green.shade700),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
```

**Acceptance Criteria:**
- [x] Welcome banner shows when coming from signup
- [x] Banner is encouraging and friendly
- [x] Back button disabled when from signup (prevent broken flow)
- [x] Banner doesn't show for existing users editing

---

#### **Task 0.6: Testing & Bug Fixes** (1 hour)

**Test Scenarios:**

1. **Restaurant Owner Signup Flow:**
   - [ ] Visit login page
   - [ ] Click "Register Your Restaurant"
   - [ ] Verify signup page loads with restaurant role pre-selected
   - [ ] Fill form and submit
   - [ ] Verify redirects to restaurant registration
   - [ ] Verify welcome banner displays
   - [ ] Complete registration
   - [ ] Verify restaurant created
   - [ ] Verify redirects to dashboard

2. **Consumer Signup Flow:**
   - [ ] Visit signup page directly
   - [ ] Verify consumer role is selected by default
   - [ ] Fill form and submit
   - [ ] Verify redirects to home screen
   - [ ] No restaurant registration

3. **Role Toggle:**
   - [ ] Visit signup page
   - [ ] Toggle from consumer to restaurant
   - [ ] Sign up
   - [ ] Verify restaurant flow triggered

4. **Edge Cases:**
   - [ ] Sign up with restaurant role, close app during registration
   - [ ] Log back in, verify can access dashboard
   - [ ] Verify can resume/complete registration
   - [ ] Test with different screen sizes
   - [ ] Test dark mode

**Acceptance Criteria:**
- [x] All test scenarios pass
- [x] No crashes or errors
- [x] Smooth transitions between screens
- [x] Proper error handling
- [x] Clear user feedback

---

### **PRIORITY 1: Menu Management (CRITICAL)** 🔴
**Impact:** HIGH - Restaurant owners cannot manage their menu  
**Effort:** 16-20 hours  
**Timeline:** 3-4 days  
**Blocking:** YES - Restaurants can't operate without menu control

---

#### **Task 1.1: Menu List View** (6 hours)
**File to Replace:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_menu_screen.dart`

**Current State:** Placeholder with "Coming soon" message

**Implementation:**

```dart
class RestaurantMenuScreen extends ConsumerStatefulWidget {
  const RestaurantMenuScreen({super.key});

  @override
  ConsumerState<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends ConsumerState<RestaurantMenuScreen> {
  String? _restaurantId;
  List<MenuItem> _menuItems = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  
  final _restaurantService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    _loadRestaurantAndMenu();
  }

  Future<void> _loadRestaurantAndMenu() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);
      if (restaurants.isEmpty) return;

      setState(() => _restaurantId = restaurants.first);
      await _loadMenu();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _loadMenu() async {
    if (_restaurantId == null) return;

    setState(() => _isLoading = true);
    try {
      final items = await _restaurantService.getMenuItems(_restaurantId!);
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'All') return _menuItems;
    return _menuItems.where((item) => item.category == _selectedCategory).toList();
  }

  List<String> get _categories {
    final cats = _menuItems.map((item) => item.category).toSet().toList();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _restaurantId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'bulk') _enterBulkMode();
              if (value == 'export') _exportMenu();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'bulk', child: Text('Bulk Edit')),
              const PopupMenuItem(value: 'export', child: Text('Export Menu')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          _buildCategoryFilter(),
          
          // Menu items list
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadMenu,
                    child: ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildMenuItemCard(_filteredItems[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddItem(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(MenuItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToEditItem(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: Icon(Icons.restaurant, color: Colors.grey.shade600),
                      ),
              ),
              const SizedBox(width: 12),
              
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'R ${item.price.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isAvailable ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Availability toggle
              Switch(
                value: item.isAvailable,
                onChanged: (value) => _toggleAvailability(item, value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No menu items yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first menu item to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddItem(),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(MenuItem item, bool isAvailable) async {
    try {
      await _restaurantService.updateMenuItem(item.id, {
        'is_available': isAvailable,
      });
      
      setState(() {
        final index = _menuItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _menuItems[index] = item.copyWith(isAvailable: isAvailable);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAvailable ? 'Item marked as available' : 'Item marked as unavailable'),
        ),
      );
    } catch (e) {
      _showError('Failed to update availability');
    }
  }

  void _navigateToAddItem() {
    context.push('/restaurant/menu/add', extra: _restaurantId);
  }

  void _navigateToEditItem(MenuItem item) {
    context.push('/restaurant/menu/edit/${item.id}', extra: item);
  }

  void _showSearch() {
    // TODO: Implement search dialog
  }

  void _enterBulkMode() {
    // TODO: Implement bulk edit mode
  }

  void _exportMenu() {
    // TODO: Implement CSV export
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**Acceptance Criteria:**
- [x] Displays all menu items grouped by category
- [x] Shows item image, name, price, availability status
- [x] Category filter chips working
- [x] Quick toggle for availability
- [x] Tap item to edit
- [x] FAB to add new item
- [x] Empty state for new restaurants
- [x] Pull-to-refresh

---

#### **Task 1.2: Add/Edit Menu Item Screen** (8 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/screens/add_edit_menu_item_screen.dart`

**Multi-Step Form Structure:**
1. **Step 1: Basic Info** - Name, description, category
2. **Step 2: Pricing** - Price, original price, prep time
3. **Step 3: Details** - Dietary tags, allergens, spice level
4. **Step 4: Customizations** - Build customization options
5. **Step 5: Media** - Upload item photo
6. **Step 6: Review** - Final review and save

**Key Features:**
```dart
- Image picker with compression (max 1MB)
- Customization builder:
  * Add option groups (Size, Toppings, etc.)
  * Set prices per option
  * Mark options as required/optional
  * Save as JSONB structure
- Dietary tags multi-select (Vegan, Gluten-Free, Halal, etc.)
- Allergen warnings
- Form validation at each step
- Save progress (draft mode)
- Preview card
```

**Customization JSON Structure:**
```json
[
  {
    "id": "size",
    "name": "Size",
    "required": true,
    "max_selections": 1,
    "options": [
      {"id": "small", "name": "Small", "price": 0},
      {"id": "large", "name": "Large", "price": 15.00}
    ]
  },
  {
    "id": "toppings",
    "name": "Extra Toppings",
    "required": false,
    "max_selections": 5,
    "options": [
      {"id": "cheese", "name": "Extra Cheese", "price": 5.00},
      {"id": "bacon", "name": "Bacon", "price": 8.00}
    ]
  }
]
```

**Acceptance Criteria:**
- [x] All form fields functional with validation
- [x] Image upload to Supabase Storage
- [x] Customization builder with add/remove options
- [x] Preview shows item as customers see it
- [x] Save creates/updates menu_item record
- [x] Navigation back to menu list on success

---

#### **Task 1.3: Menu Item Analytics** (3 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/widgets/menu_item_performance_card.dart`

**Display Metrics:**
- Times ordered (today, this week, this month)
- Revenue generated
- Average rating (from order reviews)
- View-to-order conversion rate
- Popular customization choices

**Integration:**
- Add "View Analytics" button to each menu item
- Show top 5 items on main dashboard
- Highlight underperforming items with suggestions

---

#### **Task 1.4: Bulk Operations** (3 hours)

**Features:**
- Long-press item to enter selection mode
- Multi-select with checkboxes
- Bulk actions:
  * Enable/disable availability
  * Change category
  * Delete multiple items
  * Adjust prices by percentage
- Bottom action bar in selection mode
- Confirmation dialogs for destructive actions

---

### **PRIORITY 2: Restaurant Settings (HIGH)** 🟠
**Impact:** MEDIUM - Can't update restaurant info after registration  
**Effort:** 12-16 hours  
**Timeline:** 2-3 days

---

#### **Task 2.1: Restaurant Profile Editor** (5 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_info_screen.dart`

**Editable Fields:**
- Basic Info: Name, description, phone, email, website
- Address: Street, city, state, postal code
- Location: Latitude/longitude with map picker
- Media: Logo URL, cover image URL, gallery images
- Cuisine Types: Multi-select (Italian, Chinese, etc.)
- Dietary Options: Vegetarian, Vegan, Gluten-Free, etc.
- Features: Outdoor seating, WiFi, Parking, etc.

**Implementation:**
```dart
class RestaurantInfoScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Restaurant Info')),
      body: Form(
        child: ListView(
          children: [
            // Logo upload
            _buildLogoUploader(),
            
            // Cover image upload
            _buildCoverImageUploader(),
            
            // Basic info fields
            TextFormField(label: 'Restaurant Name'),
            TextFormField(label: 'Description', maxLines: 4),
            TextFormField(label: 'Phone'),
            TextFormField(label: 'Email'),
            
            // Address with map picker
            _buildAddressSection(),
            
            // Cuisine types
            _buildCuisineSelector(),
            
            // Save button
            ElevatedButton(onPressed: _saveChanges),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveChanges() async {
    await _restaurantService.updateRestaurant(_restaurantId, {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'phone_number': _phoneController.text,
      'email': _emailController.text,
      'address_line1': _addressController.text,
      'city': _cityController.text,
      'cuisine_type': _selectedCuisineTypes,
      'logo_url': _logoUrl,
      'cover_image_url': _coverImageUrl,
    });
  }
}
```

**Image Upload Integration:**
- Create Supabase Storage bucket: `restaurant-images`
- Upload path: `{restaurantId}/logo.jpg`, `{restaurantId}/cover.jpg`
- Compress images before upload (max 2MB)

**Acceptance Criteria:**
- [x] All fields pre-filled with current data
- [x] Logo and cover images upload successfully
- [x] Map picker updates lat/long
- [x] Changes save to database
- [x] Changes reflect immediately in customer app

---

#### **Task 2.2: Operating Hours Editor** (4 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/screens/operating_hours_screen.dart`

**UI Design:**
```dart
// For each day of the week:
- Toggle: Open / Closed
- TimePicker: Opening time
- TimePicker: Closing time
- Optional: Add second shift (split hours)

// Helper buttons:
- "Copy to All Days"
- "Copy Weekdays"
- "Copy Weekends"
- "Set Holiday Hours"
```

**JSON Structure for opening_hours:**
```json
{
  "monday": {"open": "09:00", "close": "22:00"},
  "tuesday": {"open": "09:00", "close": "22:00"},
  "wednesday": {"open": "09:00", "close": "22:00"},
  "thursday": {"open": "09:00", "close": "22:00"},
  "friday": {"open": "09:00", "close": "23:00"},
  "saturday": {"open": "09:00", "close": "23:00"},
  "sunday": {"open": "10:00", "close": "21:00"}
}
```

**Acceptance Criteria:**
- [x] Day-by-day schedule editor
- [x] Time pickers with 15-min increments
- [x] Support for closed days
- [x] Split shift support (lunch + dinner)
- [x] Bulk copy operations
- [x] Saves to restaurant.opening_hours JSONB
- [x] Validates times (open < close)

---

#### **Task 2.3: Delivery Settings** (3 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/screens/delivery_settings_screen.dart`

**Settings:**
- Delivery Radius (km) - Slider with live map preview
- Delivery Fee Structure:
  * Fixed fee
  * Distance-based (per km)
  * Free delivery threshold
- Minimum Order Amount (R)
- Estimated Delivery Time (minutes)

**Implementation:**
```dart
class DeliverySettingsScreen extends StatefulWidget {
  double _deliveryRadius = 5.0;
  double _deliveryFee = 20.0;
  double _minimumOrder = 50.0;
  int _estimatedTime = 30;
  
  Widget _buildRadiusSlider() {
    return Column(
      children: [
        Text('Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km'),
        Slider(
          value: _deliveryRadius,
          min: 1,
          max: 20,
          divisions: 19,
          onChanged: (value) => setState(() => _deliveryRadius = value),
        ),
        // Map showing radius circle
        _buildRadiusMap(),
      ],
    );
  }
  
  Future<void> _save() async {
    await _restaurantService.updateRestaurant(_restaurantId, {
      'delivery_radius': _deliveryRadius,
      'delivery_fee': _deliveryFee,
      'minimum_order_amount': _minimumOrder,
      'estimated_delivery_time': _estimatedTime,
    });
  }
}
```

**Map Preview:**
- Show restaurant location as center point
- Draw circle with radius = delivery_radius
- Show affected areas/neighborhoods

**Acceptance Criteria:**
- [x] Slider updates radius in real-time
- [x] Map circle visualization
- [x] All settings save correctly
- [x] Fee calculator preview
- [x] Changes reflect in customer app

---

#### **Task 2.4: Quick Settings Widget** (2 hours)
**Enhancement to:** `RestaurantDashboardScreen`

**Add at top of dashboard:**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Currently Accepting Orders'),
            Switch(
              value: _restaurant.isAcceptingOrders,
              onChanged: _toggleAcceptingOrders,
            ),
          ],
        ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusChip(_getOperatingStatus()),
            TextButton(
              onPressed: () => context.push('/restaurant/settings'),
              child: Text('Manage Settings'),
            ),
          ],
        ),
      ],
    ),
  ),
)
```

**Operating Status Logic:**
```dart
String _getOperatingStatus() {
  if (!_restaurant.isActive) return 'Inactive';
  if (!_restaurant.isAcceptingOrders) return 'Paused';
  
  final now = DateTime.now();
  final dayName = _getDayName(now.weekday);
  final hours = _restaurant.openingHours[dayName];
  
  if (hours == null) return 'Closed Today';
  
  final currentTime = TimeOfDay.now();
  final open = _parseTime(hours['open']);
  final close = _parseTime(hours['close']);
  
  if (_isTimeBetween(currentTime, open, close)) {
    return 'Open Now';
  } else {
    return 'Closed Now';
  }
}
```

---

### **PRIORITY 3: Real-time Order Notifications (HIGH)** 🟠
**Impact:** HIGH - Restaurant owners miss orders without alerts  
**Effort:** 8-12 hours  
**Timeline:** 2 days

---

#### **Task 3.1: Supabase Realtime Integration** (4 hours)
**File to Modify:** `lib/features/restaurant_dashboard/providers/restaurant_dashboard_provider.dart`

**Implementation:**
```dart
class RestaurantDashboardNotifier extends StateNotifier<RestaurantDashboardState> {
  StreamSubscription<List<Map<String, dynamic>>>? _ordersSubscription;
  final Set<String> _seenOrderIds = {};
  final OrderAlertService _alertService = OrderAlertService();

  Future<void> startWatchingOrders(String restaurantId) async {
    // Cancel existing subscription
    _ordersSubscription?.cancel();
    
    // Subscribe to new orders
    _ordersSubscription = supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false)
      .listen((orders) {
        _handleOrdersUpdate(orders);
      });
  }

  void _handleOrdersUpdate(List<Map<String, dynamic>> orders) {
    final newOrders = orders.where((order) {
      final orderId = order['id'] as String;
      final status = order['status'] as String;
      final isNew = status == 'placed' && !_seenOrderIds.contains(orderId);
      
      if (isNew) {
        _seenOrderIds.add(orderId);
      }
      
      return isNew;
    }).toList();

    if (newOrders.isNotEmpty) {
      // Trigger alerts
      _alertService.notifyNewOrders(newOrders.length);
      
      // Update state
      state = state.copyWith(
        pendingOrdersCount: state.pendingOrdersCount + newOrders.length,
        hasNewOrders: true,
      );
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
```

**Supabase Setup:**
- Enable realtime for `orders` table
- RLS policy: Restaurant owners can watch their orders
- Test with multiple concurrent connections

**Acceptance Criteria:**
- [x] Subscription starts when dashboard opens
- [x] New orders detected in real-time
- [x] Subscription cleans up on dispose
- [x] Reconnects after network loss
- [x] No duplicate alerts

---

#### **Task 3.2: Audio/Visual Alerts** (3 hours)
**File to Create:** `lib/features/restaurant_dashboard/services/order_alert_service.dart`

**Features:**
- Play sound on new order
- Vibration pattern
- Show badge on dashboard
- In-app banner notification

**Implementation:**
```dart
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class OrderAlertService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> notifyNewOrders(int count) async {
    // Play sound
    await _playNewOrderSound();
    
    // Vibrate
    await _vibratePattern();
    
    // Show local notification (if app in foreground)
    await _showLocalNotification(count);
  }

  Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/new_order.mp3'));
    } catch (e) {
      print('Failed to play sound: $e');
    }
  }

  Future<void> _vibratePattern() async {
    if (await Vibration.hasVibrator() ?? false) {
      // Pattern: short-pause-short-pause-long
      Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 500]);
    }
  }

  Future<void> _showLocalNotification(int count) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'restaurant_orders',
      'Restaurant Orders',
      channelDescription: 'Notifications for new restaurant orders',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('new_order'),
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      0,
      'New Order${count > 1 ? 's' : ''}!',
      'You have $count new order${count > 1 ? 's' : ''} waiting',
      platformDetails,
    );
  }
}
```

**Assets Needed:**
- `assets/sounds/new_order.mp3` (pleasant notification sound)
- Update `pubspec.yaml` to include assets
- Add packages: `audioplayers`, `vibration`

**Acceptance Criteria:**
- [x] Sound plays when new order arrives
- [x] Vibration pattern distinct and noticeable
- [x] Notification shows order count
- [x] Works in foreground and background
- [x] Respects device silent mode

---

#### **Task 3.3: Push Notifications (Background)** (5 hours)

**Backend: Edge Function**
**File to Create:** `supabase/functions/notify-restaurant-new-order/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { orderId } = await req.json()
  
  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )
  
  // Get order details
  const { data: order } = await supabaseAdmin
    .from('orders')
    .select('restaurant_id')
    .eq('id', orderId)
    .single()
  
  // Get restaurant owner FCM tokens
  const { data: owners } = await supabaseAdmin
    .from('restaurant_owners')
    .select('user_id')
    .eq('restaurant_id', order.restaurant_id)
  
  const userIds = owners.map(o => o.user_id)
  
  const { data: profiles } = await supabaseAdmin
    .from('profiles')
    .select('fcm_token')
    .in('id', userIds)
    .not('fcm_token', 'is', null)
  
  // Send FCM notification to each owner
  for (const profile of profiles) {
    await sendFCM(profile.fcm_token, {
      title: '🔔 New Order!',
      body: 'You have a new order waiting',
      data: {
        orderId,
        route: '/restaurant/orders',
      },
    })
  }
  
  return new Response('OK', { status: 200 })
})
```

**Database Trigger:**
```sql
CREATE OR REPLACE FUNCTION notify_restaurant_new_order()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/notify-restaurant-new-order',
    body := json_build_object('orderId', NEW.id)::jsonb
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_order_placed
AFTER INSERT ON orders
FOR EACH ROW
WHEN (NEW.status = 'placed')
EXECUTE FUNCTION notify_restaurant_new_order();
```

**Frontend:**
- Store FCM token in profiles on restaurant registration
- Handle notification tap → navigate to orders screen
- Background message handler

**Acceptance Criteria:**
- [x] Push notification sent when order placed
- [x] Notification arrives even when app closed
- [x] Tap notification opens orders screen
- [x] Works on both Android and iOS

---

### **PRIORITY 4: Staff Management (MEDIUM)** 🟡
**Impact:** MEDIUM - Multi-user restaurant management  
**Effort:** 12-16 hours  
**Timeline:** 2-3 days

---

#### **Task 4.1: Staff List Screen** (4 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/screens/staff_management_screen.dart`

**Features:**
- List all staff members with roles
- Status badges (Active, On Leave, Suspended)
- Search by name/email
- Filter by role
- Add staff FAB
- Tap staff to edit

**Implementation:**
```dart
class StaffManagementScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(staffProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showSearch,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: staffState.staff.length,
        itemBuilder: (context, index) {
          final staff = staffState.staff[index];
          return _buildStaffCard(staff);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/restaurant/staff/add'),
        icon: Icon(Icons.person_add),
        label: Text('Invite Staff'),
      ),
    );
  }
  
  Widget _buildStaffCard(RestaurantStaff staff) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: staff.avatarUrl != null 
            ? NetworkImage(staff.avatarUrl!) 
            : null,
          child: staff.avatarUrl == null ? Icon(Icons.person) : null,
        ),
        title: Text(staff.fullName),
        subtitle: Text(staff.role),
        trailing: _buildStatusChip(staff.status),
        onTap: () => _editStaff(staff),
      ),
    );
  }
}
```

**Acceptance Criteria:**
- [x] Displays all staff members
- [x] Shows role and status
- [x] Search functionality
- [x] Empty state for no staff
- [x] Tap to edit staff

---

#### **Task 4.2: Add/Edit Staff** (5 hours)
**File to Create:** `lib/features/restaurant_dashboard/presentation/screens/add_edit_staff_screen.dart`

**Form Fields:**
- Email (lookup or invite)
- Role: Manager, Chef, Cashier, Server, Delivery Coordinator
- Permissions checkboxes:
  * View menu / Update menu
  * View orders / Update orders
  * View analytics
  * Manage staff (owner only)
  * Manage settings
- Employment Type: Full-time, Part-time, Contractor
- Hired Date
- Hourly Rate (optional)

**Implementation:**
```dart
class AddEditStaffScreen extends ConsumerStatefulWidget {
  Future<void> _inviteStaff() async {
    // Check if user exists
    final { data: existingUser } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', _emailController.text)
      .maybeSingle();
    
    String userId;
    
    if (existingUser == null) {
      // Send invitation email
      await _sendInvitationEmail(_emailController.text);
      
      // Create pending user record
      userId = await _createPendingUser(_emailController.text);
    } else {
      userId = existingUser['id'];
    }
    
    // Create staff record
    await supabase.from('restaurant_staff').insert({
      'user_id': userId,
      'restaurant_id': widget.restaurantId,
      'role': _selectedRole,
      'permissions': _getPermissions(),
      'employment_type': _employmentType,
      'hired_date': _hiredDate.toIso8601String(),
    });
    
    // Assign user role
    await supabase.from('user_roles').insert({
      'user_id': userId,
      'role': 'restaurant_staff',
    });
  }
  
  Map<String, bool> _getPermissions() {
    return {
      'view_menu': _permissions['view_menu'] ?? false,
      'update_menu': _permissions['update_menu'] ?? false,
      'view_orders': _permissions['view_orders'] ?? false,
      'update_orders': _permissions['update_orders'] ?? false,
      'view_analytics': _permissions['view_analytics'] ?? false,
      'manage_staff': _permissions['manage_staff'] ?? false,
      'manage_settings': _permissions['manage_settings'] ?? false,
    };
  }
}
```

**Email Invitation:**
- Use Supabase Auth to send invitation
- Custom email template with restaurant name
- Link to download app + auto-fill email

**Acceptance Criteria:**
- [x] Email lookup works
- [x] Invitation emails sent for new users
- [x] Role selection functional
- [x] Permissions save correctly
- [x] Staff record created
- [x] User role assigned

---

#### **Task 4.3: Permissions Enforcement** (3 hours)

**Implement RLS Policies:**
```sql
-- Staff can only view/update menu if they have permission
CREATE POLICY "Staff with menu permission can view"
ON menu_items FOR SELECT
USING (
  restaurant_id IN (
    SELECT restaurant_id FROM restaurant_staff
    WHERE user_id = auth.uid()
    AND (permissions->>'view_menu')::boolean = true
  )
);

-- Similar policies for orders, analytics, etc.
```

**Frontend Checks:**
```dart
class PermissionService {
  Future<bool> hasPermission(String permission) async {
    final { data } = await supabase
      .from('restaurant_staff')
      .select('permissions')
      .eq('user_id', supabase.auth.currentUser!.id)
      .single();
    
    return data['permissions'][permission] == true;
  }
}

// Use in UI:
if (await PermissionService().hasPermission('update_menu')) {
  // Show edit button
}
```

**Acceptance Criteria:**
- [x] RLS policies enforce permissions
- [x] UI hides unauthorized actions
- [x] API calls fail gracefully
- [x] Permission checks performant

---

### **PRIORITY 5: Enhanced Analytics (LOW)** 🟢
**Impact:** LOW - Nice-to-have insights  
**Effort:** 8-12 hours  
**Timeline:** 1-2 days

*(See detailed tasks in full plan document)*

---

## 📅 Implementation Timeline

### **Week 1: Menu Management (Priority 1)**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon | Task 1.1: Menu list view | 6 |
| Tue-Wed | Task 1.2: Add/Edit menu item | 8 |
| Thu | Task 1.3: Analytics integration | 3 |
| Fri | Task 1.4: Bulk operations + testing | 3 |
| **Total** | **Menu management complete** | **20h** |

### **Week 2: Settings & Notifications (Priorities 2-3)**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon | Task 2.1: Restaurant profile editor | 5 |
| Tue | Tasks 2.2-2.3: Hours & delivery settings | 7 |
| Wed | Tasks 3.1-3.2: Realtime + alerts | 7 |
| Thu | Task 3.3: Push notifications | 5 |
| Fri | Integration testing & bug fixes | 6 |
| **Total** | **Settings & notifications complete** | **30h** |

### **Week 3: Staff Management & Polish (Priority 4)**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon-Tue | Priority 4: Staff management | 12 |
| Wed | Priority 5: Enhanced analytics | 8 |
| Thu-Fri | Full integration testing, bug fixes, polish | 10 |
| **Total** | **All priorities complete** | **30h** |

**Grand Total:** 80 hours (~3 weeks)

---

## ✅ Definition of Done

### **Functional Requirements**
- [x] Restaurant owners can sign up directly from auth flow
- [x] Role selector on signup page works correctly
- [x] Restaurant CTA displays on login page
- [x] All CRUD operations work for menu items
- [x] Restaurant info can be updated post-registration
- [x] Operating hours editable with validation
- [x] Real-time order notifications functional
- [x] Staff can be invited and managed
- [x] Permissions enforced at DB and UI level
- [x] All images upload successfully
- [x] Error handling for all edge cases

### **Quality Requirements**
- [x] Zero lint errors
- [x] All new code has unit tests
- [x] Integration tests for critical flows
- [x] No memory leaks (subscriptions cleaned up)
- [x] Responsive UI on all screen sizes

### **User Experience Requirements**
- [x] Loading states for all async operations
- [x] User-friendly error messages
- [x] Smooth animations
- [x] Dark mode support
- [x] Accessibility labels

### **Performance Requirements**
- [x] Menu list loads in <2 seconds
- [x] Image uploads complete in <10 seconds
- [x] Realtime updates arrive within 3 seconds
- [x] No UI jank (maintain 60 FPS)

---

## 🚀 Rollout Strategy

1. **Internal Testing (Days 1-3):** Dev team tests with test restaurant
2. **Beta Testing (Days 4-7):** 5 real restaurant partners test
3. **Feedback Iteration (Days 8-10):** Fix critical issues
4. **Soft Launch (Week 4):** Enable for 50% of restaurants
5. **Full Launch (Week 5):** Enable for all restaurants with announcement

---

## 📚 Documentation Requirements

### **For Restaurant Owners**
1. **Getting Started Guide:**
   - How to add your first menu item
   - How to update operating hours
   - How to manage orders

2. **Video Tutorials:**
   - Menu management walkthrough
   - Staff invitation process
   - Understanding analytics

### **For Developers**
1. **Technical Docs:**
   - Menu management API reference
   - Realtime subscription patterns
   - Image upload guidelines
   - Permission system architecture

2. **Testing Guides:**
   - How to test realtime features
   - How to simulate orders
   - How to test notifications

---

## 💰 Cost Impact

- **Supabase Storage:** ~5GB for restaurant/menu images ≈ **$0.10/month**
- **Realtime Connections:** Included in current plan
- **Edge Functions:** Notification triggers within free tier (500K/month)
- **Firebase:** FCM is free
- **Total Additional Cost:** **~$0.10/month**

---

## 🎯 Success Metrics

**Post-Implementation Tracking:**

1. **Adoption Rate:** 80% of restaurants complete menu setup within 7 days
2. **Engagement:** Average restaurant owner logs in 5+ times per week
3. **Order Response Time:** <5 minutes from order placed to accepted
4. **Staff Utilization:** 30% of restaurants invite at least 1 staff member
5. **Error Rate:** <1% of API calls fail
6. **Customer Satisfaction:** Restaurant ratings improve by 0.2+ stars

---

## 📱 Testing Checklist

### **Auth Integration (Priority 0)**
- [ ] Login page displays restaurant owner CTA
- [ ] Clicking CTA navigates to signup with role pre-selected
- [ ] Signup page shows role selector
- [ ] Consumer role selected by default
- [ ] Can toggle between roles
- [ ] Restaurant role signup redirects to registration
- [ ] Consumer signup redirects to home
- [ ] Welcome banner shows on registration from signup
- [ ] Back button disabled when from signup
- [ ] Role persists in database correctly

### **Menu Management**
- [ ] Add new menu item with all fields
- [ ] Upload item image (JPG, PNG)
- [ ] Edit existing item
- [ ] Toggle availability on/off
- [ ] Delete item
- [ ] Create customization options
- [ ] Search menu items
- [ ] Filter by category
- [ ] Bulk enable/disable
- [ ] Export menu to CSV

### **Restaurant Settings**
- [ ] Update restaurant name
- [ ] Upload new logo
- [ ] Update operating hours
- [ ] Change delivery radius
- [ ] Update delivery fee
- [ ] Quick toggle accepting orders
- [ ] Changes reflect in customer app

### **Order Notifications**
- [ ] New order appears in realtime
- [ ] Sound plays on new order
- [ ] Vibration pattern triggers
- [ ] Push notification received (app closed)
- [ ] Tap notification opens orders screen
- [ ] Subscription reconnects after network loss

### **Staff Management**
- [ ] Invite new staff member
- [ ] Email invitation sent
- [ ] Assign role and permissions
- [ ] Edit staff member
- [ ] Remove staff member
- [ ] Permissions enforced in UI
- [ ] RLS policies block unauthorized access

---

## 🔧 Required Packages

**Add to pubspec.yaml:**
```yaml
dependencies:
  audioplayers: ^5.2.1  # For new order sound
  vibration: ^1.8.4     # For haptic feedback
  
dev_dependencies:
  # (existing packages sufficient)
```

**Supabase Storage Buckets to Create:**
1. `restaurant-images` (Public, 5MB max)
2. `menu-item-images` (Public, 2MB max)

**Assets to Add:**
```
assets/
  sounds/
    new_order.mp3
```

---

## Summary

This plan transforms the restaurant experience from **55% to 100% complete** by implementing:

0. ✅ **Auth Integration** - Restaurant owners can sign up directly (not manually switch roles)
1. ✅ **Full menu management** - Add, edit, delete items with photos and customizations
2. ✅ **Restaurant settings** - Update all info, hours, delivery settings post-registration
3. ✅ **Real-time order alerts** - Never miss an order with sound, vibration, and push notifications
4. ✅ **Staff management** - Invite team members with role-based permissions
5. ✅ **Enhanced analytics** - Deeper insights into performance

**Total Investment:**
- **Time:** 86 hours (~3.5 weeks)
- **Cost:** ~$0.10/month
- **Result:** Fully functional restaurant management platform with seamless onboarding

**Next Steps:**
1. Review and approve this plan
2. Set up Supabase storage buckets
3. Start with Priority 1: Menu Management
4. Test thoroughly at each milestone
5. Roll out with restaurant partner feedback

---

**Document Version:** 1.0  
**Created:** January 2025  
**Status:** Ready for Implementation
