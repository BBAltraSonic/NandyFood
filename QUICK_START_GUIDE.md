# 🚀 Quick Start Guide - NandyFood Restaurant Platform

**Last Updated:** January 13, 2025

---

## ⚡ Quick Start

### **Run the App:**
```bash
cd "C:\Users\BB\Documents\NandyFood"
flutter run
```

### **Test Restaurant Owner Flow:**
1. Open app
2. Tap "Don't have an account? Sign Up"
3. Select "Sell Food" (restaurant owner)
4. Fill signup form
5. Complete restaurant registration
6. Start adding menu items!

### **Test Real-time Notifications:**
1. Sign in as restaurant owner
2. Open dashboard
3. Create a test order (via consumer account or database)
4. See real-time notification appear
5. Hear audio alert + feel vibration

### **Test User Profile:**
1. Sign in as any user
2. Tap Profile icon
3. Profile loads immediately (no spinner)
4. See real user data from database

---

## 📁 Key Files

### **Restaurant Screens:**
```
lib/features/restaurant_dashboard/presentation/screens/
├── restaurant_dashboard_screen.dart     # Main dashboard with realtime
├── restaurant_menu_screen.dart          # Menu list
├── add_edit_menu_item_screen.dart       # Add/edit items
├── restaurant_info_screen.dart          # Profile editor
├── operating_hours_screen.dart          # Hours editor
├── delivery_settings_screen.dart        # Delivery config
└── restaurant_settings_screen.dart      # Settings hub
```

### **Services:**
```
lib/features/restaurant_dashboard/services/
├── restaurant_management_service.dart   # CRUD operations
├── realtime_order_service.dart          # Real-time subscriptions
└── audio_notification_service.dart      # Audio/haptic alerts
```

### **Core:**
```
lib/core/
├── providers/auth_provider.dart         # Authentication
├── services/role_service.dart           # Multi-role management
└── utils/app_logger.dart                # Debug logging
```

### **Models:**
```
lib/shared/models/
├── restaurant.dart                      # Restaurant model (enhanced)
├── order.dart                           # Order model
└── user_profile.dart                    # User profile model
```

---

## 🗺️ Routes

### **Authentication:**
- `/auth/login` - Login screen
- `/auth/signup` - Signup screen
- `/auth/signup?role=restaurant` - Signup as restaurant owner

### **Restaurant Owner:**
- `/restaurant/register` - Restaurant registration
- `/restaurant/dashboard` - Main dashboard with realtime
- `/restaurant/menu` - Menu list
- `/restaurant/menu/add` - Add menu item
- `/restaurant/menu/edit/:itemId` - Edit menu item
- `/restaurant/settings` - Settings hub
- `/restaurant/settings/info` - Restaurant profile
- `/restaurant/settings/hours` - Operating hours
- `/restaurant/settings/delivery` - Delivery settings
- `/restaurant/orders` - Order management
- `/restaurant/analytics` - Analytics dashboard

### **User:**
- `/profile` - User profile screen
- `/home` - Home screen
- `/search` - Search restaurants

---

## 🔧 Common Tasks

### **Add a New Menu Item:**
1. Navigate to `/restaurant/menu`
2. Tap FAB (+) button
3. Follow 6-step wizard:
   - Step 1: Name, description, category
   - Step 2: Price, original price, prep time
   - Step 3: Dietary tags, allergens, spice level
   - Step 4: Customization options
   - Step 5: Upload image
   - Step 6: Review and save

### **Update Restaurant Info:**
1. Navigate to `/restaurant/settings`
2. Tap "Restaurant Info"
3. Update logo, cover, details
4. Tap checkmark to save

### **Set Operating Hours:**
1. Navigate to `/restaurant/settings`
2. Tap "Operating Hours"
3. Set hours for each day
4. Use quick actions to copy
5. Tap checkmark to save

### **Configure Delivery:**
1. Navigate to `/restaurant/settings`
2. Tap "Delivery Settings"
3. Set radius, fee, minimum order
4. See live preview
5. Tap checkmark to save

---

## 🐛 Troubleshooting

### **Profile Won't Load:**
```bash
# Check logs
flutter run --verbose

# Look for:
# "Loading user profile for: [user-id]"
# "User profile loaded successfully"
```

**Common causes:**
- User not authenticated → Sign in first
- No user_profile in database → Check Supabase
- RLS policy blocking → Verify policies

**Quick fix:**
```sql
-- Check if profile exists
SELECT * FROM user_profiles WHERE id = 'your-user-id';

-- Create if missing
INSERT INTO user_profiles (id, email, full_name)
VALUES ('user-id', 'email@example.com', 'Full Name');
```

---

### **Real-time Not Working:**
```bash
# Check Supabase connection
flutter run --verbose

# Look for:
# "Subscribing to real-time orders for restaurant"
# "✅ Subscribed to restaurant orders successfully!"
```

**Common causes:**
- Realtime not enabled → Run migration
- No subscription → Check dashboard screen
- Connection issues → Restart app

**Quick fix:**
```sql
-- Verify realtime enabled
SELECT * FROM pg_publication_tables 
WHERE schemaname = 'public' AND tablename = 'orders';

-- Enable if missing
ALTER PUBLICATION supabase_realtime ADD TABLE orders;
```

---

### **Image Upload Fails:**
```bash
# Check storage bucket exists
supabase___execute_sql("SELECT * FROM storage.buckets")
```

**Common causes:**
- Bucket doesn't exist → Create via Supabase dashboard
- No upload permission → Check RLS policies
- File too large → Check size limits

**Quick fix:**
1. Open Supabase Dashboard
2. Navigate to Storage
3. Create bucket: `menu-item-images` (public, 5MB)
4. Create bucket: `restaurant-images` (public, 5MB)

---

### **Compile Errors:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

**If MenuItem errors:**
```bash
# Regenerate models
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📊 Monitoring

### **Check Logs:**
```dart
// Console logs show:
AppLogger.section('🚀 APP STARTING')
AppLogger.info('Loading user profile for: user-id')
AppLogger.success('✅ Subscribed to restaurant orders')
AppLogger.warning('No user profile found')
AppLogger.error('Error loading: error-message')
```

### **Supabase Logs:**
```bash
# Via MCP
supabase___get_logs(service: 'api')
supabase___get_logs(service: 'realtime')
supabase___get_logs(service: 'storage')
```

### **Database Queries:**
```sql
-- Check active restaurants
SELECT id, name, is_active FROM restaurants;

-- Check menu items count
SELECT restaurant_id, COUNT(*) as items
FROM menu_items
GROUP BY restaurant_id;

-- Check recent orders
SELECT id, restaurant_id, status, total_amount, placed_at
FROM orders
ORDER BY placed_at DESC
LIMIT 10;

-- Check user profiles
SELECT COUNT(*) FROM user_profiles;

-- Check user roles
SELECT user_id, role, is_primary
FROM user_roles;
```

---

## 🎯 Testing Scenarios

### **Scenario 1: Restaurant Owner Signup**
1. Open app → Tap "Sign Up"
2. Select "Sell Food"
3. Enter: email, password, name
4. Tap "Create Account"
5. **Expected:** Redirected to restaurant registration
6. Fill restaurant details
7. **Expected:** Redirected to dashboard

### **Scenario 2: Add First Menu Item**
1. Sign in as restaurant owner
2. Navigate to Menu
3. **Expected:** Empty state with "Add First Item"
4. Tap "Add First Item"
5. Complete all 6 steps
6. **Expected:** Item appears in menu list

### **Scenario 3: Real-time Order**
1. Open restaurant dashboard
2. Create order in Supabase:
   ```sql
   INSERT INTO orders (restaurant_id, user_id, total_amount, status)
   VALUES ('restaurant-id', 'user-id', 100.00, 'placed');
   ```
3. **Expected:** 
   - Notification appears immediately
   - Audio alert plays
   - Device vibrates
   - Dashboard refreshes

### **Scenario 4: Profile View**
1. Sign in as any user
2. Tap Profile icon
3. **Expected:**
   - Profile loads < 1 second
   - Shows real user data
   - No infinite spinner

---

## 🔐 Security Checklist

### **RLS Policies (Verified):**
- ✅ Users can only view own profile
- ✅ Users can only update own profile
- ✅ Restaurant owners can only manage own restaurant
- ✅ Restaurant owners can only view own orders
- ✅ Menu items scoped to restaurant

### **Authentication:**
- ✅ Routes protected by auth guards
- ✅ Role-based access control
- ✅ Session management via Supabase
- ✅ Secure logout

### **Data Validation:**
- ✅ Client-side form validation
- ✅ Database constraints
- ✅ Type checking
- ✅ Null safety

---

## 📈 Performance

### **Optimization Applied:**
- ✅ Image compression before upload
- ✅ FutureProvider caching
- ✅ Lazy loading menu items
- ✅ Debounced search
- ✅ Stream management

### **Expected Performance:**
- Profile load: < 1 second
- Menu list: < 2 seconds
- Image upload: < 5 seconds
- Real-time notification: < 500ms latency

---

## 🆘 Emergency Fixes

### **App Won't Start:**
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter run
```

### **Database Issues:**
```sql
-- Reset user profile
DELETE FROM user_profiles WHERE id = 'user-id';
-- Trigger will recreate on next login

-- Reset restaurant
UPDATE restaurants SET is_active = true WHERE id = 'restaurant-id';

-- Clear orders
DELETE FROM orders WHERE restaurant_id = 'restaurant-id';
```

### **Storage Issues:**
```sql
-- Check buckets
SELECT id, name, public FROM storage.buckets;

-- Create missing buckets (via Supabase Dashboard)
-- 1. Go to Storage
-- 2. Create new bucket
-- 3. Set public/private
-- 4. Set size limits
```

---

## 📞 Support

### **Documentation:**
- `RESTAURANT_IMPLEMENTATION_COMPLETE.md` - Full implementation details
- `PROFILE_LOADING_FIXED.md` - Profile troubleshooting
- `COMPILE_ERRORS_FIXED.md` - Compilation fixes
- `SESSION_COMPLETE_SUMMARY.md` - Overall summary

### **Key Contacts:**
- Supabase Dashboard: https://app.supabase.com
- Flutter Docs: https://docs.flutter.dev
- Riverpod Docs: https://riverpod.dev

---

**Quick Reference Version:** 1.0  
**Last Tested:** January 13, 2025  
**Status:** ✅ All systems operational
