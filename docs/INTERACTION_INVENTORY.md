# Flutter App Complete Interaction Inventory

**Generated**: 2025-10-25  
**Purpose**: Complete catalog of all user interactions, screens, and flows

---

## 📱 Screen Inventory

### 1. Authentication Screens

#### 1.1 Splash Screen (`splash_screen.dart`)
- **Route**: `/`
- **Interactions**:
  - Auto-navigate after 3 seconds
  - Display app logo and branding
- **Gestures**: None (auto-transition)
- **Testing Priority**: ⭐⭐

#### 1.2 Onboarding Screen (`onboarding_screen.dart`)
- **Route**: `/onboarding`
- **Interactions**:
  - Swipe left/right through pages
  - Tap "Skip" button
  - Tap "Get Started" button
  - Dot indicators for page position
- **Gestures**: Horizontal swipe, tap
- **Testing Priority**: ⭐⭐⭐

#### 1.3 Login Screen (`login_screen.dart`)
- **Route**: `/auth/login`
- **Interactions**:
  - Email text field (validation)
  - Password text field (validation, obscure text)
  - Password visibility toggle
  - "Remember me" checkbox
  - Login button
  - "Forgot Password?" link
  - "Sign Up" link
  - Google Sign-In button
  - Apple Sign-In button
- **Gestures**: Tap, text input, scroll
- **Forms**: Email, Password
- **Validations**: Email format, password min length
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 1.4 Signup Screen (`signup_screen.dart`)
- **Route**: `/auth/signup`
- **Interactions**:
  - Full name text field
  - Email text field (validation)
  - Phone number text field (validation)
  - Password text field (validation, obscure text)
  - Confirm password text field (match validation)
  - Password visibility toggles
  - Role selection (Customer/Restaurant Owner)
  - Terms & conditions checkbox
  - Sign Up button
  - "Already have account?" link
  - Google Sign-In button
  - Apple Sign-In button
- **Gestures**: Tap, text input, scroll
- **Forms**: Name, Email, Phone, Password, Confirm Password
- **Validations**: Email format, phone format, password match, terms acceptance
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 1.5 Forgot Password Screen (`forgot_password_screen.dart`)
- **Route**: `/auth/forgot-password`
- **Interactions**:
  - Email text field
  - Reset password button
  - Back button
- **Gestures**: Tap, text input
- **Testing Priority**: ⭐⭐⭐

#### 1.6 Verify Email Screen (`verify_email_screen.dart`)
- **Route**: `/auth/verify-email`
- **Interactions**:
  - Display verification message
  - Resend email button
  - Continue button
- **Gestures**: Tap
- **Testing Priority**: ⭐⭐⭐

---

### 2. Home & Discovery Screens

#### 2.1 Home Screen (`home_screen.dart`)
- **Route**: `/home`
- **Interactions**:
  - Search bar (tap to navigate to search)
  - Location selector
  - Category chips (horizontal scroll)
  - Restaurant cards (vertical scroll)
  - Pull-to-refresh
  - Bottom navigation
  - Promotional banners (carousel)
  - Filter button
  - Sort dropdown
- **Gestures**: Tap, vertical scroll, horizontal scroll, pull-to-refresh
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 2.2 Search Screen (`search_screen.dart`)
- **Route**: `/search`
- **Interactions**:
  - Search text field (real-time search)
  - Recent searches list
  - Clear search button
  - Filter chips
  - Search results (restaurants/menu items)
  - Voice search button
- **Gestures**: Tap, text input, scroll
- **Testing Priority**: ⭐⭐⭐⭐

---

### 3. Restaurant Screens

#### 3.1 Restaurant List Screen (`restaurant_list_screen.dart`)
- **Route**: `/restaurants`
- **Interactions**:
  - Restaurant cards
  - Filter button
  - Sort options
  - Scroll for pagination
  - Favorite toggle
- **Gestures**: Tap, scroll
- **Testing Priority**: ⭐⭐⭐⭐

#### 3.2 Restaurant Detail Screen (`restaurant_detail_screen.dart`)
- **Route**: `/restaurant/:id`
- **Interactions**:
  - Header image
  - Favorite button
  - Share button
  - Tabs: Info, Menu, Reviews
  - Restaurant info display
  - Operating hours
  - Delivery info
  - Call restaurant button
- **Gestures**: Tap, scroll, swipe (tabs)
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 3.3 Menu Screen (`menu_screen.dart`)
- **Route**: `/restaurant/:id/menu`
- **Interactions**:
  - Category tabs/chips
  - Menu item cards
  - Search menu items
  - Filter dietary options
  - Tap item for details
- **Gestures**: Tap, scroll, horizontal swipe
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 3.4 Menu Item Detail Screen (`menu_item_detail_screen.dart`)
- **Interactions**:
  - Item image gallery
  - Quantity selector (+/- buttons)
  - Size selection (radio buttons)
  - Customizations (checkboxes)
  - Special instructions text field
  - Add to cart button
  - Price calculation (dynamic)
- **Gestures**: Tap, text input, swipe (image gallery)
- **Forms**: Quantity, customizations, special instructions
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 3.5 Reviews Screen (`reviews_screen.dart`)
- **Interactions**:
  - Review list
  - Star ratings display
  - Filter by rating
  - Sort by date/rating
  - Load more reviews
  - Write review button
- **Gestures**: Tap, scroll
- **Testing Priority**: ⭐⭐⭐

#### 3.6 Write Review Screen (`write_review_screen.dart`)
- **Interactions**:
  - Star rating selector
  - Review text field
  - Photo upload
  - Submit button
  - Cancel button
- **Gestures**: Tap, text input
- **Forms**: Rating, review text
- **Testing Priority**: ⭐⭐⭐

---

### 4. Cart & Checkout Screens

#### 4.1 Cart Screen (`cart_screen.dart`)
- **Route**: `/cart`
- **Interactions**:
  - Cart item list
  - Quantity adjustment (+/- buttons)
  - Remove item (swipe or delete button)
  - Clear cart button
  - Promo code input
  - Apply promo button
  - Price breakdown display
  - Proceed to checkout button
  - Empty cart state
- **Gestures**: Tap, swipe-to-delete, scroll
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 4.2 Checkout Screen (`checkout_screen.dart`)
- **Route**: `/checkout`
- **Interactions**:
  - Delivery address selection
  - Add new address button
  - Payment method selection
  - Add payment method button
  - Delivery time selector
  - Special instructions text field
  - Tip amount selector
  - Order summary
  - Place order button
  - Terms acceptance checkbox
- **Gestures**: Tap, text input, scroll
- **Forms**: Special instructions, tip amount
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 4.3 Payment Method Screen (`payment_method_screen.dart`)
- **Interactions**:
  - Saved payment methods list
  - Add new card button
  - Select payment method (radio)
  - Cash on delivery option
  - PayFast integration
- **Gestures**: Tap, scroll
- **Testing Priority**: ⭐⭐⭐⭐

#### 4.4 PayFast Payment Screen (`payfast_payment_screen.dart`)
- **Interactions**:
  - WebView for PayFast
  - Loading indicator
  - Success/failure callbacks
  - Cancel button
- **Gestures**: Tap, web interactions
- **Testing Priority**: ⭐⭐⭐⭐

#### 4.5 Order Confirmation Screen (`order_confirmation_screen.dart`)
- **Route**: `/order/confirmation`
- **Interactions**:
  - Order number display
  - Order details
  - Estimated delivery time
  - Track order button
  - View receipt button
  - Continue shopping button
- **Gestures**: Tap
- **Testing Priority**: ⭐⭐⭐⭐

---

### 5. Order Tracking Screens

#### 5.1 Order Tracking Screen (`order_tracking_screen.dart`)
- **Route**: `/order/track`
- **Interactions**:
  - Order status timeline
  - Live map with driver location
  - Estimated arrival time
  - Call driver button
  - Call restaurant button
  - Order details accordion
  - Cancel order button
  - Help/Support button
- **Gestures**: Tap, pinch-zoom (map), scroll
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 5.2 Enhanced Order Tracking Screen (`enhanced_order_tracking_screen.dart`)
- **Interactions**:
  - Real-time location updates
  - Driver photo and rating
  - Vehicle details
  - Live chat with driver
  - Map controls (zoom, center)
- **Gestures**: Tap, map gestures
- **Testing Priority**: ⭐⭐⭐⭐

#### 5.3 Order History Screen (Order) (`order_history_screen.dart`)
- **Route**: `/order/history`
- **Interactions**:
  - Order list (past orders)
  - Filter by status
  - Search orders
  - Tap order for details
  - Reorder button
  - Rate order button
- **Gestures**: Tap, scroll, pull-to-refresh
- **Testing Priority**: ⭐⭐⭐⭐

#### 5.4 Payment Result Screen (`payment_result_screen.dart`)
- **Interactions**:
  - Show success/failure status with icon and message
  - On success: Track Order, Back to Home
  - On failure: Try Again, Use Different Method, Cancel
  - Display payment reference when available
- **Gestures**: Tap
- **Testing Priority**: ⭐⭐⭐

---

### 6. Profile Screens

#### 6.1 Profile Screen (Main) (`profile_screen.dart`)
- **Route**: `/profile`
- **Interactions**:
  - Profile photo
  - Edit profile button
  - Name and email display
  - Menu items:
    - Order History
    - Addresses
    - Payment Methods
    - Favorites
    - Settings
    - Help & Support
    - Feedback
    - Logout
- **Gestures**: Tap, scroll
- **Testing Priority**: ⭐⭐⭐⭐

#### 6.2 Profile Settings Screen (`profile_settings_screen.dart`)
- **Route**: `/profile/settings`
- **Interactions**:
  - Edit name field
  - Edit email field
  - Edit phone field
  - Profile photo upload
  - Change password button
  - Save button
  - Cancel button
- **Gestures**: Tap, text input
- **Forms**: Name, Email, Phone
- **Testing Priority**: ⭐⭐⭐

#### 6.3 Settings Screen (`settings_screen.dart`)
- **Route**: `/profile/app-settings`
- **Interactions**:
  - Dark mode toggle
  - Notifications toggle
  - Push notifications toggle
  - Email notifications toggle
  - SMS notifications toggle
  - Language selector
  - About app
  - Privacy policy
  - Terms of service
- **Gestures**: Tap, toggle switches
- **Testing Priority**: ⭐⭐⭐⭐

#### 6.4 Address Screen (`address_screen.dart`)
- **Route**: `/profile/addresses`
- **Interactions**:
  - Address list
  - Add new address button
  - Edit address button
  - Delete address (swipe)
  - Set default address toggle
  - Search addresses
- **Gestures**: Tap, swipe-to-delete, scroll
- **Testing Priority**: ⭐⭐⭐⭐

#### 6.5 Add/Edit Address Screen (`add_edit_address_screen.dart`)
- **Route**: `/profile/add-address` or `/profile/edit-address/:id`
- **Interactions**:
  - Label field (Home, Work, Other)
  - Address line 1 field
  - Address line 2 field
  - City field
  - State field
  - Postal code field
  - Country field
  - Phone field
  - Select on map button
  - Use current location button
  - Set as default checkbox
  - Save button
- **Gestures**: Tap, text input
- **Forms**: Complete address form
- **Validations**: All fields, postal code format, phone format
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 6.6 Payment Methods Screen (`payment_methods_screen.dart`)
- **Route**: `/profile/payment-methods`
- **Interactions**:
  - Saved cards list
  - Add new card button
  - Edit card button
  - Delete card (swipe)
  - Set default payment toggle
- **Gestures**: Tap, swipe-to-delete, scroll
- **Testing Priority**: ⭐⭐⭐⭐

#### 6.7 Add/Edit Payment Screen (`add_edit_payment_screen.dart`)
- **Route**: `/profile/add-payment` or `/profile/edit-payment/:id`
- **Interactions**:
  - Card number field (formatted)
  - Cardholder name field
  - Expiry date field (MM/YY)
  - CVV field (obscured)
  - Billing address selector
  - Set as default checkbox
  - Save button
- **Gestures**: Tap, text input
- **Forms**: Card details
- **Validations**: Card number (Luhn), expiry date, CVV
- **Testing Priority**: ⭐⭐⭐⭐

#### 6.8 Order History Screen (Profile) (`order_history_screen.dart`)
- **Route**: `/profile/order-history`
- **Interactions**:
  - Same as Order History Screen (Order)
- **Testing Priority**: ⭐⭐⭐⭐

#### 6.9 Feedback Screen (`feedback_screen.dart`)
- **Route**: `/profile/feedback`
- **Interactions**:
  - Feedback type selector
  - Subject field
  - Message text area
  - Rating stars
  - Attach screenshot button
  - Submit button
- **Gestures**: Tap, text input
- **Forms**: Feedback form
- **Testing Priority**: ⭐⭐⭐

---

### 7. Favorites Screen

#### 7.1 Favourites Screen (`favourites_screen.dart`)
- **Route**: `/favourites`
- **Interactions**:
  - Favorite restaurants list
  - Remove favorite (swipe or button)
  - Tap to view restaurant
  - Empty state when no favorites
- **Gestures**: Tap, swipe, scroll
- **Testing Priority**: ⭐⭐⭐

---

### 8. Restaurant Dashboard (Owner)

#### 8.1 Role Selection Screen (`role_selection_screen.dart`)
- **Route**: `/role/select`
- **Interactions**:
  - Customer role card
  - Restaurant Owner role card
  - Selection confirmation
- **Gestures**: Tap
- **Testing Priority**: ⭐⭐⭐

#### 8.2 Restaurant Dashboard Screen (`restaurant_dashboard_screen.dart`)
- **Route**: `/restaurant/dashboard`
- **Interactions**:
  - Statistics cards
  - Active orders count
  - Revenue display
  - Quick actions buttons
  - Navigation to:
    - Orders
    - Menu
    - Analytics
    - Settings
- **Gestures**: Tap, scroll
- **Testing Priority**: ⭐⭐⭐⭐

#### 8.3 Restaurant Registration Screen (`restaurant_registration_screen.dart`)
- **Route**: `/restaurant/register`
- **Interactions**:
  - Restaurant name field
  - Description field
  - Cuisine type selector
  - Address fields
  - Phone field
  - Email field
  - Logo upload
  - Cover image upload
  - Operating hours selector
  - Delivery settings
  - Submit button
- **Gestures**: Tap, text input, scroll
- **Forms**: Complete registration form
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 8.4 Restaurant Orders Screen (`restaurant_orders_screen.dart`)
- **Route**: `/restaurant/orders`
- **Interactions**:
  - Order tabs (New, Preparing, Ready, Completed)
  - Order cards
  - Accept order button
  - Reject order button
  - Mark as ready button
  - View order details
  - Filter by date
  - Search orders
- **Gestures**: Tap, swipe (tabs), scroll
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 8.5 Restaurant Menu Screen (Owner) (`restaurant_menu_screen.dart`)
- **Route**: `/restaurant/menu`
- **Interactions**:
  - Menu items list
  - Add menu item button
  - Edit item button
  - Delete item button
  - Toggle availability switch
  - Category management
  - Search menu items
- **Gestures**: Tap, scroll, swipe
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 8.6 Add/Edit Menu Item Screen (`add_edit_menu_item_screen.dart`)
- **Route**: `/restaurant/menu/add` or `/restaurant/menu/edit/:itemId`
- **Interactions**:
  - Item name field
  - Description field
  - Price field
  - Category selector
  - Image upload (multiple)
  - Dietary tags (checkboxes)
  - Customization options
  - Availability toggle
  - Preparation time field
  - Save button
- **Gestures**: Tap, text input, scroll
- **Forms**: Menu item form
- **Testing Priority**: ⭐⭐⭐⭐⭐

#### 8.7 Restaurant Analytics Screen (`restaurant_analytics_session_wrapper.dart`)
- **Route**: `/restaurant/analytics`
- **Interactions**:
  - Date range selector
  - Charts display
  - Key metrics
  - Export report button
  - Filter options
- **Gestures**: Tap, pinch-zoom (charts), scroll
- **Testing Priority**: ⭐⭐⭐

#### 8.8 Restaurant Settings Screen (`restaurant_settings_screen.dart`)
- **Route**: `/restaurant/settings`
- **Interactions**:
  - Navigation to:
    - Restaurant Info
    - Operating Hours
    - Delivery Settings
  - Toggle settings
- **Gestures**: Tap, scroll
- **Testing Priority**: ⭐⭐⭐

#### 8.9 Restaurant Info Screen (`restaurant_info_screen.dart`)
- **Route**: `/restaurant/settings/info`
- **Interactions**:
  - Edit restaurant details
  - Similar to registration form
- **Testing Priority**: ⭐⭐⭐

#### 8.10 Operating Hours Screen (`operating_hours_screen.dart`)
- **Route**: `/restaurant/settings/hours`
- **Interactions**:
  - Day toggles (open/closed)
  - Time pickers for each day
  - Break time settings
  - Save button
- **Gestures**: Tap, time selection
- **Testing Priority**: ⭐⭐⭐⭐

#### 8.11 Delivery Settings Screen (`delivery_settings_screen.dart`)
- **Route**: `/restaurant/settings/delivery`
- **Interactions**:
  - Delivery radius slider
  - Minimum order amount field
  - Delivery fee field
  - Free delivery threshold field
  - Estimated delivery time field
  - Save button
- **Gestures**: Tap, slider, text input
- **Testing Priority**: ⭐⭐⭐⭐

---

## 🎨 Widget Inventory

### Shared Widgets (41 total)

1. **accessible_cart_item_widget.dart**
   - Interactions: Quantity adjust, remove
   - Gestures: Tap

2. **advanced_filter_sheet.dart**
   - Interactions: Multiple filters, sliders, checkboxes
   - Gestures: Tap, slide, scroll

3. **app_bar_widget.dart**
   - Interactions: Back button, title, actions
   - Gestures: Tap

4. **bottom_navigation_bar_widget.dart**
   - Interactions: Tab selection (4-5 tabs)
   - Gestures: Tap

5. **cart_item_widget.dart**
   - Interactions: Quantity adjust, remove, customize
   - Gestures: Tap, swipe

6. **confirmation_dialog.dart**
   - Interactions: Confirm, cancel buttons
   - Gestures: Tap

7. **delivery_tracking_map_widget.dart**
   - Interactions: Map display, markers, live updates
   - Gestures: Pinch, pan, tap

8. **delivery_tracking_widget.dart**
   - Interactions: Status timeline, driver info
   - Gestures: Tap, scroll

9. **empty_state_widget.dart**
   - Interactions: Display message, action button
   - Gestures: Tap

10. **enhanced_error_message_widget.dart**
    - Interactions: Error display, retry button
    - Gestures: Tap

11. **enhanced_loading_indicator.dart**
    - Interactions: Loading animation
    - Gestures: None

12. **error_boundary.dart**
    - Interactions: Error catching and display
    - Gestures: Tap (retry)

13. **filter_widget.dart**
    - Interactions: Filter chips, apply
    - Gestures: Tap

14. **floating_cart_button.dart**
    - Interactions: Cart badge, navigate to cart
    - Gestures: Tap

15. **lazy_loading_list.dart**
    - Interactions: Infinite scroll, pagination
    - Gestures: Scroll

16. **location_map_widget.dart**
    - Interactions: Map display, location pin
    - Gestures: Map gestures

17. **location_selector_widget.dart**
    - Interactions: Select location, use current
    - Gestures: Tap

18. **meal_time_selector_widget.dart**
    - Interactions: Time selection chips
    - Gestures: Tap

19. **menu_item_card_widget.dart**
    - Interactions: View item, add to cart
    - Gestures: Tap

20. **modern_bottom_navigation.dart**
    - Interactions: Modern tab design
    - Gestures: Tap

21. **notification_banner.dart**
    - Interactions: Display notification, dismiss
    - Gestures: Tap, swipe

22. **offline_banner.dart**
    - Interactions: Offline indicator
    - Gestures: None

23. **order_card_widget.dart**
    - Interactions: Order summary, actions
    - Gestures: Tap

24. **order_history_item_widget.dart**
    - Interactions: Order details, reorder
    - Gestures: Tap

25. **order_tracking_widget.dart**
    - Interactions: Track order status
    - Gestures: Tap

26. **payment_loading_indicator.dart**
    - Interactions: Payment processing animation
    - Gestures: None

27. **payment_method_selector_widget.dart**
    - Interactions: Select payment method
    - Gestures: Tap

28. **payment_security_badge.dart**
    - Interactions: Display security info
    - Gestures: None

29. **rating_stars.dart**
    - Interactions: Display rating
    - Gestures: None (display only)

30. **rating_widget.dart**
    - Interactions: Interactive rating
    - Gestures: Tap

31. **restaurant_card_widget.dart**
    - Interactions: View restaurant, favorite
    - Gestures: Tap

32. **search_bar_widget.dart**
    - Interactions: Search input
    - Gestures: Tap, text input

33. **shimmer_widget.dart**
    - Interactions: Loading placeholder
    - Gestures: None

34. **skeleton_loading.dart**
    - Interactions: Loading skeletons
    - Gestures: None

35. **status_badge_widget.dart**
    - Interactions: Display order status
    - Gestures: None

36. **styled_button_widget.dart**
    - Interactions: Custom button styles
    - Gestures: Tap

37. **success_message_widget.dart**
    - Interactions: Success feedback
    - Gestures: None

38. **user_profile_widget.dart**
    - Interactions: Profile display
    - Gestures: Tap

---

## 🔄 User Flow Inventory

### Critical User Flows

1. **New User Onboarding**
   - Splash → Onboarding → Signup → Home
   - Priority: ⭐⭐⭐⭐⭐

2. **Guest Browsing**
   - Splash → Home → Browse Restaurants → View Menu
   - Priority: ⭐⭐⭐⭐

3. **User Authentication**
   - Login → Home
   - Signup → Home
   - Social Auth → Home
   - Priority: ⭐⭐⭐⭐⭐

4. **Restaurant Discovery**
   - Home → Search → Filter → Restaurant Detail
   - Priority: ⭐⭐⭐⭐

5. **Order Placement**
   - Restaurant → Menu → Item Detail → Cart → Checkout → Confirmation
   - Priority: ⭐⭐⭐⭐⭐

6. **Order Tracking**
   - Order Confirmation → Order Tracking → Live Updates → Delivery
   - Priority: ⭐⭐⭐⭐⭐

7. **Profile Management**
   - Profile → Edit Profile/Addresses/Payment → Save
   - Priority: ⭐⭐⭐⭐

8. **Favorites Management**
   - Restaurant → Add to Favorites → Favorites List
   - Priority: ⭐⭐⭐

9. **Review & Rating**
   - Order History → Rate Order → Submit Review
   - Priority: ⭐⭐⭐

10. **Restaurant Owner Journey**
    - Signup (Owner) → Register Restaurant → Dashboard → Manage Orders/Menu
    - Priority: ⭐⭐⭐⭐⭐

---

## 📊 Interaction Categories

### Form Inputs (17 forms total)
1. Login Form
2. Signup Form
3. Forgot Password Form
4. Address Form (Add/Edit)
5. Payment Card Form
6. Review Form
7. Feedback Form
8. Restaurant Registration Form
9. Menu Item Form
10. Profile Edit Form
11. Search Form
12. Filter Form
13. Promo Code Form
14. Special Instructions Form
15. Operating Hours Form
16. Delivery Settings Form
17. Change Password Form

### Navigation Elements
- Bottom Navigation Bar (5 items)
- App Bar with back button
- Drawer/Menu (if applicable)
- Tab Bars (Restaurant Detail, Orders)
- Deep Links (notifications, sharing)

### Gesture Types Used
1. **Tap** - All interactive elements
2. **Double Tap** - Image zoom
3. **Long Press** - Context menus
4. **Swipe** - Delete items, page navigation
5. **Scroll** - Vertical lists
6. **Horizontal Scroll** - Categories, carousels
7. **Pull-to-Refresh** - List updates
8. **Pinch-to-Zoom** - Maps, images
9. **Pan** - Map navigation
10. **Drag** - Reorder items (if applicable)

### State Changes to Test
1. Loading states (shimmer, spinners)
2. Empty states (no data)
3. Error states (network, validation)
4. Success states (confirmations)
5. Offline mode
6. Network transitions (online ↔ offline)
7. Theme changes (light ↔ dark)
8. Authentication states (logged in/out)
9. Order states (pending → preparing → delivered)
10. Real-time updates (driver location)

---

## 🔍 Validation Rules Inventory

### Email Validation
- Format: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
- Required field
- Max length: 254

### Password Validation
- Min length: 8 characters
- Required field
- Contains uppercase, lowercase, number, special char

### Phone Validation
- Format: Varies by country
- Min length: 10 digits
- Max length: 15 digits

### Card Number Validation
- Luhn algorithm check
- Format: 16 digits (grouped)
- CVV: 3-4 digits

### Address Validation
- All fields required
- Postal code format check
- Coordinates validation

---

## 📱 Device-Specific Testing

### Screen Sizes
- Small phones (320x568)
- Medium phones (375x667)
- Large phones (414x896)
- Tablets (768x1024)
- Landscape orientations

### Platform-Specific Features
- iOS: Apple Sign-In, haptic feedback
- Android: Google Sign-In, material design
- Both: Push notifications, deep links

---

## 🎯 Testing Priority Matrix

**⭐⭐⭐⭐⭐ Critical** (20 items)
- Login Screen
- Signup Screen
- Home Screen
- Restaurant Detail Screen
- Menu Screen
- Menu Item Detail Screen
- Cart Screen
- Checkout Screen
- Order Tracking Screen
- Restaurant Registration
- Restaurant Orders
- Restaurant Menu Management
- Add Menu Item

**⭐⭐⭐⭐ High** (15 items)
- Search Screen
- Restaurant List
- Payment screens
- Address management
- Profile screens
- Settings

**⭐⭐⭐ Medium** (10 items)
- Reviews
- Favorites
- Feedback
- Analytics

**⭐⭐ Low** (5 items)
- Splash
- Static info screens

---

## 📝 Coverage Goals

- **Unit Tests**: 85%+ coverage
- **Widget Tests**: All interactive widgets
- **Integration Tests**: All critical user flows
- **Golden Tests**: All major screens (light + dark)
- **E2E Tests**: Complete user journeys

---

**Total Screens**: 40+  
**Total Widgets**: 41 shared widgets  
**Total Forms**: 17  
**Total User Flows**: 10 critical paths  
**Total Gestures**: 10 types

