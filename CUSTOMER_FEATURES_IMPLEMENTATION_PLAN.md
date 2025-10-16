# 🎯 Customer Features Implementation Plan
**NandyFood - Complete Customer Experience**

**Date Created:** January 2025  
**Current Completion:** 72% → Target: 95%  
**Estimated Timeline:** 3-4 weeks  
**Total Effort:** ~120 hours

---

## 📊 Executive Summary

This plan outlines the implementation roadmap to complete all customer-facing features in the NandyFood app. The focus is on delivering a **competitive, modern food delivery experience** that matches industry standards (Uber Eats, DoorDash).

### Current Status
- ✅ **Core ordering flow:** Complete (discover, order, pay, basic tracking)
- ⚠️ **Real-time features:** 50% complete (UI exists, backend incomplete)
- ⚠️ **Engagement features:** 70% complete (reviews work, photos missing)
- ❌ **Advanced features:** 0% complete (social, loyalty, advanced personalization)

### Success Criteria
By completion, customers should be able to:
1. ✅ Discover restaurants visually on a map with pins
2. ✅ Order food with full customization
3. ✅ Track their delivery driver in real-time on a live map
4. ✅ Receive push notifications for order status changes
5. ✅ Upload photos to reviews and profile
6. ✅ Have a seamless, polished experience across all flows

---

## 🚀 Implementation Priorities

### **PRIORITY 1: Real-Time Driver Tracking** 🔴 CRITICAL
**Impact:** HIGH - Major competitive differentiator  
**Effort:** 16-20 hours  
**Timeline:** 3-4 days

#### Current State (70% complete)
- ✅ RealtimeService exists with driver location channel
- ✅ OrderTrackingScreen UI complete with map widget
- ✅ Order status timeline widget
- ❌ Driver location not connected to map
- ❌ No real-time updates rendering on map
- ❌ Missing driver info display (name, photo, contact)

#### Implementation Tasks

##### **Task 1.1: Backend - Supabase Realtime Setup** (4 hours)
**Files to create/modify:**
- `supabase/migrations/20250115_add_driver_location_tracking.sql`

**Steps:**
1. Create `driver_locations` table:
   ```sql
   CREATE TABLE driver_locations (
     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
     driver_id UUID REFERENCES profiles(id) NOT NULL,
     order_id UUID REFERENCES orders(id),
     latitude DECIMAL(10, 8) NOT NULL,
     longitude DECIMAL(11, 8) NOT NULL,
     heading DECIMAL(5, 2), -- Direction in degrees
     speed DECIMAL(5, 2), -- Speed in km/h
     accuracy DECIMAL(5, 2), -- GPS accuracy in meters
     updated_at TIMESTAMPTZ DEFAULT NOW()
   );
   
   -- Index for fast queries
   CREATE INDEX idx_driver_locations_driver_order 
   ON driver_locations(driver_id, order_id);
   
   -- Real-time publication
   ALTER PUBLICATION supabase_realtime 
   ADD TABLE driver_locations;
   ```

2. Add RLS policies:
   ```sql
   -- Customers can only see their order's driver location
   CREATE POLICY "Customers see their driver location"
   ON driver_locations FOR SELECT
   USING (
     order_id IN (
       SELECT id FROM orders WHERE user_id = auth.uid()
     )
   );
   
   -- Drivers can only update their own location
   CREATE POLICY "Drivers update own location"
   ON driver_locations FOR INSERT
   WITH CHECK (driver_id = auth.uid());
   ```

3. Create driver location update Edge Function:
   - File: `supabase/functions/update-driver-location/index.ts`
   - Called by driver app to update location every 10 seconds
   - Validates driver is assigned to active order

**Acceptance Criteria:**
- [x] Table created and published to realtime
- [x] RLS policies tested and working
- [x] Can insert/query driver locations

---

##### **Task 1.2: Flutter - Integrate Realtime Driver Location** (6 hours)
**Files to modify:**
- `lib/core/services/realtime_service.dart`
- `lib/features/order/presentation/screens/order_tracking_screen.dart`
- `lib/features/order/providers/order_tracking_provider.dart`

**Steps:**

1. **Update RealtimeService** (`realtime_service.dart`):
   ```dart
   Stream<Map<String, dynamic>> subscribeToDriverLocation(String orderId) {
     final channel = _client.channel('driver-location-$orderId');
     
     return channel
       .onPostgresChanges(
         event: PostgresChangeEvent.insert,
         schema: 'public',
         table: 'driver_locations',
         filter: PostgresChangeFilter(
           type: PostgresChangeFilterType.eq,
           column: 'order_id',
           value: orderId,
         ),
       )
       .subscribe()
       .map((payload) => payload.newRecord);
   }
   ```

2. **Create OrderTrackingProvider** (`order_tracking_provider.dart`):
   ```dart
   class OrderTrackingNotifier extends StateNotifier<OrderTrackingState> {
     final RealtimeService _realtimeService;
     StreamSubscription? _locationSubscription;
     
     Future<void> startTracking(String orderId) async {
       _locationSubscription = _realtimeService
         .subscribeToDriverLocation(orderId)
         .listen((location) {
           state = state.copyWith(
             driverLocation: LatLng(
               location['latitude'],
               location['longitude'],
             ),
             driverHeading: location['heading'],
             lastUpdateTime: DateTime.now(),
           );
         });
     }
     
     @override
     void dispose() {
       _locationSubscription?.cancel();
       super.dispose();
     }
   }
   ```

3. **Update OrderTrackingScreen** (modify existing):
   - Add `flutter_map` with two markers:
     - Customer delivery address (static)
     - Driver current location (real-time)
   - Add polyline showing route
   - Add animated driver marker with rotation based on heading
   - Add ETA calculation based on distance and speed

**Code Addition:**
```dart
// In order_tracking_screen.dart build method
FlutterMap(
  options: MapOptions(
    initialCenter: state.driverLocation ?? state.deliveryLocation,
    initialZoom: 15,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    MarkerLayer(
      markers: [
        // Customer location marker
        Marker(
          point: state.deliveryLocation,
          width: 40,
          height: 40,
          child: Icon(Icons.home, color: Colors.green, size: 40),
        ),
        // Driver location marker (real-time)
        if (state.driverLocation != null)
          Marker(
            point: state.driverLocation!,
            width: 40,
            height: 40,
            rotate: true,
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: state.driverHeading * (pi / 180), // Convert to radians
              child: Icon(Icons.motorcycle, color: Colors.blue, size: 40),
            ),
          ),
      ],
    ),
    // Polyline showing route (optional - requires routing API)
    if (state.routePolyline != null)
      PolylineLayer(
        polylines: [
          Polyline(
            points: state.routePolyline!,
            color: Colors.blue,
            strokeWidth: 4,
          ),
        ],
      ),
  ],
)
```

**Acceptance Criteria:**
- [x] Driver location updates on map in real-time (every 10 seconds)
- [x] Map auto-centers on driver when location updates
- [x] Driver marker rotates based on heading
- [x] Both customer and driver markers visible
- [x] Smooth animations on marker updates

---

##### **Task 1.3: Driver Info Display** (3 hours)
**Files to modify:**
- `lib/features/order/presentation/screens/order_tracking_screen.dart`
- `lib/shared/models/driver.dart` (create if not exists)
- `lib/features/order/providers/order_tracking_provider.dart`

**Steps:**
1. Fetch driver profile from order:
   - Join orders table with profiles on `driver_id`
   - Get driver name, photo, phone, rating

2. Add driver info card to OrderTrackingScreen:
   ```dart
   Card(
     child: ListTile(
       leading: CircleAvatar(
         backgroundImage: NetworkImage(driver.photoUrl ?? defaultAvatar),
       ),
       title: Text(driver.fullName),
       subtitle: Text('⭐ ${driver.rating.toStringAsFixed(1)} • ${driver.completedDeliveries} deliveries'),
       trailing: IconButton(
         icon: Icon(Icons.phone),
         onPressed: () => _callDriver(driver.phone),
       ),
     ),
   )
   ```

3. Add call/message driver functionality:
   - Use `url_launcher` to open phone dialer
   - Use SMS intent for messaging

**Acceptance Criteria:**
- [x] Driver name, photo, and rating displayed
- [x] Tap phone icon to call driver
- [x] Driver info updates if driver changes

---

##### **Task 1.4: ETA Calculation** (2 hours)
**Files to modify:**
- `lib/features/order/providers/order_tracking_provider.dart`
- `lib/features/order/presentation/screens/order_tracking_screen.dart`

**Steps:**
1. Calculate distance between driver and customer using Haversine formula
2. Estimate time based on:
   - Current distance
   - Average delivery speed (30 km/h)
   - Add buffer (5-10 minutes)
3. Display ETA prominently:
   ```dart
   Text(
     'Arriving in ${state.eta} minutes',
     style: Theme.of(context).textTheme.headlineMedium,
   )
   ```

**Acceptance Criteria:**
- [x] ETA displayed and updates in real-time
- [x] ETA accounts for current driver speed
- [x] ETA shows "Less than 1 minute" when very close

---

##### **Task 1.5: Testing** (3 hours)
**Test scenarios:**
1. Order placed → driver location starts updating
2. Driver moves → map updates smoothly
3. Network interruption → reconnects and resumes
4. Order delivered → location tracking stops
5. Multiple orders → correct driver tracked

**Create test file:**
- `test/integration/real_time_tracking_flow_test.dart`

**Acceptance Criteria:**
- [x] All test scenarios pass
- [x] No memory leaks (subscriptions cleaned up)
- [x] Graceful error handling

---

### **PRIORITY 2: Push Notifications** 🔴 CRITICAL
**Impact:** HIGH - Essential for customer engagement  
**Effort:** 12-16 hours  
**Timeline:** 2-3 days

#### Current State (60% complete)
- ✅ Firebase Cloud Messaging setup
- ✅ `NotificationService` exists
- ✅ Local notification display works
- ✅ Permission requests implemented
- ❌ No backend triggers for order events
- ❌ Notification handlers incomplete

#### Implementation Tasks

##### **Task 2.1: Firebase Setup Completion** (2 hours)
**Steps:**
1. Run `flutterfire configure` to generate proper `firebase_options.dart`
2. Add Firebase credentials to `.env`:
   ```env
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_MESSAGING_SENDER_ID=your-sender-id
   ```
3. Configure Android `google-services.json`
4. Configure iOS APNs certificates
5. Test FCM token generation

**Files to verify:**
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

**Acceptance Criteria:**
- [x] FCM tokens generated successfully
- [x] Test notification received on device
- [x] Firebase console shows active device

---

##### **Task 2.2: Backend - Supabase Edge Functions** (6 hours)
**Create notification triggers for order events**

**Files to create:**
- `supabase/functions/send-order-notification/index.ts`
- `supabase/migrations/20250115_add_notification_triggers.sql`

**Step 1: Store FCM tokens** (SQL migration):
```sql
-- Add FCM token to profiles
ALTER TABLE profiles 
ADD COLUMN fcm_token TEXT,
ADD COLUMN fcm_token_updated_at TIMESTAMPTZ;

-- Create notification log table
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  notification_type TEXT NOT NULL,
  title TEXT,
  body TEXT,
  data JSONB,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'sent' -- sent, failed, clicked
);
```

**Step 2: Create Edge Function** (TypeScript):
```typescript
// supabase/functions/send-order-notification/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { orderId, status, userId } = await req.json();
  
  // Fetch user's FCM token
  const { data: profile } = await supabaseAdmin
    .from('profiles')
    .select('fcm_token')
    .eq('id', userId)
    .single();
  
  if (!profile?.fcm_token) {
    return new Response('No FCM token', { status: 400 });
  }
  
  // Prepare notification based on order status
  const notifications = {
    'placed': {
      title: '🎉 Order Placed!',
      body: 'Your order has been placed successfully.',
    },
    'accepted': {
      title: '✅ Order Accepted',
      body: 'The restaurant is preparing your food.',
    },
    'preparing': {
      title: '👨‍🍳 Cooking in Progress',
      body: 'Your delicious meal is being prepared.',
    },
    'ready': {
      title: '📦 Order Ready',
      body: 'Your order is ready for pickup by driver.',
    },
    'out_for_delivery': {
      title: '🚗 On the Way!',
      body: 'Your driver is heading to you now.',
    },
    'delivered': {
      title: '✅ Delivered!',
      body: 'Enjoy your meal! Please rate your experience.',
    },
  };
  
  const notification = notifications[status];
  
  // Send via Firebase Admin SDK
  const message = {
    token: profile.fcm_token,
    notification: {
      title: notification.title,
      body: notification.body,
    },
    data: {
      orderId,
      status,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
      route: '/order/tracking',
    },
  };
  
  await admin.messaging().send(message);
  
  // Log notification
  await supabaseAdmin.from('notification_logs').insert({
    user_id: userId,
    notification_type: 'order_status',
    title: notification.title,
    body: notification.body,
    data: { orderId, status },
  });
  
  return new Response('Notification sent', { status: 200 });
});
```

**Step 3: Database triggers** (SQL):
```sql
-- Trigger function to send notification on order status change
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function asynchronously
  PERFORM net.http_post(
    url := 'https://your-project.supabase.co/functions/v1/send-order-notification',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.service_role_key') || '"}'::jsonb,
    body := json_build_object(
      'orderId', NEW.id,
      'status', NEW.status,
      'userId', NEW.user_id
    )::jsonb
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger to orders table
CREATE TRIGGER on_order_status_change
AFTER UPDATE OF status ON orders
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION notify_order_status_change();
```

**Acceptance Criteria:**
- [x] FCM tokens stored in database
- [x] Edge Function deployed and accessible
- [x] Database trigger fires on status change
- [x] Notifications sent successfully

---

##### **Task 2.3: Flutter - Notification Handling** (4 hours)
**Files to modify:**
- `lib/core/services/notification_service.dart`
- `lib/main.dart`

**Steps:**

1. **Update NotificationService** to handle FCM:
```dart
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  Future<void> initialize() async {
    // Request permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveFcmToken(token);
    }
    
    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveFcmToken);
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }
  
  Future<void> _saveFcmToken(String token) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      await supabase.from('profiles').update({
        'fcm_token': token,
        'fcm_token_updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    _flutterLocalNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'order_updates',
          'Order Updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: json.encode(message.data),
    );
  }
  
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data['route'] != null) {
      // Navigate to specific screen
      navigatorKey.currentState?.pushNamed(
        data['route'],
        arguments: {'orderId': data['orderId']},
      );
    }
  }
}

// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background notification (optional processing)
}
```

2. **Update main.dart** initialization:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(MyApp());
}
```

**Acceptance Criteria:**
- [x] FCM token saved to database on login
- [x] Foreground notifications display
- [x] Background notifications work
- [x] Tapping notification navigates to order tracking
- [x] Token refreshes automatically

---

##### **Task 2.4: Testing** (2 hours)
**Test scenarios:**
1. Place order → receive "Order Placed" notification
2. Restaurant accepts → receive "Order Accepted" notification
3. Order out for delivery → receive notification with driver info
4. Tap notification → app opens to order tracking screen
5. Multiple notifications → all display correctly

**Manual testing steps:**
1. Use Firebase Console to send test notification
2. Change order status in Supabase → verify notification arrives
3. Test with app in foreground, background, and closed
4. Test on both Android and iOS

**Acceptance Criteria:**
- [x] All order status notifications working
- [x] Notifications display in all app states
- [x] Navigation from notification works

---

### **PRIORITY 3: Interactive Map Discovery** 🟡 MEDIUM
**Impact:** MEDIUM - Nice-to-have for discovery  
**Effort:** 8-10 hours  
**Timeline:** 1-2 days

#### Current State (50% complete)
- ✅ Map widget exists on home screen
- ✅ User location marked
- ❌ Restaurant pins not showing
- ❌ Tap pin to view restaurant incomplete

#### Implementation Tasks

##### **Task 3.1: Add Restaurant Pins to Map** (4 hours)
**Files to modify:**
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/home/providers/restaurant_provider.dart`

**Steps:**

1. **Fetch restaurants in viewport**:
```dart
// In restaurant_provider.dart
Future<List<Restaurant>> getRestaurantsInBounds({
  required LatLng northEast,
  required LatLng southWest,
}) async {
  final response = await _database.client
    .from('restaurants')
    .select()
    .gte('latitude', southWest.latitude)
    .lte('latitude', northEast.latitude)
    .gte('longitude', southWest.longitude)
    .lte('longitude', northEast.longitude)
    .eq('is_active', true);
  
  return (response as List)
    .map((json) => Restaurant.fromJson(json))
    .toList();
}
```

2. **Add markers to map**:
```dart
// In home_screen.dart
MarkerLayer(
  markers: state.restaurants.map((restaurant) {
    return Marker(
      point: LatLng(restaurant.latitude, restaurant.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () => _showRestaurantPreview(restaurant),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pin background
            Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
            // Restaurant logo (small)
            Positioned(
              top: 8,
              child: CircleAvatar(
                radius: 8,
                backgroundImage: NetworkImage(restaurant.logoUrl ?? ''),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }).toList(),
)
```

3. **Update markers when map moves**:
```dart
MapOptions(
  onPositionChanged: (position, hasGesture) {
    if (hasGesture) {
      final bounds = _mapController.bounds;
      ref.read(restaurantProvider.notifier).loadRestaurantsInBounds(
        northEast: bounds.northEast,
        southWest: bounds.southWest,
      );
    }
  },
)
```

**Acceptance Criteria:**
- [x] Restaurant pins appear on map
- [x] Pins show restaurant logo
- [x] Pins update when map is panned
- [x] Pin density limited (max 50 pins)

---

##### **Task 3.2: Restaurant Preview Card** (3 hours)
**Files to modify:**
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/shared/widgets/restaurant_preview_card.dart` (create)

**Steps:**

1. **Create RestaurantPreviewCard widget**:
```dart
class RestaurantPreviewCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Restaurant image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: restaurant.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 12),
                // Restaurant info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${restaurant.rating}'),
                          Text(' • '),
                          Text('${restaurant.deliveryTime} min'),
                          Text(' • '),
                          Text('R${restaurant.deliveryFee}'),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        restaurant.cuisineTypes.join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

2. **Show preview on pin tap**:
```dart
void _showRestaurantPreview(Restaurant restaurant) {
  setState(() {
    _selectedRestaurant = restaurant;
  });
}

// In build method
if (_selectedRestaurant != null)
  RestaurantPreviewCard(
    restaurant: _selectedRestaurant!,
    onTap: () {
      context.push('/restaurant/${_selectedRestaurant!.id}');
    },
  ),
```

**Acceptance Criteria:**
- [x] Preview card slides up from bottom
- [x] Shows restaurant photo, name, rating, delivery time
- [x] Tap card to navigate to restaurant detail
- [x] Dismiss by tapping map or another pin

---

##### **Task 3.3: Map Clustering** (2 hours)
**Prevent pin overlap in dense areas**

**Package to add:**
```yaml
dependencies:
  flutter_map_marker_cluster: ^1.3.0
```

**Implementation:**
```dart
MarkerClusterLayerWidget(
  options: MarkerClusterLayerOptions(
    maxClusterRadius: 120,
    size: Size(40, 40),
    markers: _buildRestaurantMarkers(),
    builder: (context, markers) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            markers.length.toString(),
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  ),
)
```

**Acceptance Criteria:**
- [x] Nearby restaurants cluster into single marker
- [x] Cluster shows count
- [x] Zoom in to expand clusters
- [x] Individual pins appear at high zoom

---

##### **Task 3.4: Testing** (1 hour)
**Test scenarios:**
1. Pan map → new restaurants load
2. Tap restaurant pin → preview appears
3. Tap preview → navigates to restaurant
4. Dense area → pins cluster
5. Zoom controls work

**Acceptance Criteria:**
- [x] Smooth performance with 100+ restaurants
- [x] No memory leaks
- [x] Graceful error handling

---

### **PRIORITY 4: Profile Enhancements** 🟢 LOW
**Impact:** LOW - Nice-to-have improvements  
**Effort:** 6-8 hours  
**Timeline:** 1 day

#### Implementation Tasks

##### **Task 4.1: Avatar Upload** (3 hours)
**Files to modify:**
- `lib/features/profile/presentation/screens/profile_screen.dart`
- `lib/features/profile/providers/profile_provider.dart`

**Steps:**

1. **Add avatar upload UI**:
```dart
GestureDetector(
  onTap: _pickAndUploadAvatar,
  child: Stack(
    children: [
      CircleAvatar(
        radius: 50,
        backgroundImage: state.profile.avatarUrl != null
          ? NetworkImage(state.profile.avatarUrl!)
          : null,
        child: state.profile.avatarUrl == null
          ? Icon(Icons.person, size: 50)
          : null,
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
        ),
      ),
    ],
  ),
)
```

2. **Implement upload**:
```dart
Future<void> _pickAndUploadAvatar() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 512,
    maxHeight: 512,
    imageQuality: 85,
  );
  
  if (image == null) return;
  
  setState(() => _isUploading = true);
  
  try {
    // Upload to Supabase Storage
    final userId = supabase.auth.currentUser!.id;
    final fileName = 'avatar_$userId.jpg';
    final bytes = await image.readAsBytes();
    
    await supabase.storage
      .from('avatars')
      .uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(upsert: true),
      );
    
    // Get public URL
    final url = supabase.storage
      .from('avatars')
      .getPublicUrl(fileName);
    
    // Update profile
    await ref.read(profileProvider.notifier).updateAvatar(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile photo updated!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload photo')),
    );
  } finally {
    setState(() => _isUploading = false);
  }
}
```

3. **Create storage bucket** (Supabase dashboard):
   - Bucket name: `avatars`
   - Public: Yes
   - File size limit: 2MB
   - Allowed MIME types: `image/jpeg,image/png`

**Acceptance Criteria:**
- [x] Tap avatar to open image picker
- [x] Photo uploads to Supabase Storage
- [x] Profile updates with new avatar URL
- [x] Avatar displays across app

---

##### **Task 4.2: Review Photo Upload** (3 hours)
**Files to modify:**
- `lib/features/restaurant/presentation/screens/write_review_screen.dart`
- `lib/shared/models/review.dart`

**Steps:**

1. **Add photo picker to review screen**:
```dart
GridView.builder(
  shrinkWrap: true,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
  ),
  itemCount: _selectedImages.length + 1,
  itemBuilder: (context, index) {
    if (index == _selectedImages.length) {
      // Add photo button
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add_photo_alternate, size: 40),
        ),
      );
    }
    
    // Selected image
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(_selectedImages[index], fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => _removeImage(index),
          ),
        ),
      ],
    );
  },
)
```

2. **Upload photos with review**:
```dart
Future<void> _submitReview() async {
  final imageUrls = <String>[];
  
  // Upload photos first
  for (var i = 0; i < _selectedImages.length; i++) {
    final file = _selectedImages[i];
    final fileName = 'review_${uuid.v4()}.jpg';
    final bytes = await file.readAsBytes();
    
    await supabase.storage
      .from('review-photos')
      .uploadBinary(fileName, bytes);
    
    final url = supabase.storage
      .from('review-photos')
      .getPublicUrl(fileName);
    
    imageUrls.add(url);
  }
  
  // Submit review with photo URLs
  await ref.read(reviewProvider.notifier).submitReview(
    restaurantId: widget.restaurantId,
    rating: _rating,
    comment: _commentController.text,
    photoUrls: imageUrls,
  );
}
```

3. **Update database** (migration):
```sql
ALTER TABLE reviews
ADD COLUMN photo_urls TEXT[];
```

**Acceptance Criteria:**
- [x] Can select up to 5 photos
- [x] Photos upload before review submission
- [x] Photos display in review list
- [x] Tap photo to view full-screen

---

##### **Task 4.3: Change Password** (2 hours)
**Files to create:**
- `lib/features/profile/presentation/screens/change_password_screen.dart`

**Steps:**

1. **Create change password screen**:
```dart
class ChangePasswordScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      // Verify current password by attempting to sign in
      final email = supabase.auth.currentUser!.email!;
      await supabase.auth.signInWithPassword(
        email: email,
        password: _currentPasswordController.text,
      );
      
      // Update to new password
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );
      
      Navigator.pop(context);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current password is incorrect')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change password')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _currentPasswordController,
              decoration: InputDecoration(labelText: 'Current Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter current password';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
              validator: (value) {
                if (value == null || value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
              validator: (value) {
                if (value != _newPasswordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
```

2. **Add navigation from settings**:
```dart
ListTile(
  leading: Icon(Icons.lock),
  title: Text('Change Password'),
  trailing: Icon(Icons.chevron_right),
  onTap: () => context.push('/profile/change-password'),
)
```

**Acceptance Criteria:**
- [x] Validates current password
- [x] Validates new password strength
- [x] Confirms password match
- [x] Updates password successfully
- [x] Shows appropriate error messages

---

### **PRIORITY 5: Advanced Features** ⚪ FUTURE
**Impact:** MEDIUM - Long-term engagement  
**Effort:** 40-60 hours  
**Timeline:** 1-2 weeks

#### Features for Future Implementation

##### **5.1 Favorite Restaurants** (4 hours)
- Add favorite button to restaurant cards
- Create favorites table in database
- Add "My Favorites" section to profile
- Filter home screen to show favorites

##### **5.2 Schedule Orders** (8 hours)
- Add "Schedule for later" option in checkout
- Time picker for delivery slot
- Store scheduled orders in database
- Background job to process scheduled orders

##### **5.3 Order Cancellation with Refund** (6 hours)
- Add cancel button to order tracking
- Cancellation policy logic (time-based)
- Integrate PayFast refund API
- Update order status to "cancelled"

##### **5.4 Help Center / FAQ** (6 hours)
- Create help articles in database
- Search functionality for help
- Category-based browsing
- Contact support form

##### **5.5 Loyalty Program** (20 hours)
- Points calculation system
- Points balance display
- Redeem points for discounts
- Points history
- Tier system (Bronze, Silver, Gold)

##### **5.6 Social Sharing** (4 hours)
- Share restaurant via social media
- Share favorite dishes
- Invite friends for discount
- Referral tracking

##### **5.7 Advanced Filters** (8 hours)
- Dietary filters (Vegan, Gluten-Free, Halal)
- Cuisine filters with multi-select
- Price range slider
- Distance radius slider
- Sort by multiple criteria

---

## 📅 Implementation Timeline

### **Week 1: Real-Time Features**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon | Priority 1 Task 1.1: Backend driver tracking setup | 4 |
| Tue | Priority 1 Task 1.2: Flutter realtime integration | 6 |
| Wed | Priority 1 Tasks 1.3-1.4: Driver info + ETA | 5 |
| Thu | Priority 1 Task 1.5: Testing | 3 |
| Fri | Priority 2 Task 2.1: Firebase setup | 2 |
| **Total** | **Priority 1 complete, Priority 2 started** | **20h** |

### **Week 2: Notifications + Map**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon | Priority 2 Task 2.2: Supabase Edge Functions | 6 |
| Tue | Priority 2 Tasks 2.3-2.4: Flutter handling + testing | 6 |
| Wed | Priority 3 Task 3.1: Restaurant pins on map | 4 |
| Thu | Priority 3 Tasks 3.2-3.3: Preview cards + clustering | 5 |
| Fri | Priority 3 Task 3.4: Testing | 1 |
| **Total** | **Priorities 2-3 complete** | **22h** |

### **Week 3: Profile + Polish**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon | Priority 4 Tasks 4.1-4.2: Avatar + review photos | 6 |
| Tue | Priority 4 Task 4.3: Change password | 2 |
| Wed-Fri | Bug fixes, polish, integration testing | 12 |
| **Total** | **All priorities complete** | **20h** |

### **Week 4: QA + Deployment Prep**
| Day | Tasks | Hours |
|-----|-------|-------|
| Mon-Tue | Full app manual QA | 8 |
| Wed-Thu | Performance optimization | 8 |
| Fri | Production deployment preparation | 4 |
| **Total** | **Production ready** | **20h** |

---

## ✅ Acceptance Criteria (Overall)

### **Definition of Done**
All priorities 1-4 must meet these criteria:

#### **Functional Requirements**
- [x] All features work as specified
- [x] Error handling for all edge cases
- [x] Offline mode graceful degradation
- [x] Real-time features reconnect after network loss

#### **Performance Requirements**
- [x] App launches in <3 seconds
- [x] Map loads and pans smoothly (60 FPS)
- [x] Notifications arrive within 5 seconds of event
- [x] Image uploads complete in <10 seconds

#### **Quality Requirements**
- [x] Zero lint errors
- [x] All new code has unit tests
- [x] Integration tests for critical flows
- [x] No memory leaks (verified with DevTools)

#### **User Experience Requirements**
- [x] Loading states for all async operations
- [x] Error messages are user-friendly
- [x] Animations are smooth and subtle
- [x] Dark mode works across all new features

#### **Security Requirements**
- [x] RLS policies tested and working
- [x] No sensitive data in client-side logs
- [x] FCM tokens securely stored
- [x] Location data privacy respected

---

## 🎯 Success Metrics

### **Post-Implementation Tracking**

#### **User Engagement**
- **Target:** 30% increase in order completion rate
- **Measure:** Orders placed vs orders delivered
- **Reason:** Better tracking reduces anxiety

#### **Customer Satisfaction**
- **Target:** 4.5+ average rating
- **Measure:** In-app ratings and reviews
- **Reason:** Real-time tracking improves experience

#### **Notification Engagement**
- **Target:** 60% notification open rate
- **Measure:** Firebase Analytics
- **Reason:** Timely notifications drive engagement

#### **Map Usage**
- **Target:** 25% of users discover via map
- **Measure:** Analytics on map pin taps
- **Reason:** Visual discovery is intuitive

#### **Technical Health**
- **Target:** <1% error rate
- **Measure:** Firebase Crashlytics
- **Reason:** Stable features increase trust

---

## 🚧 Known Risks & Mitigations

### **Risk 1: Real-Time Scaling**
**Risk:** Supabase Realtime may struggle with 1000+ concurrent orders  
**Impact:** HIGH  
**Mitigation:**
- Load test with 100+ simultaneous connections
- Implement connection pooling
- Add rate limiting on driver location updates (10s intervals)
- Consider Redis for location caching if needed

### **Risk 2: Notification Delivery Reliability**
**Risk:** FCM notifications may not arrive consistently  
**Impact:** MEDIUM  
**Mitigation:**
- Implement fallback polling (check order status every 30s)
- Add in-app status bar for order updates
- Test across multiple devices and OS versions

### **Risk 3: Map Performance**
**Risk:** 500+ restaurant pins may cause lag  
**Impact:** MEDIUM  
**Mitigation:**
- Implement clustering (already planned)
- Limit pins to 100 max in viewport
- Use marker virtualization
- Debounce map movement events

### **Risk 4: Firebase Configuration Complexity**
**Risk:** Multi-platform Firebase setup may fail  
**Impact:** MEDIUM  
**Mitigation:**
- Use FlutterFire CLI for configuration
- Test on both Android and iOS early
- Document all setup steps
- Keep backup of all config files

---

## 📚 Documentation Requirements

### **For Developers**

#### **Create/Update Documentation**
1. **README.md** - Add real-time tracking setup steps
2. **FIREBASE_SETUP.md** - Complete Firebase configuration guide
3. **SUPABASE_SETUP.md** - Update with new tables and functions
4. **TESTING_GUIDE.md** - How to test real-time features locally

#### **Code Documentation**
- Add JSDoc/DartDoc comments to all new services
- Document complex algorithms (ETA calculation, clustering)
- Add examples to provider usage

### **For QA Testing**

#### **Create Test Plans**
1. **REAL_TIME_TESTING.md** - How to test driver tracking
2. **NOTIFICATION_TESTING.md** - How to test all notification types
3. **MAP_TESTING.md** - How to test map features

#### **Create Test Data**
- SQL script to create test restaurants with locations
- SQL script to create test orders in various states
- Instructions for simulating driver movement

---

## 🔄 Rollout Strategy

### **Phase 1: Internal Testing** (Week 3)
- **Audience:** Development team (5 users)
- **Features:** All Priority 1-4 features
- **Goals:** 
  - Verify all features work
  - Identify critical bugs
  - Performance baseline

### **Phase 2: Beta Testing** (Week 4)
- **Audience:** 20-50 beta testers
- **Features:** All Priority 1-4 features
- **Goals:**
  - Real-world usage patterns
  - Stress test real-time features
  - Collect user feedback

### **Phase 3: Soft Launch** (Week 5)
- **Audience:** 10% of user base
- **Features:** All Priority 1-3 features (hold Priority 4 as fallback)
- **Goals:**
  - Monitor error rates
  - Verify notification delivery
  - Check Supabase usage/costs

### **Phase 4: Full Launch** (Week 6)
- **Audience:** 100% of user base
- **Features:** All Priority 1-4 features
- **Goals:**
  - Scale to full traffic
  - Monitor metrics
  - Collect satisfaction data

---

## 💰 Cost Considerations

### **Supabase Usage Increases**

#### **Realtime Connections**
- **Current Plan:** Likely Free Tier (500MB bandwidth)
- **Estimated Usage:** 
  - 100 concurrent orders = 100 Realtime connections
  - Driver location updates (10s intervals) = ~6 KB/min per order
  - Daily: ~8.6 GB for 1000 orders
- **Recommendation:** Monitor and upgrade to Pro ($25/month) if needed

#### **Edge Function Invocations**
- **Notifications per order:** ~6 notifications (status changes)
- **1000 orders/day:** 6,000 invocations
- **Current Plan:** Free tier includes 500K invocations
- **Cost:** Stay on free tier

#### **Storage**
- **Avatars:** 500 KB average × 10,000 users = 5 GB
- **Review photos:** 300 KB average × 5,000 reviews × 3 photos = 4.5 GB
- **Current Plan:** Free tier includes 1 GB
- **Recommendation:** Upgrade storage ($0.021/GB/month) ≈ $0.20/month

### **Firebase Costs**

#### **Cloud Messaging**
- **Free:** Unlimited notifications
- **Cost:** $0

#### **Crashlytics & Analytics**
- **Free:** Unlimited events
- **Cost:** $0

### **Total Monthly Increase**
- **Supabase Pro (if needed):** $25
- **Additional storage:** ~$0.20
- **Firebase:** $0
- **Total:** ~$25/month

---

## 📱 Testing Checklist

### **Before Marking Complete**

#### **Real-Time Tracking**
- [ ] Driver location updates on map every 10 seconds
- [ ] Map auto-centers on driver
- [ ] Driver marker rotates based on heading
- [ ] ETA updates dynamically
- [ ] Driver info displays correctly
- [ ] Call driver button works
- [ ] Connection resilient to network interruptions
- [ ] Subscription cleans up on screen exit
- [ ] Works on both Android and iOS
- [ ] No memory leaks (DevTools profiler)

#### **Push Notifications**
- [ ] "Order Placed" notification sent
- [ ] "Order Accepted" notification sent
- [ ] "Preparing" notification sent
- [ ] "Out for Delivery" notification sent
- [ ] "Delivered" notification sent
- [ ] Notifications arrive in foreground
- [ ] Notifications arrive in background
- [ ] Notifications arrive when app closed
- [ ] Tap notification navigates to tracking
- [ ] FCM token saved to database
- [ ] Works on both Android and iOS

#### **Map Discovery**
- [ ] Restaurant pins appear on map
- [ ] Pins show restaurant logos
- [ ] Pins update when map pans
- [ ] Tap pin shows preview card
- [ ] Preview card displays correct info
- [ ] Tap preview navigates to restaurant
- [ ] Clustering works in dense areas
- [ ] Smooth performance with 100+ pins
- [ ] Works on both Android and iOS

#### **Profile Features**
- [ ] Avatar upload works
- [ ] Avatar displays across app
- [ ] Review photo upload works (up to 5)
- [ ] Review photos display in list
- [ ] Tap photo shows full-screen
- [ ] Change password validates current password
- [ ] Change password updates successfully
- [ ] Change password shows errors appropriately
- [ ] Works on both Android and iOS

---

## 🎉 Summary

This plan provides a **clear, actionable roadmap** to complete the NandyFood customer experience. By following this 4-week plan, you'll deliver:

✅ **Real-time driver tracking** - Industry-standard feature  
✅ **Push notifications** - Essential for engagement  
✅ **Interactive map discovery** - Enhanced UX  
✅ **Profile enhancements** - Better personalization  

**Total Investment:**
- **Time:** 82-104 hours (~3-4 weeks)
- **Cost:** ~$25/month ongoing
- **Result:** Competitive, modern food delivery app

**Next Steps:**
1. Review and approve this plan
2. Set up development environment (Firebase, Supabase configs)
3. Start with Priority 1: Real-Time Tracking
4. Test thoroughly at each priority milestone
5. Roll out gradually to mitigate risks

---

**Document Version:** 1.0  
**Last Updated:** January 2025  
**Maintained By:** Development Team  
**Questions?** Contact: [Your Contact Info]
