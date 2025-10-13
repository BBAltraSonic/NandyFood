# User Roles Implementation Plan - NandyFood

## Overview
This document outlines a comprehensive implementation plan for adding user role functionality to the NandyFood application. The system will support two primary user types:
1. **Consumers** - Regular users who order food
2. **Restaurants** - Business users who manage restaurant operations

---

## Table of Contents
1. [Database Schema Changes](#1-database-schema-changes)
2. [Backend Services & APIs](#2-backend-services--apis)
3. [State Management](#3-state-management)
4. [Authentication & Authorization](#4-authentication--authorization)
5. [UI Components & Screens](#5-ui-components--screens)
6. [Restaurant Dashboard](#6-restaurant-dashboard)
7. [Consumer Dashboard](#7-consumer-dashboard)
8. [Testing Strategy](#8-testing-strategy)
9. [Deployment & Migration](#9-deployment--migration)

---

## 1. Database Schema Changes

### Phase 1.1: Add User Role System

#### Create User Roles Table
```sql
-- Migration: 010_create_user_roles.sql

-- User roles enum
CREATE TYPE user_role_type AS ENUM ('consumer', 'restaurant_owner', 'restaurant_staff', 'admin', 'delivery_driver');

-- User roles table
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    role user_role_type NOT NULL DEFAULT 'consumer',
    is_primary BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, role)
);

CREATE INDEX idx_user_roles_user_id ON public.user_roles(user_id);
CREATE INDEX idx_user_roles_role ON public.user_roles(role);
CREATE INDEX idx_user_roles_primary ON public.user_roles(is_primary) WHERE is_primary = TRUE;
```

#### Update User Profiles Table
```sql
-- Add role-related fields to user_profiles
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS primary_role user_role_type DEFAULT 'consumer',
ADD COLUMN IF NOT EXISTS role_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS role_verification_date TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS role_metadata JSONB DEFAULT '{}'::jsonb;

CREATE INDEX idx_user_profiles_primary_role ON public.user_profiles(primary_role);
```

### Phase 1.2: Restaurant Ownership System

#### Restaurant Owners Table
```sql
-- Migration: 011_create_restaurant_owners.sql

CREATE TABLE IF NOT EXISTS public.restaurant_owners (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    owner_type TEXT CHECK (owner_type IN ('primary', 'co-owner', 'manager')) DEFAULT 'primary',
    permissions JSONB DEFAULT '{
        "manage_menu": true,
        "manage_orders": true,
        "manage_staff": false,
        "view_analytics": true,
        "manage_settings": false
    }'::jsonb,
    status TEXT CHECK (status IN ('active', 'pending', 'suspended', 'removed')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, restaurant_id)
);

CREATE INDEX idx_restaurant_owners_user_id ON public.restaurant_owners(user_id);
CREATE INDEX idx_restaurant_owners_restaurant_id ON public.restaurant_owners(restaurant_id);
CREATE INDEX idx_restaurant_owners_status ON public.restaurant_owners(status);
```

#### Restaurant Staff Table
```sql
CREATE TABLE IF NOT EXISTS public.restaurant_staff (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    role TEXT CHECK (role IN ('manager', 'chef', 'cashier', 'server', 'delivery')) NOT NULL,
    permissions JSONB DEFAULT '{}'::jsonb,
    employment_type TEXT CHECK (employment_type IN ('full-time', 'part-time', 'contractor')) DEFAULT 'full-time',
    status TEXT CHECK (status IN ('active', 'on_leave', 'suspended', 'terminated')) DEFAULT 'active',
    hired_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, restaurant_id)
);

CREATE INDEX idx_restaurant_staff_user_id ON public.restaurant_staff(user_id);
CREATE INDEX idx_restaurant_staff_restaurant_id ON public.restaurant_staff(restaurant_id);
CREATE INDEX idx_restaurant_staff_role ON public.restaurant_staff(role);
```

### Phase 1.3: Restaurant Analytics & Metrics

```sql
-- Migration: 012_create_restaurant_analytics.sql

CREATE TABLE IF NOT EXISTS public.restaurant_analytics (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    restaurant_id UUID REFERENCES public.restaurants(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    total_orders INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    cancelled_orders INTEGER DEFAULT 0,
    total_revenue DECIMAL(10, 2) DEFAULT 0,
    average_order_value DECIMAL(10, 2) DEFAULT 0,
    new_customers INTEGER DEFAULT 0,
    returning_customers INTEGER DEFAULT 0,
    average_prep_time INTEGER DEFAULT 0,
    average_delivery_time INTEGER DEFAULT 0,
    customer_satisfaction_score DECIMAL(3, 2),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(restaurant_id, date)
);

CREATE INDEX idx_restaurant_analytics_restaurant_id ON public.restaurant_analytics(restaurant_id);
CREATE INDEX idx_restaurant_analytics_date ON public.restaurant_analytics(date DESC);
```

### Phase 1.4: Row Level Security (RLS) Policies

```sql
-- Migration: 013_role_based_rls.sql

-- User Roles RLS
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own roles"
    ON public.user_roles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all roles"
    ON public.user_roles FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.user_roles
            WHERE user_id = auth.uid() AND role = 'admin'
        )
    );

-- Restaurant Owners RLS
ALTER TABLE public.restaurant_owners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Owners can view own restaurants"
    ON public.restaurant_owners FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Primary owners can manage co-owners"
    ON public.restaurant_owners FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurant_owners.restaurant_id
            AND owner_type = 'primary'
            AND status = 'active'
        )
    );

-- Restaurant modification by owners
CREATE POLICY "Owners can update their restaurants"
    ON public.restaurants FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = restaurants.id
            AND status = 'active'
        )
    );

-- Menu items RLS for restaurant owners
CREATE POLICY "Owners can manage menu items"
    ON public.menu_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = menu_items.restaurant_id
            AND status = 'active'
        )
    );

-- Orders visibility for restaurant owners
CREATE POLICY "Owners can view restaurant orders"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = orders.restaurant_id
            AND status = 'active'
        )
    );

CREATE POLICY "Owners can update restaurant orders"
    ON public.orders FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.restaurant_owners
            WHERE user_id = auth.uid()
            AND restaurant_id = orders.restaurant_id
            AND status = 'active'
        )
    );
```

### Phase 1.5: Database Functions & Triggers

```sql
-- Migration: 014_role_functions.sql

-- Function to assign default consumer role on signup
CREATE OR REPLACE FUNCTION public.assign_default_consumer_role()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_roles (user_id, role, is_primary)
    VALUES (NEW.id, 'consumer', TRUE)
    ON CONFLICT (user_id, role) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created_assign_role
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.assign_default_consumer_role();

-- Function to update primary role in user_profiles
CREATE OR REPLACE FUNCTION public.sync_primary_role()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        -- Update user_profiles with new primary role
        UPDATE public.user_profiles
        SET primary_role = NEW.role,
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        -- Set all other roles for this user to non-primary
        UPDATE public.user_roles
        SET is_primary = FALSE
        WHERE user_id = NEW.user_id
        AND id != NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_role_primary_change
    AFTER INSERT OR UPDATE OF is_primary ON public.user_roles
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION public.sync_primary_role();

-- Function to check if user has permission
CREATE OR REPLACE FUNCTION public.user_has_permission(
    p_user_id UUID,
    p_restaurant_id UUID,
    p_permission TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    has_perm BOOLEAN := FALSE;
BEGIN
    SELECT 
        COALESCE((permissions->>p_permission)::BOOLEAN, FALSE)
    INTO has_perm
    FROM public.restaurant_owners
    WHERE user_id = p_user_id
    AND restaurant_id = p_restaurant_id
    AND status = 'active';
    
    RETURN COALESCE(has_perm, FALSE);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate daily analytics
CREATE OR REPLACE FUNCTION public.calculate_daily_restaurant_analytics(
    p_restaurant_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS void AS $$
BEGIN
    INSERT INTO public.restaurant_analytics (
        restaurant_id,
        date,
        total_orders,
        completed_orders,
        cancelled_orders,
        total_revenue,
        average_order_value,
        new_customers,
        returning_customers
    )
    SELECT
        p_restaurant_id,
        p_date,
        COUNT(*) as total_orders,
        COUNT(*) FILTER (WHERE status = 'completed') as completed_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_orders,
        COALESCE(SUM(total_amount) FILTER (WHERE status = 'completed'), 0) as total_revenue,
        COALESCE(AVG(total_amount) FILTER (WHERE status = 'completed'), 0) as average_order_value,
        COUNT(DISTINCT user_id) FILTER (
            WHERE NOT EXISTS (
                SELECT 1 FROM public.orders o2
                WHERE o2.user_id = orders.user_id
                AND o2.created_at < p_date
            )
        ) as new_customers,
        COUNT(DISTINCT user_id) FILTER (
            WHERE EXISTS (
                SELECT 1 FROM public.orders o2
                WHERE o2.user_id = orders.user_id
                AND o2.created_at < p_date
            )
        ) as returning_customers
    FROM public.orders
    WHERE restaurant_id = p_restaurant_id
    AND DATE(created_at) = p_date
    ON CONFLICT (restaurant_id, date)
    DO UPDATE SET
        total_orders = EXCLUDED.total_orders,
        completed_orders = EXCLUDED.completed_orders,
        cancelled_orders = EXCLUDED.cancelled_orders,
        total_revenue = EXCLUDED.total_revenue,
        average_order_value = EXCLUDED.average_order_value,
        new_customers = EXCLUDED.new_customers,
        returning_customers = EXCLUDED.returning_customers;
END;
$$ LANGUAGE plpgsql;
```

---

## 2. Backend Services & APIs

### Phase 2.1: Role Service

**File:** `lib/core/services/role_service.dart`

```dart
class RoleService {
  final SupabaseClient _supabase = DatabaseService().client;
  
  // Get user roles
  Future<List<UserRole>> getUserRoles(String userId);
  
  // Check if user has role
  Future<bool> hasRole(String userId, String role);
  
  // Get primary role
  Future<UserRole?> getPrimaryRole(String userId);
  
  // Switch primary role (if user has multiple roles)
  Future<void> switchPrimaryRole(String userId, String roleType);
  
  // Request restaurant owner role
  Future<void> requestRestaurantOwnerRole(
    String userId,
    Map<String, dynamic> businessInfo
  );
  
  // Verify restaurant owner
  Future<void> verifyRestaurantOwner(String userId, String restaurantId);
}
```

### Phase 2.2: Restaurant Management Service

**File:** `lib/features/restaurant_dashboard/services/restaurant_management_service.dart`

```dart
class RestaurantManagementService {
  // Restaurant operations
  Future<Restaurant> getRestaurant(String restaurantId);
  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> updates);
  Future<void> updateOperatingHours(String restaurantId, Map<String, dynamic> hours);
  Future<void> toggleAcceptingOrders(String restaurantId, bool isAccepting);
  
  // Menu management
  Future<List<MenuItem>> getMenuItems(String restaurantId);
  Future<MenuItem> createMenuItem(MenuItem item);
  Future<void> updateMenuItem(String itemId, Map<String, dynamic> updates);
  Future<void> deleteMenuItem(String itemId);
  Future<void> toggleMenuItemAvailability(String itemId, bool isAvailable);
  
  // Order management
  Future<List<Order>> getRestaurantOrders(
    String restaurantId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });
  Future<void> updateOrderStatus(String orderId, String newStatus);
  Future<void> acceptOrder(String orderId, int estimatedPrepTime);
  Future<void> rejectOrder(String orderId, String reason);
  
  // Staff management
  Future<List<RestaurantStaff>> getStaff(String restaurantId);
  Future<void> addStaff(String restaurantId, String userId, String role);
  Future<void> updateStaffPermissions(String staffId, Map<String, dynamic> permissions);
  Future<void> removeStaff(String staffId);
  
  // Analytics
  Future<RestaurantAnalytics> getAnalytics(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<Map<String, dynamic>> getDashboardMetrics(String restaurantId);
}
```

### Phase 2.3: Permission Service

**File:** `lib/core/services/permission_service.dart`

```dart
class PermissionService {
  Future<bool> canManageMenu(String userId, String restaurantId);
  Future<bool> canManageOrders(String userId, String restaurantId);
  Future<bool> canManageStaff(String userId, String restaurantId);
  Future<bool> canViewAnalytics(String userId, String restaurantId);
  Future<bool> canManageSettings(String userId, String restaurantId);
  
  Future<Map<String, bool>> getAllPermissions(String userId, String restaurantId);
}
```

---

## 3. State Management

### Phase 3.1: Role State Management

**File:** `lib/core/providers/role_provider.dart`

```dart
// Role state
class RoleState {
  final UserRole? primaryRole;
  final List<UserRole> allRoles;
  final bool isLoading;
  final String? error;
  
  bool get isConsumer => primaryRole?.role == 'consumer';
  bool get isRestaurantOwner => primaryRole?.role == 'restaurant_owner';
  bool get isRestaurantStaff => primaryRole?.role == 'restaurant_staff';
  bool get hasMultipleRoles => allRoles.length > 1;
}

// Role provider
final roleProvider = StateNotifierProvider<RoleNotifier, RoleState>(
  (ref) => RoleNotifier(ref),
);

class RoleNotifier extends StateNotifier<RoleState> {
  Future<void> loadUserRoles();
  Future<void> switchRole(String roleType);
  Future<void> requestRestaurantRole(Map<String, dynamic> businessInfo);
}
```

### Phase 3.2: Restaurant Dashboard State

**File:** `lib/features/restaurant_dashboard/providers/restaurant_dashboard_provider.dart`

```dart
// Dashboard state
class RestaurantDashboardState {
  final Restaurant? restaurant;
  final List<Order> recentOrders;
  final List<Order> pendingOrders;
  final RestaurantAnalytics? analytics;
  final DashboardMetrics? metrics;
  final bool isLoading;
  final String? error;
}

// Dashboard provider
final restaurantDashboardProvider = 
    StateNotifierProvider.family<RestaurantDashboardNotifier, RestaurantDashboardState, String>(
  (ref, restaurantId) => RestaurantDashboardNotifier(ref, restaurantId),
);

class RestaurantDashboardNotifier extends StateNotifier<RestaurantDashboardState> {
  Future<void> loadDashboardData();
  Future<void> refreshOrders();
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> toggleAcceptingOrders();
}
```

### Phase 3.3: Menu Management State

**File:** `lib/features/restaurant_dashboard/providers/menu_management_provider.dart`

```dart
class MenuManagementState {
  final List<MenuItem> items;
  final Map<String, List<MenuItem>> itemsByCategory;
  final bool isLoading;
  final String? error;
}

final menuManagementProvider = 
    StateNotifierProvider.family<MenuManagementNotifier, MenuManagementState, String>(
  (ref, restaurantId) => MenuManagementNotifier(ref, restaurantId),
);

class MenuManagementNotifier extends StateNotifier<MenuManagementState> {
  Future<void> loadMenuItems();
  Future<void> addMenuItem(MenuItem item);
  Future<void> updateMenuItem(String itemId, Map<String, dynamic> updates);
  Future<void> deleteMenuItem(String itemId);
  Future<void> toggleItemAvailability(String itemId);
  Future<void> reorderCategories(List<String> newOrder);
}
```

### Phase 3.4: Restaurant Orders State

**File:** `lib/features/restaurant_dashboard/providers/restaurant_orders_provider.dart`

```dart
class RestaurantOrdersState {
  final List<Order> orders;
  final Map<String, List<Order>> ordersByStatus;
  final OrderFilters filters;
  final bool isLoading;
  final String? error;
}

final restaurantOrdersProvider = 
    StateNotifierProvider.family<RestaurantOrdersNotifier, RestaurantOrdersState, String>(
  (ref, restaurantId) => RestaurantOrdersNotifier(ref, restaurantId),
);

class RestaurantOrdersNotifier extends StateNotifier<RestaurantOrdersState> {
  Future<void> loadOrders();
  Future<void> filterOrders(OrderFilters filters);
  Future<void> acceptOrder(String orderId, int prepTime);
  Future<void> rejectOrder(String orderId, String reason);
  Future<void> markOrderReady(String orderId);
  Future<void> markOrderCompleted(String orderId);
}
```

---

## 4. Authentication & Authorization

### Phase 4.1: Update Auth Provider with Role Support

**File:** `lib/core/providers/auth_provider.dart` (Update existing)

```dart
// Add to AuthState
class AuthState {
  // ... existing fields
  final UserRole? primaryRole;
  final List<UserRole> roles;
  
  bool get canAccessRestaurantDashboard =>
      primaryRole?.role == 'restaurant_owner' ||
      primaryRole?.role == 'restaurant_staff';
  
  bool get canAccessAdminDashboard => primaryRole?.role == 'admin';
}

// Add to AuthStateNotifier
class AuthStateNotifier extends StateNotifier<AuthState> {
  // ... existing methods
  
  Future<void> loadUserRoles() async {
    // Load roles after authentication
  }
  
  Future<String> getInitialRoute() async {
    if (state.primaryRole?.role == 'restaurant_owner') {
      return '/restaurant/dashboard';
    } else if (state.primaryRole?.role == 'restaurant_staff') {
      return '/restaurant/orders';
    } else {
      return '/home';
    }
  }
}
```

### Phase 4.2: Route Guards

**File:** `lib/core/routing/route_guards.dart`

```dart
class RouteGuards {
  static String? requireRestaurantRole(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    
    if (!authState.isAuthenticated) {
      return '/auth/login?redirect=${state.uri}';
    }
    
    if (!authState.canAccessRestaurantDashboard) {
      return '/home'; // Redirect to consumer home
    }
    
    return null; // Allow access
  }
  
  static String? requireConsumerRole(BuildContext context, GoRouterState state) {
    // Similar logic for consumer-only routes
  }
}
```

---

## 5. UI Components & Screens

### Phase 5.1: Role Selection Components

**File:** `lib/shared/widgets/role_selector_widget.dart`

```dart
class RoleSelectorWidget extends ConsumerWidget {
  // Dropdown or modal to switch between roles
  // Show when user has multiple roles
}
```

**File:** `lib/features/authentication/presentation/screens/role_selection_screen.dart`

```dart
class RoleSelectionScreen extends StatelessWidget {
  // Screen shown after signup to select primary role
  // Options: Continue as Consumer, Register as Restaurant Owner
}
```

### Phase 5.2: Restaurant Registration Flow

**File:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_registration_screen.dart`

```dart
class RestaurantRegistrationScreen extends StatefulWidget {
  // Multi-step form for restaurant registration:
  // 1. Business Information
  // 2. Location & Contact
  // 3. Operating Hours
  // 4. Cuisine & Features
  // 5. Verification Documents
}
```

---

## 6. Restaurant Dashboard

### Phase 6.1: Main Dashboard Screen

**File:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart`

**Features:**
- Quick stats cards (Today's Orders, Revenue, Avg. Order Value)
- Pending orders list (with quick actions)
- Recent activity feed
- Quick access buttons (Menu, Orders, Analytics)
- Toggle accepting orders switch
- Real-time order notifications

**Widgets:**
- `DashboardStatCard`
- `PendingOrderCard`
- `QuickActionButton`
- `RecentActivityList`

### Phase 6.2: Orders Management Screen

**File:** `lib/features/restaurant_dashboard/presentation/screens/orders_management_screen.dart`

**Features:**
- Tabs: Pending, Preparing, Ready, Completed, Cancelled
- Order cards with customer info
- Accept/Reject actions for pending orders
- Set preparation time estimate
- Mark order as ready
- Filter by date range
- Search by order ID or customer name
- Real-time updates via Supabase Realtime

**Widgets:**
- `OrderStatusTabs`
- `RestaurantOrderCard`
- `OrderActionButtons`
- `OrderDetailsModal`
- `OrderFiltersSheet`

### Phase 6.3: Menu Management Screen

**File:** `lib/features/restaurant_dashboard/presentation/screens/menu_management_screen.dart`

**Features:**
- List of all menu items grouped by category
- Add new item button
- Edit/Delete item actions
- Toggle item availability (in stock/out of stock)
- Drag to reorder items
- Bulk operations (disable multiple items)
- Image upload for menu items

**Widgets:**
- `MenuCategorySection`
- `MenuItemCard`
- `AddMenuItemFab`
- `MenuItemFormSheet`
- `ItemAvailabilityToggle`

### Phase 6.4: Analytics Screen

**File:** `lib/features/restaurant_dashboard/presentation/screens/analytics_screen.dart`

**Features:**
- Date range selector
- Revenue chart (line/bar chart)
- Orders chart (daily orders)
- Top selling items
- Customer insights (new vs returning)
- Average order value trends
- Peak hours heatmap
- Export data option

**Widgets:**
- `DateRangeSelector`
- `RevenueChart` (using fl_chart)
- `OrdersChart`
- `TopItemsList`
- `CustomerInsightsCard`
- `PeakHoursHeatmap`

### Phase 6.5: Restaurant Settings Screen

**File:** `lib/features/restaurant_dashboard/presentation/screens/restaurant_settings_screen.dart`

**Features:**
- Restaurant info editor
- Operating hours manager
- Delivery settings (radius, fee, min order)
- Staff management
- Notification preferences
- Business verification status
- Bank account / payout settings

**Widgets:**
- `RestaurantInfoForm`
- `OperatingHoursEditor`
- `DeliverySettingsForm`
- `StaffManagementList`
- `NotificationPreferences`

### Phase 6.6: Staff Management Screen

**File:** `lib/features/restaurant_dashboard/presentation/screens/staff_management_screen.dart`

**Features:**
- List of staff members
- Add new staff (invite by email)
- Assign roles and permissions
- View staff activity
- Remove staff

---

## 7. Consumer Dashboard

### Phase 7.1: Enhanced Home Screen

**Update:** `lib/features/home/presentation/screens/home_screen.dart`

**New Features:**
- Show role selector if user has multiple roles
- "Switch to Restaurant Dashboard" button for restaurant owners
- Personalized recommendations based on role

### Phase 7.2: Consumer Profile with Role Info

**Update:** `lib/features/profile/presentation/screens/profile_screen.dart`

**New Sections:**
- Current role badge
- "Become a Restaurant Owner" CTA (if consumer only)
- Role management option (if multiple roles)

---

## 8. Testing Strategy

### Phase 8.1: Database Tests
- Test RLS policies for each role
- Test role assignment triggers
- Test permission checking functions
- Test analytics calculation functions

### Phase 8.2: Service Tests
- Unit tests for RoleService
- Unit tests for RestaurantManagementService
- Unit tests for PermissionService
- Integration tests for role switching

### Phase 8.3: Provider Tests
- Test role state management
- Test dashboard state updates
- Test menu management state
- Test order management state

### Phase 8.4: UI Tests
- Widget tests for dashboard components
- Integration tests for restaurant registration flow
- Integration tests for order management flow
- End-to-end tests for complete user journeys

### Phase 8.5: Security Tests
- Test unauthorized access attempts
- Test permission boundaries
- Test RLS policy enforcement
- Test role switching security

---

## 9. Deployment & Migration

### Phase 9.1: Pre-Deployment Checklist

1. **Database Migrations**
   - [ ] Run all migration scripts in order (010-014)
   - [ ] Verify RLS policies are active
   - [ ] Test database functions
   - [ ] Backup production database

2. **Environment Setup**
   - [ ] Update environment variables
   - [ ] Configure Supabase realtime for restaurant orders
   - [ ] Set up notification channels
   - [ ] Configure storage buckets for restaurant images

3. **Code Deployment**
   - [ ] Merge feature branch to main
   - [ ] Run all tests
   - [ ] Build and test Android/iOS apps
   - [ ] Deploy to staging environment

### Phase 9.2: Migration Strategy

1. **Existing Users**
   - All existing users automatically assigned 'consumer' role
   - Send notification about new restaurant features
   - Provide link to restaurant registration

2. **Data Migration**
   - No changes to existing orders, profiles, restaurants
   - Restaurant owners table initially empty
   - Gradual onboarding of restaurant partners

3. **Rollout Plan**
   - Week 1: Deploy to staging, internal testing
   - Week 2: Beta testing with 5-10 restaurant partners
   - Week 3: Fix issues, gather feedback
   - Week 4: Full production rollout
   - Week 5: Marketing campaign for restaurant signups

### Phase 9.3: Monitoring & Analytics

**Track:**
- Number of users switching roles
- Restaurant registration conversion rate
- Restaurant dashboard usage metrics
- Order acceptance time by restaurants
- Customer satisfaction with restaurant responsiveness

**Alerts:**
- Failed role assignments
- RLS policy violations
- High order rejection rates
- System errors in restaurant dashboard

---

## 10. Implementation Timeline

### Week 1-2: Database & Backend
- ✅ Create database migrations (010-014)
- ✅ Implement RLS policies
- ✅ Create database functions
- ✅ Build RoleService
- ✅ Build RestaurantManagementService
- ✅ Build PermissionService

### Week 3-4: State Management & Core Logic
- ✅ Implement role providers
- ✅ Implement restaurant dashboard providers
- ✅ Implement menu management providers
- ✅ Implement order management providers
- ✅ Update auth provider with role support
- ✅ Create route guards

### Week 5-6: Restaurant Dashboard UI
- ✅ Create dashboard screen with stats
- ✅ Create orders management screen
- ✅ Create menu management screen
- ✅ Create analytics screen
- ✅ Create restaurant settings screen
- ✅ Create staff management screen

### Week 7: Consumer Experience Updates
- ✅ Update home screen
- ✅ Update profile screen
- ✅ Create role selection UI
- ✅ Create restaurant registration flow

### Week 8: Testing & Polish
- ✅ Write and run unit tests
- ✅ Write and run integration tests
- ✅ Conduct security testing
- ✅ UI/UX polish and refinements
- ✅ Performance optimization

### Week 9: Deployment & Beta
- ✅ Deploy to staging
- ✅ Beta testing with restaurants
- ✅ Gather feedback
- ✅ Fix critical issues

### Week 10: Production Launch
- ✅ Production deployment
- ✅ Monitor system health
- ✅ Support restaurant onboarding
- ✅ Marketing campaign

---

## 11. Key Models & Data Structures

### UserRole Model
```dart
class UserRole {
  final String id;
  final String userId;
  final String role; // 'consumer', 'restaurant_owner', 'restaurant_staff', 'admin'
  final bool isPrimary;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### RestaurantOwner Model
```dart
class RestaurantOwner {
  final String id;
  final String userId;
  final String restaurantId;
  final String ownerType; // 'primary', 'co-owner', 'manager'
  final Map<String, bool> permissions;
  final String status; // 'active', 'pending', 'suspended'
  final DateTime createdAt;
}
```

### RestaurantAnalytics Model
```dart
class RestaurantAnalytics {
  final String id;
  final String restaurantId;
  final DateTime date;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int newCustomers;
  final int returningCustomers;
  final int? averagePrepTime;
  final int? averageDeliveryTime;
  final double? customerSatisfactionScore;
}
```

### DashboardMetrics Model
```dart
class DashboardMetrics {
  final int todayOrders;
  final double todayRevenue;
  final int pendingOrders;
  final double avgOrderValue;
  final int activeMenuItems;
  final double restaurantRating;
  final int totalReviews;
  final bool isAcceptingOrders;
}
```

---

## 12. Navigation Structure

```
Root
├── Consumer Flow
│   ├── /home
│   ├── /restaurants
│   ├── /restaurant/:id
│   ├── /cart
│   ├── /checkout
│   ├── /order/track
│   ├── /order/history
│   └── /profile
│
├── Restaurant Flow (NEW)
│   ├── /restaurant/dashboard
│   ├── /restaurant/orders
│   ├── /restaurant/menu
│   ├── /restaurant/analytics
│   ├── /restaurant/settings
│   ├── /restaurant/staff
│   └── /restaurant/registration
│
├── Authentication
│   ├── /auth/login
│   ├── /auth/signup
│   ├── /auth/role-selection
│   └── /auth/forgot-password
│
└── Shared
    └── /settings
```

---

## 13. Real-time Features

### Supabase Realtime Subscriptions

**For Restaurant Dashboard:**
```dart
// Listen to new orders for restaurant
DatabaseService().client
  .from('orders')
  .stream(primaryKey: ['id'])
  .eq('restaurant_id', restaurantId)
  .eq('status', 'pending')
  .listen((List<Map<String, dynamic>> data) {
    // Update pending orders in real-time
    // Show notification
    // Play sound alert
  });

// Listen to order status changes
DatabaseService().client
  .from('orders')
  .stream(primaryKey: ['id'])
  .eq('restaurant_id', restaurantId)
  .listen((List<Map<String, dynamic>> data) {
    // Update orders list in real-time
  });
```

**For Consumers:**
```dart
// Listen to their order status (existing functionality)
// No changes needed
```

---

## 14. Notification Strategy

### Push Notifications for Restaurants

1. **New Order Received**
   - Title: "New Order #12345"
   - Body: "Order from John Doe - $25.99"
   - Action: Open orders screen

2. **Order Cancellation by Customer**
   - Title: "Order Cancelled"
   - Body: "Order #12345 was cancelled by customer"

3. **Customer Support Message**
   - Title: "Customer Message"
   - Body: "Customer has a question about their order"

4. **Daily Summary**
   - Title: "Today's Performance"
   - Body: "15 orders, $425 revenue"
   - Scheduled: 10 PM daily

### In-App Notifications
- Badge count on restaurant dashboard for pending orders
- Sound alert for new orders
- Toast notifications for order status changes

---

## 15. Security Considerations

1. **Role Verification**
   - Verify restaurant ownership before allowing access
   - Require business documentation upload
   - Admin approval for restaurant owner role

2. **Permission Checks**
   - Always check permissions server-side
   - Never trust client-side role claims
   - Use RLS policies for data access

3. **Audit Logging**
   - Log all role changes
   - Log all permission grants/revokes
   - Log sensitive restaurant operations

4. **Rate Limiting**
   - Limit restaurant registration requests
   - Limit order status update frequency
   - Prevent abuse of analytics endpoints

---

## 16. Future Enhancements (Post-MVP)

1. **Multi-Restaurant Management**
   - One owner can manage multiple restaurants
   - Switch between restaurants in dashboard

2. **Advanced Analytics**
   - Predictive analytics for demand
   - Inventory management suggestions
   - Customer behavior insights

3. **Staff App**
   - Separate lightweight app for staff
   - Focus on order fulfillment
   - Kitchen display system

4. **Delivery Driver Role**
   - Add delivery_driver role
   - Driver dashboard
   - Route optimization

5. **Loyalty & Promotions**
   - Restaurant-specific loyalty programs
   - Custom promotion creation
   - Discount management

6. **Table Reservations**
   - For dine-in restaurants
   - Table management system
   - Reservation notifications

---

## 17. API Endpoints Summary

### Role Management
- `GET /api/roles/user/:userId` - Get user roles
- `POST /api/roles/switch` - Switch primary role
- `POST /api/roles/request-restaurant` - Request restaurant owner role

### Restaurant Management
- `GET /api/restaurant/:id` - Get restaurant details
- `PUT /api/restaurant/:id` - Update restaurant
- `POST /api/restaurant/:id/toggle-orders` - Toggle accepting orders

### Menu Management
- `GET /api/restaurant/:id/menu` - Get menu items
- `POST /api/restaurant/:id/menu` - Create menu item
- `PUT /api/menu-item/:id` - Update menu item
- `DELETE /api/menu-item/:id` - Delete menu item
- `POST /api/menu-item/:id/toggle` - Toggle availability

### Order Management
- `GET /api/restaurant/:id/orders` - Get restaurant orders
- `POST /api/order/:id/accept` - Accept order
- `POST /api/order/:id/reject` - Reject order
- `PUT /api/order/:id/status` - Update order status

### Analytics
- `GET /api/restaurant/:id/analytics` - Get analytics
- `GET /api/restaurant/:id/dashboard-metrics` - Get dashboard metrics

### Staff Management
- `GET /api/restaurant/:id/staff` - Get staff list
- `POST /api/restaurant/:id/staff` - Add staff member
- `PUT /api/staff/:id` - Update staff permissions
- `DELETE /api/staff/:id` - Remove staff member

---

## Conclusion

This comprehensive plan covers all aspects of implementing user roles in the NandyFood application. The implementation follows a phased approach starting with database schema, then backend services, state management, and finally UI components.

**Key Success Metrics:**
- 95%+ role assignment success rate
- <2 second dashboard load time
- <10 second order notification delay
- 80%+ restaurant owner satisfaction
- 50+ restaurants onboarded in first month

**Next Steps:**
1. Review and approve this plan
2. Set up project board with tasks
3. Begin Phase 1: Database Schema Changes
4. Daily standups to track progress
5. Weekly demos to stakeholders

---

**Document Version:** 1.0  
**Last Updated:** October 13, 2025  
**Author:** NandyFood Development Team  
**Status:** Ready for Implementation
