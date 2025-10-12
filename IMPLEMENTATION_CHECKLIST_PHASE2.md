# Phase 2 Implementation Checklist
## Real-Time Features & Backend Enhancement (Weeks 5-7) - Target: 50% → 70%

**Current Status:** 50%  
**Target Status:** 70%  
**Timeline:** 3 Weeks  
**Focus:** Real-Time Order Tracking, Backend Features, Profile Management

---

## 📍 Week 5: Real-Time Order Tracking & Live Updates

### Day 21-22: Firebase Cloud Messaging Setup
- [ ] **FCM Integration**
  - File: `lib/core/services/notification_service.dart`
  - Add `firebase_messaging` package (^14.7.0)
  - Add `firebase_core` package (^2.24.0)
  - Configure Firebase project for Android
  - Configure Firebase project for iOS
  - Add google-services.json (Android)
  - Add GoogleService-Info.plist (iOS)
  - Request notification permissions
  
- [ ] **Local Notifications Setup**
  - File: `lib/core/services/local_notification_service.dart`
  - Configure notification channels (Android)
  - Set notification icons and sounds
  - Implement notification tap handlers
  - Test foreground notifications
  - Test background notifications
  
- [ ] **Supabase Real-Time Setup**
  - Enable real-time in Supabase project settings
  - Configure RLS policies for orders table
  - Configure RLS policies for deliveries table
  - Test real-time subscriptions

**Acceptance Criteria:**
- ✅ FCM tokens generated and stored
- ✅ Notifications received in all app states (foreground/background/terminated)
- ✅ Notification permissions handled gracefully
- ✅ Real-time subscriptions working with Supabase

---

### Day 23-24: Live Order Tracking Implementation
- [ ] **Real-Time Order Status Updates**
  - File: `lib/features/order/presentation/providers/order_tracking_provider.dart`
  - Subscribe to order status changes via Supabase real-time
  - Implement status change listeners
  - Update UI in real-time when status changes
  - Add retry logic for connection failures
  
- [ ] **Visual Status Timeline**
  - File: `lib/features/order/presentation/widgets/order_status_timeline.dart`
  - Create step-by-step visual timeline widget
  - Status stages: Order Placed → Confirmed → Preparing → Ready → Picked Up → On the Way → Delivered
  - Add checkmark icons for completed stages
  - Add loading spinner for current stage
  - Implement smooth transitions between stages
  - Show timestamp for each completed stage
  
- [ ] **Order Status Notifications**
  - Send push notification on order confirmation
  - Send notification when order is being prepared
  - Send notification when driver picks up order
  - Send notification when driver is nearby (< 1 km)
  - Send notification on delivery completion
  - Add notification sound and vibration

**Acceptance Criteria:**
- ✅ Status updates appear instantly (< 2 seconds)
- ✅ Timeline UI updates smoothly without flickering
- ✅ Notifications sent at appropriate status changes
- ✅ Connection resilience (auto-reconnect on failure)

---

### Day 25-26: Driver Location Tracking
- [ ] **Live Driver Location on Map**
  - File: `lib/features/order/presentation/widgets/live_tracking_map.dart`
  - Subscribe to driver location updates (Supabase real-time)
  - Display driver marker on map with custom icon
  - Add animated marker movement (smooth transitions)
  - Show user delivery location marker
  - Display route polyline from driver to user
  - Implement auto-zoom to fit both markers
  
- [ ] **Driver Information Display**
  - File: `lib/features/order/presentation/widgets/driver_info_card.dart`
  - Show driver name and photo
  - Display vehicle type and number
  - Show driver rating (stars)
  - Add "Call Driver" button with phone integration
  - Add "Message Driver" button (in-app chat or SMS)
  - Display driver's current distance from user
  
- [ ] **ETA Calculation**
  - File: `lib/core/services/delivery_tracking_service.dart`
  - Calculate estimated time of arrival
  - Update ETA in real-time based on driver location
  - Account for traffic conditions (via routing API)
  - Display ETA prominently on tracking screen
  - Show ETA countdown timer

**Acceptance Criteria:**
- ✅ Driver location updates every 10-30 seconds
- ✅ Smooth marker animation without jumps
- ✅ Accurate ETA calculation (within 5 minutes)
- ✅ Contact driver functionality works
- ✅ Map auto-centers and zooms appropriately

---

### Day 27: Order Actions & Edge Cases
- [ ] **Cancel Order Functionality**
  - File: `lib/features/order/presentation/widgets/cancel_order_dialog.dart`
  - Add "Cancel Order" button (only before preparation)
  - Show confirmation dialog with cancellation policy
  - Implement cancellation reasons selection
  - Process refund if payment made
  - Update order status to "cancelled"
  - Send cancellation notification
  
- [ ] **Modify Order Functionality**
  - Add "Add Items" button (only before preparation)
  - Allow adding items to existing order
  - Recalculate total and update payment
  - Show updated order summary
  - Notify restaurant of changes
  
- [ ] **Order Issues Handling**
  - Add "Report Issue" button
  - Issue types: Wrong items, Missing items, Quality issue, Delivery delay
  - Show issue reporting form
  - Send issue to support system
  - Track issue resolution
  
- [ ] **Edge Cases**
  - Handle GPS permission denied
  - Handle location services disabled
  - Handle network disconnection during tracking
  - Handle order stuck in status (timeout warnings)
  - Handle driver location not available

**Acceptance Criteria:**
- ✅ Cancel order works before preparation starts
- ✅ Add items functionality updates order correctly
- ✅ Issue reporting submits successfully
- ✅ All edge cases handled with helpful messages
- ✅ No crashes on permission denial or network loss

**Week 5 Deliverable:** ✅ Live order tracking matching Uber Eats/DoorDash experience

---

## 🔧 Week 6: Backend Enhancement & User Engagement

### Day 28-29: Reviews & Ratings System
- [ ] **Restaurant Reviews**
  - File: `lib/features/restaurant/presentation/screens/write_review_screen.dart`
  - Create review submission form
  - Add star rating selector (1-5 stars)
  - Add text review field (min 10 chars, max 500 chars)
  - Add photo upload option (optional)
  - Implement review validation
  - Submit review to database
  
- [ ] **Order Rating Flow**
  - File: `lib/features/order/presentation/widgets/rate_order_dialog.dart`
  - Show rating dialog after order completion
  - Rate food quality (1-5 stars)
  - Rate delivery experience (1-5 stars)
  - Add optional text feedback
  - Rate driver (separate from restaurant)
  - Submit ratings to database
  
- [ ] **Review Display Enhancement**
  - Update `lib/features/restaurant/presentation/widgets/reviews_section.dart`
  - Show user's own review at top
  - Add "Helpful" button with counter
  - Add "Report" button for inappropriate reviews
  - Implement review sorting (Most Recent, Most Helpful, Highest/Lowest Rating)
  - Add review filters by rating
  - Show verified purchase badge
  
- [ ] **Rating Analytics**
  - Calculate overall restaurant rating
  - Update rating after each review
  - Track rating trends over time
  - Show rating distribution (5 stars: X%, 4 stars: Y%, etc.)

**Acceptance Criteria:**
- ✅ Reviews submit successfully with validation
- ✅ Photos upload and display correctly
- ✅ Ratings update restaurant score in real-time
- ✅ Review moderation flags inappropriate content
- ✅ Users can edit/delete their own reviews

---

### Day 30-31: Favorites & Collections
- [ ] **Favorite Restaurants**
  - File: `lib/features/profile/presentation/providers/favorites_provider.dart`
  - Add heart icon to restaurant cards
  - Implement add/remove favorite functionality
  - Store favorites in database (user_favorites table)
  - Show favorites count on profile
  - Sync favorites across devices
  
- [ ] **Favorites Screen**
  - File: `lib/features/profile/presentation/screens/favorites_screen.dart`
  - Create dedicated favorites list screen
  - Display favorite restaurants in grid/list view
  - Add search within favorites
  - Add sorting options (Recently added, Most ordered, Alphabetical)
  - Show empty state with suggestion to explore
  - Add "Remove All" option with confirmation
  
- [ ] **Favorite Dishes**
  - Add favorite icon to dish cards
  - Create favorite dishes list
  - Quick reorder from favorites
  - Show dish availability status
  
- [ ] **Collections (Optional)**
  - Create custom collections ("Date Night", "Quick Lunch", etc.)
  - Add restaurants to collections
  - Share collections with friends

**Acceptance Criteria:**
- ✅ Favorites sync instantly across devices
- ✅ Heart icon state updates immediately
- ✅ Favorites persist after logout/login
- ✅ Can manage favorites easily (add/remove)
- ✅ Empty state provides clear next action

---

### Day 32-33: Cart Persistence & Smart Features
- [ ] **Save Cart for Later**
  - File: `lib/features/order/presentation/providers/saved_carts_provider.dart`
  - Add "Save for Later" button in cart
  - Store cart items in database
  - Load saved carts on app launch
  - Show list of saved carts
  - Allow naming saved carts
  - Set cart expiration (7 days)
  
- [ ] **Smart Cart Suggestions**
  - File: `lib/core/services/recommendation_service.dart`
  - Analyze cart contents
  - Suggest complementary items ("People also bought...")
  - Suggest drinks with meals
  - Suggest sides with main courses
  - Show suggestions as carousel below cart
  - Track suggestion conversion rate
  
- [ ] **Frequently Ordered Items**
  - Track user's order history
  - Identify frequently ordered items
  - Show "Your Favorites" section on home
  - Enable quick reorder with one tap
  - Show last order date for each item
  
- [ ] **Bundle Deals**
  - Create bundle deals in database
  - Show bundle suggestions in cart
  - Apply automatic discounts for bundles
  - Display savings prominently

**Acceptance Criteria:**
- ✅ Saved carts persist and load correctly
- ✅ Smart suggestions are relevant and helpful
- ✅ Quick reorder works seamlessly
- ✅ Bundle deals apply automatically
- ✅ Expiration removes old saved carts

---

### Day 34: Analytics & Tracking Setup
- [ ] **Analytics Integration**
  - File: `lib/core/services/analytics_service.dart`
  - Add Firebase Analytics (or equivalent)
  - Define key events to track
  - Implement event logging
  - Add user properties tracking
  - Set up conversion funnels
  
- [ ] **Key Events to Track**
  - App opens and sessions
  - Restaurant views
  - Menu item views
  - Add to cart events
  - Checkout initiated
  - Order placed
  - Order completed
  - Review submitted
  - Search queries
  - Filter usage
  
- [ ] **Performance Monitoring**
  - Add Firebase Performance Monitoring
  - Track screen load times
  - Track network request latency
  - Monitor app crash rate
  - Set up automatic crash reporting
  
- [ ] **Custom Analytics Dashboard**
  - Create admin analytics viewer
  - Show key metrics (DAU, MAU, Conversion rate)
  - Track revenue and GMV
  - Monitor user retention
  - Analyze user behavior patterns

**Acceptance Criteria:**
- ✅ All key events tracked accurately
- ✅ Analytics data flows to dashboard
- ✅ Performance metrics monitored
- ✅ Crash reports actionable
- ✅ Privacy compliance maintained

**Week 6 Deliverable:** ✅ Robust backend supporting engagement and retention

---

## 👤 Week 7: Profile Management & User Preferences

### Day 35-36: Profile Customization
- [ ] **Avatar Upload & Management**
  - File: `lib/features/profile/presentation/screens/edit_profile_screen.dart`
  - Add profile photo upload button
  - Implement image picker (camera or gallery)
  - Add image cropping functionality
  - Compress and optimize image before upload
  - Upload to Supabase Storage
  - Update user profile with avatar URL
  - Show placeholder for users without avatar
  
- [ ] **Profile Information Editing**
  - Edit full name
  - Edit phone number (with verification)
  - Edit email (with verification)
  - Add date of birth
  - Add gender (optional)
  - Add bio (optional, max 150 chars)
  - Save changes with validation
  - Show loading state during save
  
- [ ] **Account Settings**
  - File: `lib/features/profile/presentation/screens/account_settings_screen.dart`
  - Change password
  - Enable/disable biometric authentication
  - Link/unlink social accounts (Google, Apple)
  - Two-factor authentication toggle
  - Delete account option (with confirmation)
  - Data export option (GDPR compliance)

**Acceptance Criteria:**
- ✅ Avatar uploads and displays correctly
- ✅ Profile updates save successfully
- ✅ Phone/email verification works
- ✅ Account security options functional
- ✅ Delete account works with proper warnings

---

### Day 37-38: Preferences & Settings
- [ ] **Dietary Preferences**
  - File: `lib/features/profile/presentation/screens/dietary_preferences_screen.dart`
  - Add dietary restrictions checkboxes (Vegetarian, Vegan, Gluten-Free, Dairy-Free, Nut Allergy, Halal, Kosher, etc.)
  - Add cuisine preferences (multi-select)
  - Add spice level preference
  - Add portion size preference
  - Store preferences in user profile
  - Use preferences for personalized recommendations
  
- [ ] **Notification Preferences**
  - File: `lib/features/profile/presentation/screens/notification_settings_screen.dart`
  - Order updates toggle
  - Promotional offers toggle
  - New restaurant alerts toggle
  - Price drop alerts toggle
  - Review reminders toggle
  - Newsletter subscription toggle
  - Set quiet hours (no notifications during sleep)
  - Choose notification sound
  
- [ ] **App Settings**
  - File: `lib/features/profile/presentation/screens/app_settings_screen.dart`
  - Theme selection (Light, Dark, System)
  - Language selection
  - Default delivery address
  - Default payment method
  - Location tracking permission
  - Background app refresh toggle
  - Clear cache option
  
- [ ] **Privacy Settings**
  - Profile visibility (Public, Friends, Private)
  - Share order history (Yes/No)
  - Personalized recommendations (Yes/No)
  - Location tracking (Always, While Using, Never)
  - Marketing communications opt-in/out

**Acceptance Criteria:**
- ✅ All preferences save and apply correctly
- ✅ Notification settings work as expected
- ✅ Theme changes apply immediately
- ✅ Privacy settings respected throughout app
- ✅ Settings sync across devices

---

### Day 39-40: Order History & Analytics
- [ ] **Enhanced Order History**
  - File: `lib/features/profile/presentation/screens/order_history_screen.dart`
  - Add filtering by status (Completed, Cancelled, Refunded)
  - Add date range filter
  - Add restaurant filter
  - Add search in order history
  - Add sorting options (Recent, Oldest, Total Amount)
  - Show order statistics summary
  
- [ ] **Order Details Enhancement**
  - File: `lib/features/order/presentation/screens/order_detail_screen.dart`
  - Show complete order timeline
  - Display itemized receipt
  - Show delivery address and instructions
  - Add "Reorder" button
  - Add "Rate & Review" button (if not rated)
  - Show refund status (if applicable)
  - Add "Download Receipt" option
  - Add "Get Help" button for issues
  
- [ ] **Spending Analytics**
  - File: `lib/features/profile/presentation/screens/spending_analytics_screen.dart`
  - Show total spending this month/year
  - Display spending by restaurant
  - Show spending by category
  - Create spending timeline chart
  - Show average order value
  - Display most ordered items
  - Show savings from promotions
  
- [ ] **Loyalty & Rewards Display**
  - Show points balance
  - Display rewards earned
  - Show available coupons
  - Track progress to next reward tier
  - Display referral bonus status

**Acceptance Criteria:**
- ✅ Order history filters work correctly
- ✅ Analytics display accurate data
- ✅ Reorder functionality works seamlessly
- ✅ Receipt download generates PDF
- ✅ Charts render smoothly with data

---

### Day 41: Addresses Management
- [ ] **Saved Addresses**
  - File: `lib/features/profile/presentation/screens/addresses_screen.dart`
  - Display list of saved addresses
  - Add "Add New Address" button
  - Show address cards with details
  - Mark default address with badge
  - Add edit and delete options
  
- [ ] **Add/Edit Address Form**
  - File: `lib/features/profile/presentation/widgets/address_form.dart`
  - Use current location button
  - Search address with autocomplete
  - Select location on map
  - Add label (Home, Work, Other)
  - Add apartment/unit number
  - Add delivery instructions
  - Add contact number for this address
  - Validate address format
  
- [ ] **Address Features**
  - Set/change default address
  - Mark favorite addresses
  - Show recent addresses
  - Detect duplicate addresses
  - Address verification via geocoding

**Acceptance Criteria:**
- ✅ Addresses save correctly
- ✅ Map selection works smoothly
- ✅ Autocomplete provides accurate results
- ✅ Default address applies at checkout
- ✅ No duplicate addresses stored

**Week 7 Deliverable:** ✅ Complete profile management and personalization

---

## 📊 Phase 2 Success Metrics

### Feature Completion
- [ ] Real-time order tracking with live driver location ✅
- [ ] Push notifications for order updates ✅
- [ ] Reviews and ratings system ✅
- [ ] Favorites functionality ✅
- [ ] Cart persistence and smart suggestions ✅
- [ ] Complete profile management ✅
- [ ] Analytics and performance monitoring ✅

### Technical Metrics
- [ ] Real-time updates with < 2 second latency
- [ ] Notification delivery rate > 95%
- [ ] Map performance: 60fps with live tracking
- [ ] Phase 2 tests passing (50+ new tests)
- [ ] No critical bugs
- [ ] Code coverage maintained at 80%+

### User Experience
- [ ] Order tracking as good as Uber Eats
- [ ] Instant status updates visible
- [ ] Smooth animations throughout
- [ ] Personalization working (recommendations, preferences)
- [ ] All settings save and apply correctly

---

## 🔧 Required Setup Before Starting

### Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in project
firebase init
```

### Dependencies to Add
```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  firebase_analytics: ^10.7.0
  firebase_performance: ^0.9.3
  firebase_crashlytics: ^3.4.0
  image_picker: ^1.0.4
  image_cropper: ^5.0.0
  fl_chart: ^0.65.0  # For analytics charts
```

### API Keys Needed
- [ ] Firebase project created (iOS + Android)
- [ ] FCM Server Key configured in Supabase
- [ ] Google Maps API key (for routing)
- [ ] Image optimization service (optional)

### Database Setup
- [ ] Enable real-time on orders and deliveries tables
- [ ] Create user_favorites table
- [ ] Create saved_carts table
- [ ] Create reviews table
- [ ] Create notifications table
- [ ] Set up proper RLS policies for new tables

---

## 🚨 Common Issues & Solutions

### Issue 1: FCM Not Receiving Notifications
**Problem:** Push notifications not arriving  
**Solution:** Check FCM token registration, verify server key in Supabase, test with Firebase Console test message

### Issue 2: Real-Time Connection Drops
**Problem:** Supabase real-time disconnects  
**Solution:** Implement reconnection logic, handle network state changes, add heartbeat mechanism

### Issue 3: Driver Location Updates Slow
**Problem:** Map marker moves slowly or jumps  
**Solution:** Use marker animation, interpolate between positions, adjust update frequency

### Issue 4: Image Upload Fails
**Problem:** Avatar upload times out or fails  
**Solution:** Compress images before upload, implement chunked upload for large files, add retry logic

### Issue 5: Analytics Not Tracking
**Problem:** Events not showing in dashboard  
**Solution:** Check Firebase configuration, verify event names match schema, test in debug mode

---

## 📝 Daily Stand-Up Checklist

### Every Morning
- [ ] Pull latest from git
- [ ] Review yesterday's completed tasks
- [ ] Check Firebase/Supabase dashboard for issues
- [ ] Identify today's focus
- [ ] Test real-time features in simulator

### Every Evening
- [ ] Mark completed tasks ✅
- [ ] Commit and push code
- [ ] Run integration tests
- [ ] Test on physical device
- [ ] Monitor analytics for new events
- [ ] Update documentation

---

## 🎉 Phase 2 Completion Criteria

**Ready to move to Phase 3 when:**
1. ✅ All Week 5-7 tasks completed
2. ✅ Real-time tracking works flawlessly
3. ✅ Push notifications reliable (95%+ delivery)
4. ✅ Profile management fully functional
5. ✅ All Phase 2 tests passing (50+ new tests)
6. ✅ No critical bugs
7. ✅ Performance benchmarks met
8. ✅ Analytics tracking all key events

**Upon completion:** Project will be at **70% overall** and ready for Phase 3 (Polish & Optimization)

---

## 📞 Need Help?

### Resources
- [Firebase Documentation](https://firebase.google.com/docs)
- [Supabase Real-Time](https://supabase.com/docs/guides/realtime)
- [Flutter Maps](https://pub.dev/packages/flutter_map)
- [Image Picker](https://pub.dev/packages/image_picker)
- [FL Chart](https://pub.dev/packages/fl_chart)

### Quick References
- Notification Service: `lib/core/services/notification_service.dart`
- Real-Time Service: `lib/core/services/realtime_service.dart`
- Analytics Service: `lib/core/services/analytics_service.dart`
- Order Tracking: `lib/features/order/presentation/providers/order_tracking_provider.dart`

---

**Let's build Phase 2! Start with Firebase setup 🔥**
