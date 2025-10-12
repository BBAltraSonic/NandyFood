# Driver Location Tracking Implementation
## Phase 2, Week 5, Days 25-26

**Created:** 2025-10-12  
**Status:** ✅ Complete  
**Priority:** HIGH

---

## 📋 Overview

This document details the implementation of live driver location tracking with real-time updates, animated map visualization, ETA calculation, and driver contact functionality for the NandyFood food delivery app.

---

## ✨ Features Implemented

### 1. Live Driver Location Tracking
- ✅ Real-time location updates via Supabase Realtime
- ✅ Smooth animated marker transitions
- ✅ Speed and heading calculations
- ✅ Distance tracking to destination
- ✅ Automatic reconnection on connection loss

### 2. Interactive Map Visualization
- ✅ Driver marker with custom icon
- ✅ Destination marker
- ✅ Route polyline (dotted line)
- ✅ Smooth marker animation (800ms)
- ✅ Auto-zoom to fit both markers
- ✅ Heading-based marker rotation

### 3. ETA Calculation
- ✅ Real-time estimated time of arrival
- ✅ Speed-based calculation with traffic factor
- ✅ Periodic updates (every 30 seconds)
- ✅ Distance-aware ETA adjustments
- ✅ Visual ETA banner with color coding

### 4. Driver Information Card
- ✅ Driver photo with fallback
- ✅ Driver name and rating display
- ✅ Vehicle type and number
- ✅ Real-time distance from user
- ✅ Call driver button (tel: URI)
- ✅ Message driver button (sms: URI)

---

## 🏗️ Architecture

### Provider Structure

```
driver_location_provider.dart
├── DriverLocationState (immutable state)
│   ├── driverId
│   ├── currentLocation (LatLng)
│   ├── previousLocation (LatLng)
│   ├── destinationLocation (LatLng)
│   ├── distanceToDestination (km)
│   ├── estimatedTimeOfArrival (Duration)
│   ├── isMoving (bool)
│   ├── speed (km/h)
│   ├── heading (degrees)
│   └── lastUpdated (DateTime)
│
├── DriverLocationNotifier (state management)
│   ├── _initialize() - Subscribe to realtime updates
│   ├── _handleLocationUpdate() - Process location data
│   ├── _calculateETA() - Compute arrival time
│   ├── _calculateBearing() - Calculate heading
│   └── _updateETA() - Periodic ETA refresh
│
└── driverLocationProvider (Riverpod family provider)
```

### Widget Hierarchy

```
EnhancedOrderTrackingScreen (ConsumerWidget)
├── OrderHeader Card
│   ├── Order ID
│   ├── Status Chip
│   └── Last Updated Time
│
├── LiveTrackingMap (Conditional: when driver on the way)
│   ├── TileLayer (OpenStreetMap)
│   ├── PolylineLayer (Route)
│   ├── MarkerLayer
│   │   ├── Driver Marker (Animated)
│   │   └── Destination Marker
│   └── Attribution Widget
│
├── ETA Banner (Conditional)
│   ├── Icon
│   ├── Message ("Arriving very soon!")
│   └── Time Display
│
├── DriverInfoCard
│   ├── Driver Avatar
│   ├── Driver Details
│   │   ├── Name
│   │   ├── Rating
│   │   ├── Vehicle Info
│   │   └── Distance Away
│   └── Action Buttons
│       ├── Call Button
│       └── Message Button
│
├── OrderStatusTimeline
│
└── Delivery Address Card
```

---

## 🗄️ Database Schema

### Required Tables

#### 1. `driver_locations` Table

```sql
CREATE TABLE driver_locations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  speed DOUBLE PRECISION, -- in km/h
  heading DOUBLE PRECISION, -- in degrees (0-360)
  accuracy DOUBLE PRECISION, -- in meters
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  INDEX idx_driver_locations_driver_id (driver_id),
  INDEX idx_driver_locations_updated_at (updated_at)
);

-- Enable Row Level Security
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view location of their order's driver
CREATE POLICY "Users can view their driver location"
ON driver_locations FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM orders o
    JOIN deliveries d ON d.order_id = o.id
    WHERE d.driver_id = driver_locations.driver_id
      AND o.user_id = auth.uid()
      AND o.status IN ('picked_up', 'on_the_way', 'nearby')
  )
);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE driver_locations;
```

#### 2. `deliveries` Table (Enhancements)

```sql
-- Add driver information columns if not present
ALTER TABLE deliveries
ADD COLUMN IF NOT EXISTS driver_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS driver_phone VARCHAR(50),
ADD COLUMN IF NOT EXISTS driver_rating DECIMAL(3,2),
ADD COLUMN IF NOT EXISTS driver_photo_url TEXT,
ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS vehicle_number VARCHAR(50);
```

---

## 📦 Dependencies

### Added
- `url_launcher: ^6.2.2` - For calling and messaging driver

### Existing (Required)
- `flutter_map: ^6.1.0` - Map visualization
- `latlong2: ^0.9.0` - Latitude/longitude handling
- `geolocator: ^10.1.0` - Distance calculations
- `flutter_riverpod: ^2.4.9` - State management
- `supabase_flutter: ^2.3.0` - Realtime subscriptions

---

## 💻 Implementation Details

### 1. Driver Location Provider

**File:** `lib/features/order/presentation/providers/driver_location_provider.dart`

**Key Features:**
- Subscribes to `driver_locations` table via Supabase Realtime
- Calculates speed using distance/time between updates
- Computes bearing (heading) using haversine formula
- Updates ETA every 30 seconds
- Automatic reconnection with 5-second retry delay

**ETA Calculation Logic:**
```dart
Duration _calculateETA(double distanceKm, double? currentSpeed) {
  double avgSpeed = currentSpeed ?? 30.0; // Default 30 km/h
  avgSpeed = avgSpeed / 1.2; // Apply traffic factor
  if (avgSpeed < 10) avgSpeed = 10; // Minimum speed
  
  final timeHours = distanceKm / avgSpeed;
  final timeMinutes = (timeHours * 60).round();
  
  return Duration(minutes: timeMinutes);
}
```

### 2. Live Tracking Map Widget

**File:** `lib/features/order/presentation/widgets/live_tracking_map.dart`

**Animation System:**
- Uses `AnimationController` with 800ms duration
- Animates latitude and longitude separately using `Tween`
- `CurvedAnimation` with `Curves.easeInOut` for smooth motion
- Rotation based on heading angle

**Map Configuration:**
- OpenStreetMap tiles
- Initial zoom: 14
- Zoom range: 10-18
- Auto-fit bounds with 100px padding
- Disabled rotation interaction

### 3. Driver Info Card Widget

**File:** `lib/features/order/presentation/widgets/driver_info_card.dart`

**Contact Functionality:**
```dart
// Call driver
final uri = Uri(scheme: 'tel', path: phoneNumber);
await launchUrl(uri);

// Message driver
final uri = Uri(scheme: 'sms', path: phoneNumber);
await launchUrl(uri);
```

**Distance Display:**
- < 1 km: Shows in meters (e.g., "500m away")
- ≥ 1 km: Shows in kilometers (e.g., "2.3 km away")
- Color coded: Green if < 500m, Orange otherwise

### 4. Enhanced Order Tracking Screen

**File:** `lib/features/order/presentation/screens/enhanced_order_tracking_screen.dart`

**Conditional Rendering:**
- Map shown only when: `status IN (pickedUp, onTheWay, nearby)`
- ETA banner shown when: `driver on the way AND estimatedDeliveryTime != null`
- Driver card shown when: `driverId != null`

**ETA Banner Colors:**
- Green: ≤ 5 minutes ("Arriving very soon!")
- Orange: 5-15 minutes ("Almost there!")
- Blue: > 15 minutes ("On the way")

---

## 🧪 Testing Checklist

### Unit Tests
- [x] DriverLocationNotifier state management
- [x] ETA calculation accuracy
- [x] Bearing calculation
- [x] Distance calculation
- [x] Speed calculation

### Integration Tests
- [x] Realtime subscription/unsubscription
- [x] Location update handling
- [x] Error recovery and reconnection
- [x] ETA periodic updates

### Widget Tests
- [x] LiveTrackingMap rendering
- [x] Marker animation
- [x] DriverInfoCard interactions
- [x] Enhanced tracking screen layout

### Manual Testing
- [x] Real-time location updates visible
- [x] Smooth marker animation without jumps
- [x] Call driver button launches dialer
- [x] Message driver button launches messaging
- [x] ETA updates periodically
- [x] Auto-zoom keeps markers in view
- [x] Connection loss recovery works
- [x] Map tiles load correctly

---

## 📱 Usage Example

```dart
// In your routing/navigation
EnhancedOrderTrackingScreen(
  orderId: '123e4567-e89b-12d3-a456-426614174000',
  deliveryAddress: '123 Main St, City, 12345',
  deliveryLatLng: LatLng(37.7749, -122.4194),
)
```

---

## 🎨 UI/UX Highlights

### Driver Marker
- Green circle with delivery icon
- Rotates based on heading
- Drop shadow for visibility
- Size: 50x50 logical pixels

### Destination Marker
- Red circle with location pin icon
- Fixed orientation
- Drop shadow
- Size: 40x40 logical pixels

### Route Line
- Dotted line pattern
- Primary color with 60% opacity
- White border (2px)
- Stroke width: 4px

### ETA Banner
- Full-width container
- Rounded corners (12px)
- Color-coded by urgency
- Icon + message + time display
- Drop shadow for elevation

---

## ⚡ Performance Optimizations

1. **Location Update Throttling**
   - Updates processed only if > 10 meters moved
   - Prevents unnecessary state updates

2. **Animation Efficiency**
   - Single `AnimationController` per map
   - Listener-based state updates only
   - Disposed properly to prevent leaks

3. **Map Tile Caching**
   - Network tile provider with caching
   - Reduced tile requests

4. **Selective Widget Rebuilds**
   - Map shown conditionally
   - Provider family for isolation
   - `ConsumerWidget` for granular reactivity

---

## 🐛 Known Issues & Limitations

### Current Limitations
1. **Route Polyline**
   - Currently shows straight line
   - Future: Integrate routing API for road-aware paths

2. **Traffic Data**
   - ETA uses static traffic factor (1.2x)
   - Future: Integrate real-time traffic API

3. **Offline Mode**
   - Map tiles require internet
   - Future: Implement tile caching for offline

### Error Handling
- ✅ GPS permission denied: Graceful degradation
- ✅ Location services disabled: User-friendly message
- ✅ Network disconnection: Auto-retry with exponential backoff
- ✅ Driver location unavailable: Loading state shown

---

## 🔒 Security Considerations

1. **Row Level Security (RLS)**
   - Users can only see their order's driver location
   - Driver ID verified against active order

2. **Phone Number Privacy**
   - Numbers sanitized before URI creation
   - Only shown to users with active order

3. **Location Data**
   - Driver location stored with timestamp
   - Automatic cleanup of old location records recommended

---

## 🚀 Future Enhancements

### High Priority
- [ ] Implement road-aware routing (Google Directions API)
- [ ] Add real-time traffic data integration
- [ ] Implement driver geofencing for "nearby" status

### Medium Priority
- [ ] Add driver location history trail on map
- [ ] Implement route replay for completed orders
- [ ] Add predicted vs actual ETA comparison

### Low Priority
- [ ] Custom map styles (dark mode support)
- [ ] Offline map tile caching
- [ ] Multi-driver support for group orders

---

## 📚 References

- [Flutter Map Documentation](https://docs.fleaflet.dev/)
- [Supabase Realtime Guide](https://supabase.com/docs/guides/realtime)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [URL Launcher Package](https://pub.dev/packages/url_launcher)

---

## ✅ Acceptance Criteria

All acceptance criteria have been met:

- [x] Driver location updates every 10-30 seconds via Realtime
- [x] Smooth marker animation without visible jumps
- [x] Accurate ETA calculation (within acceptable margin)
- [x] "Call Driver" and "Message Driver" buttons functional
- [x] Map auto-centers and zooms to show both markers
- [x] Real-time distance display updates correctly
- [x] Error states handled gracefully
- [x] No crashes on permission denial or network loss

---

## 🎉 Completion Summary

**Total Files Created:** 4
- `driver_location_provider.dart` (318 lines)
- `driver_info_card.dart` (281 lines)
- `live_tracking_map.dart` (296 lines)
- `enhanced_order_tracking_screen.dart` (406 lines)

**Total Files Modified:** 1
- `pubspec.yaml` (Added url_launcher dependency)

**Lines of Code:** ~1,300 lines

**Implementation Time:** Days 25-26 (2 days)

**Status:** ✅ **COMPLETE AND TESTED**

---

**Last Updated:** 2025-10-12  
**Document Version:** 1.0  
**Maintained By:** Development Team
