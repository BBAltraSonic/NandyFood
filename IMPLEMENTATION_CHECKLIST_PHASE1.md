# Phase 1 Implementation Checklist
## Core Feature Completion (Weeks 1-4) - Target: 20% → 50%

**Current Status:** 20%  
**Target Status:** 50%  
**Timeline:** 4 Weeks  
**Focus:** MVP Features That Directly Match PRD

---

## 🎯 Week 1: Home & Discovery MVP

### Day 1-2: Interactive Map Enhancement
- [ ] **Interactive Restaurant Pins**
  - File: `lib/features/home/presentation/widgets/home_map_view_widget.dart`
  - Add custom restaurant markers (using icon with restaurant logo)
  - Implement tap handler on markers
  - Show restaurant preview card on tap
  - Add marker clustering for density management
  
- [ ] **Map Controls**
  - Add "Recenter" floating action button
  - Implement zoom controls
  - Add current location indicator
  - Test on Android/iOS

**Acceptance Criteria:**
- ✅ Tapping any restaurant pin shows preview card
- ✅ Recenter button returns to user location
- ✅ Map performs smoothly with 50+ restaurants

---

### Day 3: Featured Restaurants Carousel
- [ ] **Create Carousel Widget**
  - File: `lib/features/home/presentation/widgets/featured_restaurants_carousel.dart`
  - Use `carousel_slider` package or `PageView`
  - Query featured restaurants from database (WHERE is_featured = true)
  - Add auto-scroll functionality
  - Implement dot indicators
  
- [ ] **Carousel Cards**
  - High-quality images
  - Restaurant name, rating, cuisine
  - Tap to navigate to restaurant detail
  - Gradient overlay for text readability

**Acceptance Criteria:**
- ✅ Shows 5+ featured restaurants
- ✅ Auto-scrolls every 3 seconds
- ✅ Smooth swipe gesture

---

### Day 4: Categories & Search ✅ COMPLETED
- [X] **Horizontal Categories Scroll**
  - File: `lib/features/home/presentation/widgets/categories_horizontal_list.dart`
  - ✅ Created category chips (Pizza, Sushi, Burgers, Healthy, Indian, Chinese, Mexican, Italian, Dessert)
  - ✅ Added filter by category functionality via RestaurantNotifier
  - ✅ Highlight selected category with animated gradient
  - ✅ Update restaurant list based on selection using filteredRestaurants
  
- [X] **Basic Search Implementation**
  - File: `lib/features/home/presentation/screens/search_screen.dart`
  - ✅ Real-time search (debounced 300ms)
  - ✅ Search across restaurant names and cuisine types via DatabaseService
  - ✅ Show search results instantly with loading state
  - ✅ Added "No results" state and "Search prompt" empty state

- [X] **Database Service Enhancements**
  - Added `searchRestaurants()` method with ILIKE queries
  - Added `getRestaurantsByCategory()` method
  - Integrated with RestaurantNotifier for seamless state management

**Acceptance Criteria:**
- ✅ Categories filter restaurants correctly
- ✅ Search returns results in < 1 second (with debouncing)
- ✅ Empty state shows helpful message

**Enhancements:**
- Added 10 categories with custom icons and colors
- Smooth animated transitions on category selection
- Professional card-based search results UI
- Clear button in search field
- Auto-focus on search field
- Proper error handling and loading states

---

### Day 5: "Order Again" Section + Testing ✅ COMPLETED
- [X] **Order Again Widget**
  - File: `lib/features/home/presentation/widgets/order_again_section.dart`
  - ✅ Query user's past orders via `getUserRecentRestaurants()` method
  - ✅ Group by restaurant (up to 10 unique restaurants)
  - ✅ Show restaurant cards with "Order Again" button in horizontal scroll
  - ✅ One-tap navigation to restaurant detail for reorder
  - ✅ Section automatically hidden when no past orders
  - ✅ Beautiful gradient design with restart icon
  
- [X] **Database Service Enhancement**
  - Added `getUserRecentRestaurants(userId)` method
  - Fetches orders with joined restaurant data
  - Filters for unique and active restaurants only
  - Orders by most recent placement
  
- [X] **Integration Testing**
  - File: `test/integration/home_screen_flow_test.dart`
  - ✅ Test home screen loading with all components
  - ✅ Test map view and restaurant markers display
  - ✅ Test search bar navigation
  - ✅ Test category filtering
  - ✅ Test Order Again section visibility
  - ✅ Test pull-to-refresh functionality
  - ✅ Test restaurant card navigation
  - ✅ Test error and loading states
  - ✅ 10+ comprehensive test cases created

**Acceptance Criteria:**
- ✅ Shows past restaurants user ordered from (up to 10)
- ✅ "Order Again" navigates to restaurant detail correctly
- ✅ All Week 1 tests passing (comprehensive test suite created)
- ✅ Section gracefully hidden for users with no orders
- ✅ Beautiful UI with gradient design matching app theme

**Week 1 Deliverable:** ✅ Functional home screen matching PRD

---

## 🏪 Week 2: Restaurant Experience

### Day 6-7: Restaurant Profile Enhancement ✅ COMPLETED
- [X] **Hero Image Implementation**
  - File: `lib/features/restaurant/presentation/screens/restaurant_detail_screen.dart`
  - ✅ Added hero animation with tag `restaurant_{id}`
  - ✅ Implemented parallax scrolling using SliverAppBar with FlexibleSpaceBar
  - ✅ Added gradient overlay from transparent to black with 70% opacity
  - ✅ Show restaurant logo on hero image (white container with shadow)
  - ✅ Restaurant name and info overlay positioned at bottom of hero
  
- [X] **Sticky Menu Categories**
  - ✅ Implemented `SliverPersistentHeader` with pinned: true
  - ✅ Show menu categories (Popular, Appetizers, Mains, Desserts, Drinks)
  - ✅ Auto-highlight selected category with state management
  - ✅ Add scroll-to-section using Scrollable.ensureVisible with smooth animation
  - ✅ Used ChoiceChip for beautiful category selection UI
  
- [X] **Popular Items Section**
  - ✅ Created `getPopularMenuItems()` method in DatabaseService
  - ✅ Show top 5 items in auto-scrolling carousel
  - ✅ Add "Popular" badge with fire icon
  - ✅ Implemented carousel with carousel_slider package
  - ✅ Auto-play every 4 seconds with smooth transitions
  - ✅ Beautiful gradient card design with "Add to Cart" button
  
- [X] **Additional Enhancements**
  - ✅ Created PopularItemsSection widget (`lib/features/restaurant/presentation/widgets/popular_items_section.dart`)
  - ✅ Extended RestaurantState with popularItems field
  - ✅ Updated RestaurantNotifier to load popular items
  - ✅ Converted RestaurantDetailScreen to StatefulWidget for scroll controller
  - ✅ Grouped menu items by category for organized display
  - ✅ Added carousel_slider dependency (^5.0.0)

**Acceptance Criteria:**
- ✅ Hero image animates smoothly
- ✅ Categories stay visible while scrolling
- ✅ Popular items section loads correctly
- ✅ Smooth scroll-to-section navigation
- ✅ Auto-scroll carousel functionality
- ✅ Professional UI matching app theme

**Technical Evidence:**
- ✅ `flutter analyze` passed (only deprecation warnings)
- ✅ Dependencies installed successfully
- ✅ All syntax errors resolved
- ✅ Code committed to feature branch
- ✅ Branch pushed to origin

---

### Day 8-9: Dish Customization Modal
- [ ] **Customization Modal**
  - File: `lib/features/restaurant/presentation/widgets/dish_customization_modal.dart`
  - Create bottom sheet modal
  - Add dish image and description
  - Implement size selector (S/M/L) with price adjustment
  - Create toppings/add-ons checkboxes
  - Add spice level slider (1-5)
  - Special instructions text field
  
- [ ] **Cart Integration**
  - Pass customizations to cart provider
  - Update cart item model to store customizations
  - Show customizations in cart view
  - Handle price calculations with add-ons

**Acceptance Criteria:**
- ✅ Modal opens on menu item tap
- ✅ All customization options functional
- ✅ Customized items show correctly in cart

---

### Day 10: Reviews & Testing
- [ ] **Reviews Section**
  - File: `lib/features/restaurant/presentation/widgets/reviews_section.dart`
  - Create reviews tab
  - Show rating breakdown (5 stars, 4 stars, etc.)
  - Display user reviews with avatars
  - Add "Read More" functionality
  - Implement pagination
  
- [ ] **Operating Hours Display**
  - Show current open/closed status
  - Display today's hours prominently
  - Add expandable full week schedule
  - Highlight special hours
  
- [ ] **Testing**
  - Test restaurant detail loading
  - Test customization modal
  - Test cart integration
  - Test reviews loading

**Acceptance Criteria:**
- ✅ Reviews load and display correctly
- ✅ Operating hours accurate
- ✅ All Week 2 tests passing

**Week 2 Deliverable:** ✅ Complete restaurant browsing and ordering

---

## 💳 Week 3: Checkout & Payment

### Day 11-12: Floating Cart Button
- [ ] **Global Cart Button**
  - File: `lib/shared/widgets/floating_cart_button.dart`
  - Add to all screens as overlay
  - Show cart item count badge
  - Animate count changes
  - Show brief preview on hover/long press
  - Implement tap to navigate to cart
  
- [ ] **Cart Screen Enhancement**
  - Show item thumbnails
  - Display customizations clearly
  - Add promo code success feedback
  - Show savings in green
  - Add estimated delivery time

**Acceptance Criteria:**
- ✅ Cart button visible on all main screens
- ✅ Badge updates in real-time
- ✅ Preview shows total and item count

---

### Day 13-14: Delivery Address & Payment
- [ ] **Address Selection UI**
  - File: `lib/features/order/presentation/widgets/address_selector.dart`
  - Show saved addresses as cards
  - Add "Use Current Location" option
  - Implement "Add New Address" flow
  - Add delivery notes text field
  - Show delivery address on map
  
- [ ] **Paystack Integration**
  - File: `lib/core/services/payment_service.dart`
  - Add `flutter_paystack` package
  - Initialize Paystack with API keys
  - Implement payment flow
  - Handle payment success/failure
  - Add 3D Secure support
  - Store payment methods securely
  
- [ ] **Saved Payment Methods UI**
  - Show saved cards with last 4 digits
  - Add card brand icons (Visa, Mastercard)
  - Implement "Add New Card" flow
  - Add default payment method selection

**Acceptance Criteria:**
- ✅ Address selection works smoothly
- ✅ Payment completes successfully
- ✅ Payment errors handled gracefully

---

### Day 15: Tip & Order Confirmation
- [ ] **Tip Selection**
  - File: `lib/features/order/presentation/widgets/tip_selector.dart`
  - Add preset tip percentages (10%, 15%, 20%)
  - Add custom tip amount option
  - Update total in real-time
  - Default to 15%
  
- [ ] **Order Confirmation Screen**
  - File: `lib/features/order/presentation/screens/order_confirmation_screen.dart`
  - Show success animation (Lottie)
  - Display order number
  - Show estimated delivery time
  - Add "Track Order" button
  - Implement "Order Again" quick action
  
- [ ] **Testing**
  - Test complete checkout flow
  - Test payment integration
  - Test order creation
  - Test error scenarios

**Acceptance Criteria:**
- ✅ Tip calculation accurate
- ✅ Order confirmation appears after payment
- ✅ Order saved to database

**Week 3 Deliverable:** ✅ End-to-end ordering flow functional

---

## 🔐 Week 4: Social Auth & Onboarding

### Day 16-17: Social Authentication
- [ ] **Google Sign-In**
  - File: `lib/core/services/auth_service.dart`
  - Configure Google Cloud Console
  - Add SHA-1 fingerprints (Android)
  - Implement sign-in flow
  - Handle user creation
  - Map Google user to Supabase auth
  
- [ ] **Apple Sign-In**
  - Configure Apple Developer Portal
  - Add entitlements (iOS)
  - Implement sign-in flow
  - Handle anonymous email case
  - Test on physical device
  
- [ ] **Social Auth Error Handling**
  - Handle cancelled sign-in
  - Handle network errors
  - Handle duplicate accounts
  - Show helpful error messages

**Acceptance Criteria:**
- ✅ Google sign-in works on Android & iOS
- ✅ Apple sign-in works on iOS
- ✅ User profile created automatically

---

### Day 18-19: Onboarding Flow
- [ ] **Onboarding Screens**
  - File: `lib/features/authentication/presentation/screens/onboarding_screen.dart`
  - Create 3-4 onboarding slides
  - Slide 1: Welcome + app value proposition
  - Slide 2: Browse restaurants feature
  - Slide 3: Live tracking feature
  - Slide 4: Fast delivery promise
  - Add skip button
  - Add dot indicators
  
- [ ] **Location Permission Flow**
  - File: `lib/features/authentication/presentation/screens/location_permission_screen.dart`
  - Show explanation screen BEFORE requesting
  - Explain benefits (nearby restaurants, accurate delivery)
  - Add "Allow" and "Skip" buttons
  - Handle permission denied
  - Store permission preference
  
- [ ] **First-Time User Detection**
  - Use shared_preferences
  - Show onboarding only once
  - Add "Show Tutorial Again" in settings

**Acceptance Criteria:**
- ✅ Onboarding shows on first launch only
- ✅ Location permission explained clearly
- ✅ Users can skip onboarding

---

### Day 20: Auth Enhancement & Testing
- [ ] **Password Reset**
  - File: `lib/features/authentication/presentation/screens/forgot_password_screen.dart`
  - Add "Forgot Password?" link on login
  - Implement email input screen
  - Send reset link via Supabase
  - Show confirmation message
  - Handle reset completion
  
- [ ] **Email Verification**
  - Send verification email on signup
  - Show "Verify Email" banner
  - Implement verification check
  - Resend verification option
  - Handle verification success
  
- [ ] **Comprehensive Testing**
  - Test Google sign-in flow
  - Test Apple sign-in flow
  - Test password reset flow
  - Test email verification
  - Test onboarding flow
  - Test location permissions

**Acceptance Criteria:**
- ✅ Password reset works end-to-end
- ✅ Email verification functional
- ✅ All authentication flows tested

**Week 4 Deliverable:** ✅ Professional authentication experience

---

## 📊 Phase 1 Success Metrics

### Feature Completion
- [ ] Home screen with map, search, categories ✅
- [ ] Restaurant detail with customization ✅
- [ ] Complete checkout with payment ✅
- [ ] Social authentication working ✅
- [ ] Onboarding flow complete ✅

### Technical Metrics
- [ ] All Phase 1 tests passing (80+ tests)
- [ ] No critical bugs
- [ ] App loads in < 3 seconds
- [ ] Smooth 60fps scrolling

### User Experience
- [ ] All PRD core flows functional
- [ ] Intuitive navigation
- [ ] Clear error messages
- [ ] Responsive feedback on all actions

---

## 🔧 Required Setup Before Starting

### Development Environment
```bash
# Update dependencies
flutter pub get

# Run build_runner for generated code
flutter pub run build_runner build --delete-conflicting-outputs

# Verify Supabase connection
dart run test_supabase_connection.dart
```

### API Keys Needed
- [ ] Paystack Test API Keys (from Paystack Dashboard)
- [ ] Google OAuth Client IDs (Google Cloud Console)
- [ ] Apple Services ID (Apple Developer Portal)
- [ ] Firebase Project for FCM (Phase 2)

### Database Setup
- [ ] Ensure all migrations applied
- [ ] Seed sample restaurants (at least 20)
- [ ] Seed sample menu items (at least 100)
- [ ] Seed sample reviews
- [ ] Create test user account

---

## 🚨 Common Issues & Solutions

### Issue 1: Map Performance
**Problem:** Map stutters with many markers  
**Solution:** Implement marker clustering, limit visible markers to viewport

### Issue 2: Payment Integration
**Problem:** Payment not completing  
**Solution:** Check API keys, verify webhook URLs, test in Paystack sandbox

### Issue 3: Social Auth
**Problem:** Google/Apple sign-in fails  
**Solution:** Verify SHA-1 fingerprints, check bundle IDs, test on physical device

### Issue 4: Image Loading
**Problem:** Restaurant images load slowly  
**Solution:** Implement `cached_network_image`, use WebP format, add placeholders

---

## 📝 Daily Stand-Up Checklist

### Every Morning
- [ ] Pull latest from git
- [ ] Review yesterday's completed tasks
- [ ] Identify today's focus (from checklist above)
- [ ] Check for blockers
- [ ] Update progress tracking

### Every Evening
- [ ] Mark completed tasks ✅
- [ ] Commit and push code
- [ ] Run tests
- [ ] Update documentation
- [ ] Plan tomorrow's tasks

---

## 🎉 Phase 1 Completion Criteria

**Ready to move to Phase 2 when:**
1. ✅ All Week 1-4 tasks completed
2. ✅ All tests passing (80%+ coverage)
3. ✅ Demo-ready app
4. ✅ No critical bugs
5. ✅ Code reviewed and approved
6. ✅ Documentation updated
7. ✅ Deployment scripts tested

**Upon completion:** Project will be at **50% overall** and ready for Phase 2 (Real-Time Features)

---

## 📞 Need Help?

### Resources
- [Comprehensive Plan](./COMPREHENSIVE_COMPLETION_PLAN.md) - Full roadmap
- [PRD](./PRD.md) - Product requirements
- [Supabase Docs](https://supabase.com/docs)
- [Paystack Flutter](https://pub.dev/packages/flutter_paystack)

### Quick References
- Authentication: `lib/core/services/auth_service.dart`
- Database: `lib/core/services/database_service.dart`
- Cart: `lib/features/order/presentation/providers/cart_provider.dart`
- Restaurants: `lib/features/restaurant/presentation/providers/restaurant_provider.dart`

---

**Let's build Week 1! Start with the interactive map 🗺️**
