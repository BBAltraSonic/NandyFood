# Phase 2 Remaining Tasks Roadmap
## Weeks 5-7: Complete Implementation Guide

**Created:** 2025-10-12  
**Current Progress:** 55% Overall (Phase 2: 25%)  
**Remaining:** 10 major task groups  

---

## 🎯 Overview

This document provides a comprehensive roadmap for completing Phase 2 of the NandyFood project. All tasks are organized by week and priority, with detailed implementation guides.

---

## ✅ Completed Tasks (Days 21-24)

- ✅ **Week 5, Day 21-22:** Firebase Cloud Messaging Setup
- ✅ **Week 5, Day 23-24:** Live Order Tracking

---

## 📋 Remaining Tasks

### 🚗 Week 5, Day 25-26: Driver Location Tracking

**Priority:** HIGH  
**Estimated Time:** 2-3 days  
**Dependencies:** Firebase & Realtime Service (✅ Complete)

#### Features to Implement

**1. Live Driver Location on Map**
- File: `lib/features/order/presentation/widgets/live_tracking_map.dart`
- Subscribe to driver location updates via Supabase Realtime
- Display driver marker with custom icon
- Show user delivery location marker
- Display route polyline from driver to user
- Animated marker movement (smooth transitions)
- Auto-zoom to fit both markers

**2. Driver Information Display**
- File: `lib/features/order/presentation/widgets/driver_info_card.dart`
- Show driver name and photo
- Display vehicle type and number
- Show driver rating (stars)
- "Call Driver" button with phone integration
- "Message Driver" button
- Display driver's current distance from user

**3. ETA Calculation**
- File: `lib/core/services/delivery_tracking_service.dart`
- Calculate estimated time of arrival
- Update ETA in real-time based on driver location
- Account for traffic conditions (via routing API)
- Display ETA prominently
- Show ETA countdown timer

#### Implementation Steps
1. Create `driver_location_provider.dart`
2. Subscribe to `driver_locations` table in Supabase
3. Create map widget with `flutter_map` package
4. Implement marker animation
5. Add ETA calculation service
6. Create driver info card widget
7. Integrate phone dialing (`url_launcher`)
8. Test real-time location updates

#### Acceptance Criteria
- [ ] Driver location updates every 10-30 seconds
- [ ] Smooth marker animation without jumps
- [ ] Accurate ETA calculation (within 5 minutes)
- [ ] Contact driver functionality works
- [ ] Map auto-centers and zooms appropriately

---

### ⚠️ Week 5, Day 27: Order Actions & Edge Cases

**Priority:** HIGH  
**Estimated Time:** 1 day  
**Dependencies:** Order Tracking (✅ Complete)

#### Features to Implement

**1. Cancel Order Functionality**
- File: `lib/features/order/presentation/widgets/cancel_order_dialog.dart`
- "Cancel Order" button (only before preparation)
- Confirmation dialog with cancellation policy
- Cancellation reasons selection
- Process refund if payment made
- Update order status to "cancelled"
- Send cancellation notification

**2. Modify Order Functionality**
- "Add Items" button (only before preparation)
- Allow adding items to existing order
- Recalculate total and update payment
- Show updated order summary
- Notify restaurant of changes

**3. Order Issues Handling**
- "Report Issue" button
- Issue types: Wrong items, Missing items, Quality issue, Delivery delay
- Issue reporting form
- Send issue to support system
- Track issue resolution

**4. Edge Cases**
- Handle GPS permission denied
- Handle location services disabled
- Handle network disconnection during tracking
- Handle order stuck in status (timeout warnings)
- Handle driver location not available

#### Implementation Steps
1. Create cancel order dialog
2. Implement cancellation logic in provider
3. Create modify order screen
4. Add issue reporting form
5. Implement edge case handlers
6. Add user-friendly error messages
7. Test all scenarios

#### Acceptance Criteria
- [ ] Cancel order works before preparation starts
- [ ] Add items functionality updates order correctly
- [ ] Issue reporting submits successfully
- [ ] All edge cases handled with helpful messages
- [ ] No crashes on permission denial or network loss

---

### ⭐ Week 6, Day 28-29: Reviews & Ratings System

**Priority:** MEDIUM  
**Estimated Time:** 2 days  
**Dependencies:** Order History

#### Features to Implement

**1. Restaurant Reviews**
- File: `lib/features/restaurant/presentation/screens/write_review_screen.dart`
- Review submission form
- Star rating selector (1-5 stars)
- Text review field (10-500 chars)
- Photo upload option
- Review validation
- Submit to database

**2. Order Rating Flow**
- File: `lib/features/order/presentation/widgets/rate_order_dialog.dart`
- Rating dialog after order completion
- Rate food quality (1-5 stars)
- Rate delivery experience (1-5 stars)
- Optional text feedback
- Rate driver separately
- Submit ratings

**3. Review Display Enhancement**
- Update existing reviews section
- Show user's own review at top
- "Helpful" button with counter
- "Report" button
- Review sorting (Recent, Helpful, Rating)
- Filter by rating
- Verified purchase badge

**4. Rating Analytics**
- Calculate overall restaurant rating
- Update rating after each review
- Track rating trends
- Show rating distribution

#### Database Schema
```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  restaurant_id UUID REFERENCES restaurants(id),
  order_id UUID REFERENCES orders(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  food_quality_rating INTEGER,
  delivery_rating INTEGER,
  review_text TEXT,
  photos TEXT[],
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

---

### ❤️ Week 6, Day 30-31: Favorites & Collections

**Priority:** MEDIUM  
**Estimated Time:** 2 days  

#### Features to Implement

**1. Favorite Restaurants**
- File: `lib/features/profile/presentation/providers/favorites_provider.dart`
- Heart icon on restaurant cards
- Add/remove favorite functionality
- Store in `user_favorites` table
- Sync across devices

**2. Favorites Screen**
- File: `lib/features/profile/presentation/screens/favorites_screen.dart`
- Grid/list view of favorites
- Search within favorites
- Sorting options
- Empty state
- "Remove All" option

**3. Favorite Dishes**
- Favorite icon on dish cards
- Favorite dishes list
- Quick reorder from favorites
- Show availability status

**4. Collections (Optional)**
- Create custom collections
- Add restaurants to collections
- Share collections

#### Database Schema
```sql
CREATE TABLE user_favorites (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  restaurant_id UUID REFERENCES restaurants(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, restaurant_id)
);
```

---

### 🛒 Week 6, Day 32-33: Cart Persistence & Smart Features

**Priority:** MEDIUM  
**Estimated Time:** 2 days  

#### Features to Implement

**1. Save Cart for Later**
- File: `lib/features/order/presentation/providers/saved_carts_provider.dart`
- "Save for Later" button
- Store cart items in database
- Load saved carts
- List of saved carts
- Name saved carts
- 7-day expiration

**2. Smart Cart Suggestions**
- Analyze cart contents
- Suggest complementary items
- Suggest drinks with meals
- Suggest sides
- Carousel below cart
- Track conversion rate

**3. Frequently Ordered Items**
- Track order history
- Identify frequent items
- "Your Favorites" section
- Quick reorder
- Show last order date

**4. Bundle Deals**
- Create bundle deals
- Show bundle suggestions
- Apply automatic discounts
- Display savings

---

### 📊 Week 6, Day 34: Analytics & Tracking Setup

**Priority:** HIGH (for production)  
**Estimated Time:** 1 day  

#### Features to Implement

**1. Firebase Analytics Integration**
- File: `lib/core/services/analytics_service.dart`
- Already has Firebase Analytics package
- Define key events
- Implement event logging
- User properties tracking
- Conversion funnels

**2. Key Events to Track**
- App opens and sessions
- Restaurant views
- Menu item views
- Add to cart
- Checkout initiated
- Order placed
- Order completed
- Review submitted
- Search queries
- Filter usage

**3. Performance Monitoring**
- Firebase Performance already added
- Track screen load times
- Track network latency
- Monitor crash rate
- Automatic crash reporting

**4. Custom Analytics Dashboard**
- Admin analytics viewer
- Key metrics (DAU, MAU, Conversion)
- Revenue and GMV tracking
- User retention
- Behavior patterns

---

### 👤 Week 7, Day 35-36: Profile Customization

**Priority:** MEDIUM  
**Estimated Time:** 2 days  

#### Features to Implement

**1. Avatar Upload**
- File: `lib/features/profile/presentation/screens/edit_profile_screen.dart`
- Image picker (camera/gallery)
- Image cropping
- Compress and optimize
- Upload to Supabase Storage
- Update profile with avatar URL

**2. Profile Information Editing**
- Edit full name
- Edit phone (with verification)
- Edit email (with verification)
- Add date of birth
- Add gender
- Add bio

**3. Account Settings**
- Change password
- Biometric authentication
- Link/unlink social accounts
- Two-factor authentication
- Delete account
- Data export (GDPR)

---

### ⚙️ Week 7, Day 37-38: Preferences & Settings

**Priority:** MEDIUM  
**Estimated Time:** 2 days  

#### Features to Implement

**1. Dietary Preferences**
- Dietary restrictions checkboxes
- Cuisine preferences
- Spice level preference
- Portion size preference

**2. Notification Preferences**
- Order updates toggle
- Promotional offers toggle
- New restaurant alerts
- Price drop alerts
- Review reminders
- Newsletter subscription
- Quiet hours

**3. App Settings**
- Theme selection (Light/Dark/System)
- Language selection
- Default delivery address
- Default payment method
- Location tracking
- Background refresh
- Clear cache

**4. Privacy Settings**
- Profile visibility
- Share order history
- Personalized recommendations
- Location tracking
- Marketing opt-in/out

---

### 📜 Week 7, Day 39-40: Order History & Analytics

**Priority:** MEDIUM  
**Estimated Time:** 2 days  

#### Features to Implement

**1. Enhanced Order History**
- Filter by status
- Date range filter
- Restaurant filter
- Search in history
- Sorting options
- Statistics summary

**2. Order Details Enhancement**
- Complete timeline
- Itemized receipt
- Delivery address
- "Reorder" button
- "Rate & Review" button
- Refund status
- Download receipt
- Get help button

**3. Spending Analytics**
- Total spending (month/year)
- Spending by restaurant
- Spending by category
- Timeline chart
- Average order value
- Most ordered items
- Savings from promotions

**4. Loyalty & Rewards**
- Points balance
- Rewards earned
- Available coupons
- Progress to next tier
- Referral bonus status

---

### 🏠 Week 7, Day 41: Addresses Management

**Priority:** HIGH  
**Estimated Time:** 1 day  

#### Features to Implement

**1. Saved Addresses**
- List of saved addresses
- "Add New Address" button
- Address cards with details
- Default address badge
- Edit and delete options

**2. Add/Edit Address Form**
- Use current location button
- Search with autocomplete
- Select on map
- Label (Home/Work/Other)
- Apartment/unit number
- Delivery instructions
- Contact number
- Validate format

**3. Address Features**
- Set/change default
- Mark favorites
- Show recent addresses
- Detect duplicates
- Address verification

---

## 📊 Implementation Priority Matrix

### Critical Path (Must Complete)
1. ✅ Firebase Setup (Day 21-22)
2. ✅ Live Order Tracking (Day 23-24)
3. 🔴 Driver Location Tracking (Day 25-26)
4. 🔴 Order Actions & Edge Cases (Day 27)
5. 🔴 Analytics Setup (Day 34)

### High Priority (Production Ready)
6. 🟡 Reviews & Ratings (Day 28-29)
7. 🟡 Favorites (Day 30-31)
8. 🟡 Profile Customization (Day 35-36)
9. 🟡 Addresses Management (Day 41)

### Medium Priority (Enhanced Experience)
10. 🟢 Cart Persistence (Day 32-33)
11. 🟢 Preferences & Settings (Day 37-38)
12. 🟢 Order History Enhancement (Day 39-40)

---

## 🛠️ Quick Start Guide

### For Each Task

**1. Create Feature Branch**
```bash
git checkout -b feature/phase2-week[X]-day[Y]-[feature-name]
```

**2. Review Checklist**
- Read task details in `IMPLEMENTATION_CHECKLIST_PHASE2.md`
- Check dependencies
- Review acceptance criteria

**3. Implement**
- Create necessary files
- Write tests
- Update documentation

**4. Test**
```bash
flutter analyze
flutter test
flutter run
```

**5. Commit & Push**
```bash
git add -A
git commit -m "feat: Implement [feature name]"
git push origin feature/phase2-week[X]-day[Y]-[feature-name]
```

**6. Create Pull Request**
- Document changes
- Include screenshots
- Mark acceptance criteria

---

## 📈 Progress Tracking

Update after completing each task:

- [x] Week 5, Day 21-22 (✅ Complete)
- [x] Week 5, Day 23-24 (✅ Complete)
- [ ] Week 5, Day 25-26
- [ ] Week 5, Day 27
- [ ] Week 6, Day 28-29
- [ ] Week 6, Day 30-31
- [ ] Week 6, Day 32-33
- [ ] Week 6, Day 34
- [ ] Week 7, Day 35-36
- [ ] Week 7, Day 37-38
- [ ] Week 7, Day 39-40
- [ ] Week 7, Day 41

**Current:** 2/12 tasks complete (17%)  
**Target:** 12/12 tasks complete (100%)

---

## 🎯 Success Metrics

### Technical
- [ ] All features implemented per spec
- [ ] 80%+ test coverage maintained
- [ ] No critical bugs
- [ ] Performance targets met
- [ ] All acceptance criteria satisfied

### User Experience
- [ ] Smooth 60fps animations
- [ ] < 3 second load times
- [ ] Intuitive navigation
- [ ] Clear error messages
- [ ] Responsive feedback

### Business
- [ ] Feature parity with competitors
- [ ] Analytics tracking complete
- [ ] User engagement features ready
- [ ] Retention mechanisms in place

---

## 📚 Resources

### Documentation
- [IMPLEMENTATION_CHECKLIST_PHASE2.md](../IMPLEMENTATION_CHECKLIST_PHASE2.md)
- [PHASE2_PROGRESS.md](./PHASE2_PROGRESS.md)
- [PHASE2_WEEK5_COMPLETE_SUMMARY.md](./PHASE2_WEEK5_COMPLETE_SUMMARY.md)

### External
- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev/)

---

## 🚀 Let's Complete Phase 2!

This roadmap provides everything needed to complete Phase 2. Follow the priority order, test thoroughly, and document as you go.

**Next Up:** Week 5, Day 25-26 - Driver Location Tracking

---

**Created:** 2025-10-12  
**Status:** Active Roadmap  
**Owner:** Development Team
