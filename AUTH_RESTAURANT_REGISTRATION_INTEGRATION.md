# 🔐 Restaurant Registration - Authentication Integration Plan

**Problem:** Users cannot register as a restaurant owner during the signup process. They must sign up as a consumer first, then navigate to role selection.

**Solution:** Add restaurant registration option directly in the authentication flow.

---

## 🎯 Current Flow vs Proposed Flow

### **Current Flow (Broken)**
```
1. User visits Signup Screen
2. Enters email, password, name
3. Auto-assigned "Consumer" role
4. Redirected to /home
5. (Manual) Navigate to Profile → Switch Role → Restaurant Owner
6. Redirected to /restaurant/register
```

**Problems:**
- ❌ No way to register as restaurant during signup
- ❌ Extra steps required (poor UX)
- ❌ Users might not discover restaurant features
- ❌ Confusing for restaurant owners

### **Proposed Flow (Fixed)**
```
Option A: Role Selection During Signup
1. User visits Signup Screen
2. Enters email, password, name
3. **NEW:** Select "I want to..." → Consumer OR Restaurant Owner
4. Sign up with selected role
5a. If Consumer → Redirect to /home
5b. If Restaurant Owner → Redirect to /restaurant/register

Option B: Separate Restaurant Signup
1. Add "Sign up as Restaurant" button on login/signup
2. Navigate to dedicated restaurant signup
3. Combined auth + restaurant info in one flow
4. Create account with restaurant_owner role
5. Redirect to restaurant dashboard
```

**Recommendation:** **Option A** - Simpler to implement, better UX

---

## 📋 Implementation Plan - Option A (Recommended)

### **STEP 1: Modify Signup Screen** (2 hours)

**File:** `lib/features/authentication/presentation/screens/signup_screen.dart`

**Changes:**

1. **Add role selection before form:**
```dart
class _SignupScreenState extends ConsumerState<SignupScreen> {
  // ... existing controllers ...
  UserRoleType _selectedRole = UserRoleType.consumer; // NEW
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Logo and title
            _buildHeader(),
            
            // NEW: Role selector
            _buildRoleSelector(),
            
            // Existing form fields
            _buildSignupForm(),
            
            // Submit button
            _buildSignupButton(),
          ],
        ),
      ),
    );
  }
  
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
  
  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      try {
        ref.read(authStateProvider.notifier).clearErrorMessage();
        
        // Sign up user
        await ref.read(authStateProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

        // Assign role
        await ref.read(authStateProvider.notifier).switchRole(_selectedRole);

        if (!mounted) return;

        // Navigate based on role
        if (_selectedRole == UserRoleType.restaurantOwner) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Let\'s set up your restaurant.'),
              backgroundColor: Colors.green,
            ),
          );
          // Redirect to restaurant registration
          context.go('/restaurant/register');
        } else {
          // Consumer signup - redirect to home
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
}
```

**Visual Design:**

```
┌─────────────────────────────────────┐
│         Create Account              │
│   Join us and discover delicious    │
│              food                    │
├─────────────────────────────────────┤
│                                     │
│  ┌────────────┐  ┌────────────┐   │
│  │  🛍️        │  │   🏪       │   │
│  │ Order Food │  │ Sell Food  │   │  ← Role Selector
│  │I'm customer│  │I own resto │   │
│  └────────────┘  └────────────┘   │
│                                     │
│  Full Name: [________________]     │
│  Email:     [________________]     │
│  Password:  [________________]     │
│  Confirm:   [________________]     │
│                                     │
│       [Create Account Button]      │
└─────────────────────────────────────┘
```

---

### **STEP 2: Update AuthProvider** (1 hour)

**File:** `lib/core/providers/auth_provider.dart`

**Verify these methods exist:**

```dart
// Should already exist, but verify:
Future<void> signUp({
  required String email,
  required String password,
  required String fullName,
}) async {
  // Create auth user
  final response = await _authService.signUp(
    email: email,
    password: password,
    fullName: fullName,
  );
  
  // Create user_profile
  await _createUserProfile(response.user!.id, email, fullName);
  
  // Assign default consumer role
  await _assignDefaultRole(response.user!.id);
  
  state = state.copyWith(user: response.user, isAuthenticated: true);
}

Future<void> switchRole(UserRoleType roleType) async {
  final userId = state.user?.id;
  if (userId == null) return;
  
  // Check if user already has this role
  final hasRole = await _roleService.hasRole(userId, roleType);
  
  if (!hasRole) {
    // Assign new role
    await _roleService.assignRole(userId, roleType, isPrimary: true);
  } else {
    // Just set as primary
    await _roleService.setPrimaryRole(userId, roleType);
  }
  
  // Update state
  final primaryRole = await _roleService.getPrimaryRole(userId);
  state = state.copyWith(primaryRole: primaryRole);
}
```

**Modifications needed:**

```dart
// MODIFY signUp to accept optional role parameter:
Future<void> signUp({
  required String email,
  required String password,
  required String fullName,
  UserRoleType initialRole = UserRoleType.consumer, // NEW parameter
}) async {
  // Create auth user
  final response = await _authService.signUp(
    email: email,
    password: password,
    fullName: fullName,
  );
  
  // Create user_profile
  await _createUserProfile(response.user!.id, email, fullName);
  
  // Assign specified role (not just consumer)
  await _roleService.assignRole(
    response.user!.id, 
    initialRole, 
    isPrimary: true
  );
  
  state = state.copyWith(
    user: response.user, 
    isAuthenticated: true,
    primaryRole: UserRole(
      userId: response.user!.id,
      role: initialRole,
      isPrimary: true,
    ),
  );
}
```

**Update signup call:**
```dart
// OLD:
await ref.read(authStateProvider.notifier).signUp(
  email: _emailController.text.trim(),
  password: _passwordController.text,
  fullName: _nameController.text.trim(),
);

// NEW:
await ref.read(authStateProvider.notifier).signUp(
  email: _emailController.text.trim(),
  password: _passwordController.text,
  fullName: _nameController.text.trim(),
  initialRole: _selectedRole, // Pass selected role
);
```

---

### **STEP 3: Add Visual Indicator on Login Screen** (30 min)

**File:** `lib/features/authentication/presentation/screens/login_screen.dart`

**Add button for restaurant owners:**

```dart
// After existing "Don't have an account? Sign up" link:

const SizedBox(height: 16),
const Divider(),
const SizedBox(height: 16),

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
          Icon(Icons.store_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text(
            'Own a restaurant?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade900,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Join NandyFood and grow your business',
        style: TextStyle(
          fontSize: 13,
          color: Colors.orange.shade700,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () => context.go('/auth/signup?role=restaurant'),
        icon: const Icon(Icons.restaurant_menu),
        label: const Text('Register Your Restaurant'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orange.shade700,
          side: BorderSide(color: Colors.orange.shade700),
        ),
      ),
    ],
  ),
),
```

**Update signup route to pre-select role:**

```dart
// In main.dart router:
GoRoute(
  path: '/auth/signup',
  builder: (context, state) {
    final roleParam = state.uri.queryParameters['role'];
    final preselectedRole = roleParam == 'restaurant' 
      ? UserRoleType.restaurantOwner 
      : UserRoleType.consumer;
    
    return SignupScreen(preselectedRole: preselectedRole);
  },
),
```

**Update SignupScreen to accept parameter:**
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

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late UserRoleType _selectedRole;
  
  @override
  void initState() {
    super.initState();
    _selectedRole = widget.preselectedRole ?? UserRoleType.consumer;
  }
  
  // ... rest of implementation
}
```

---

### **STEP 4: Improve Restaurant Registration Flow** (1 hour)

**File:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_registration_screen.dart`

**Add onboarding context at the start:**

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Register Your Restaurant'),
      // Don't allow back navigation if coming from signup
      automaticallyImplyLeading: widget.fromSignup ? false : true,
    ),
    body: Column(
      children: [
        // NEW: Welcome banner for new signups
        if (widget.fromSignup) _buildWelcomeBanner(),
        
        // Existing progress indicator and form
        _buildProgressIndicator(),
        Expanded(child: _buildForm()),
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
          'Let\'s get your restaurant set up in just a few steps',
          style: TextStyle(color: Colors.green.shade700),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
```

**Add "Skip for Now" option:**

```dart
// In _buildNavigationButtons():
Row(
  children: [
    if (_currentStep > 0)
      TextButton(
        onPressed: _previousStep,
        child: const Text('Back'),
      ),
    const Spacer(),
    
    // NEW: Allow skipping to save as draft
    if (_currentStep < 4)
      TextButton(
        onPressed: _saveDraft,
        child: const Text('Save Draft & Continue Later'),
      ),
    
    if (_currentStep < 4)
      ElevatedButton(
        onPressed: _nextStep,
        child: const Text('Next'),
      )
    else
      ElevatedButton(
        onPressed: _submit,
        child: const Text('Complete Registration'),
      ),
  ],
)
```

---

### **STEP 5: Update Navigation Flow** (30 min)

**File:** `lib/main.dart`

**Ensure restaurant registration route is accessible:**

```dart
GoRoute(
  path: '/restaurant/register',
  builder: (context, state) {
    final fromSignup = state.uri.queryParameters['fromSignup'] == 'true';
    return RestaurantRegistrationScreen(fromSignup: fromSignup);
  },
),
```

**Update signup navigation:**
```dart
// In SignupScreen after successful restaurant owner signup:
context.go('/restaurant/register?fromSignup=true');
```

---

## 📱 User Experience Flow

### **New Restaurant Owner Signup:**

1. **Visit Login Page**
   - See "Own a restaurant?" banner
   - Click "Register Your Restaurant"

2. **Signup Page**
   - Role pre-selected to "Restaurant Owner"
   - Fill email, password, name
   - Click "Create Account"

3. **Restaurant Registration**
   - Welcome banner shows
   - Multi-step form (5 steps):
     - Basic Info
     - Location
     - Details (cuisine, hours, etc.)
     - Operating Hours
     - Review
   - Can save draft and continue later
   - Submit to create restaurant

4. **Restaurant Dashboard**
   - Guided tour of features
   - Prompt to add first menu item

### **Existing Flow (Consumer):**

1. **Visit Signup Page**
   - Role defaults to "Consumer"
   - Fill form
   - Click "Create Account"

2. **Home Screen**
   - Browse restaurants
   - Can switch to restaurant owner role later from profile

---

## ✅ Testing Checklist

### **Restaurant Owner Signup**
- [ ] Click "Register Your Restaurant" on login page
- [ ] Signup page has "Restaurant Owner" pre-selected
- [ ] Create account with restaurant role
- [ ] Redirects to restaurant registration
- [ ] Welcome banner displays
- [ ] Complete all 5 steps
- [ ] Restaurant created successfully
- [ ] Redirects to restaurant dashboard

### **Consumer Signup**
- [ ] Normal signup flow unchanged
- [ ] Defaults to "Consumer" role
- [ ] Can toggle to "Restaurant Owner" before submitting
- [ ] If toggled, follows restaurant flow
- [ ] If not toggled, goes to home screen

### **Role Switching**
- [ ] Can switch from consumer to restaurant owner in profile
- [ ] Redirects to restaurant registration if no restaurant
- [ ] Redirects to dashboard if restaurant exists

### **Edge Cases**
- [ ] Signup with restaurant role, exit registration
- [ ] Can resume registration later
- [ ] Draft restaurants saved
- [ ] Can have both consumer and restaurant roles

---

## 🎨 Visual Mockups

### **Login Screen - Restaurant CTA:**
```
┌─────────────────────────────────────┐
│           Welcome Back              │
│                                     │
│  Email:    [________________]      │
│  Password: [________________]      │
│                                     │
│         [Sign In Button]           │
│                                     │
│  Don't have an account? Sign Up    │
│                                     │
│ ──────────────────────────────────  │
│                                     │
│ ┌─────────────────────────────┐   │
│ │  🏪  Own a restaurant?      │   │
│ │  Join NandyFood and grow    │   │
│ │      your business          │   │
│ │                             │   │
│ │ [Register Your Restaurant] │   │
│ └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### **Signup Screen - Role Selector:**
```
┌─────────────────────────────────────┐
│         Create Account              │
│   Join us and discover delicious    │
│              food                    │
│                                     │
│ ┌───────────────────────────────┐  │
│ │  🛍️ Order Food │ 🏪 Sell Food│  │  ← Tabs
│ │  I'm customer  │I own resto   │  │
│ └───────────────────────────────┘  │
│                                     │
│  Full Name: [________________]     │
│  Email:     [________________]     │
│  Password:  [________________]     │
│  Confirm:   [________________]     │
│                                     │
│       [Create Account Button]      │
└─────────────────────────────────────┘
```

---

## 📅 Implementation Timeline

| Task | Time | Priority |
|------|------|----------|
| Step 1: Modify Signup Screen | 2 hours | HIGH |
| Step 2: Update AuthProvider | 1 hour | HIGH |
| Step 3: Login Screen CTA | 30 min | MEDIUM |
| Step 4: Restaurant Registration Flow | 1 hour | MEDIUM |
| Step 5: Navigation Updates | 30 min | LOW |
| Testing & Bug Fixes | 1 hour | HIGH |
| **Total** | **6 hours** | |

---

## 🚀 Alternative: Option B - Dedicated Restaurant Signup

If you prefer a completely separate flow for restaurants:

**Create:** `lib/features/authentication/presentation/screens/restaurant_signup_screen.dart`

**Combined Form:**
- Step 1: Account Info (email, password, name)
- Step 2: Restaurant Basic Info
- Step 3: Location & Contact
- Step 4: Operating Details
- Step 5: Review & Submit

**Advantages:**
- Cleaner separation
- More context-specific UI
- Can collect more upfront info

**Disadvantages:**
- More code duplication
- Harder to maintain
- Users can't easily become both

**Recommendation:** Stick with Option A (simpler, more flexible)

---

## Summary

**Problem Solved:** ✅ Users can now register as a restaurant owner during signup

**Implementation:**
1. Add role selector to signup page
2. Update auth provider to accept initial role
3. Add restaurant CTA on login page
4. Improve restaurant registration onboarding
5. Update navigation flows

**Time Required:** 6 hours

**User Impact:** 
- Restaurant owners can sign up in one flow
- Clearer path to restaurant features
- Better conversion for restaurant signups

---

**Document Version:** 1.0  
**Created:** January 2025  
**Status:** Ready for Implementation
