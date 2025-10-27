# NandyFood Project Analysis and Spec-Driven Completion Plan

This document consolidates a thorough analysis of the current Flutter project and a PRD-aligned, spec-driven implementation plan with strict checklists. Use the checkboxes to track progress. Complex tasks include recursive spec files referenced at the end.

---

## 1) Project Analysis

### Project Overview
- Purpose: Modern Flutter food delivery app with consumer and restaurant-owner experiences.
- Core capabilities:
  - Consumer: onboarding, authentication (email/password, Google, Apple), home & search, restaurant list/detail/menu, cart & checkout, order confirmation/tracking/history, profile (addresses, payments, feedback), favourites.
  - Restaurant Owner: registration, dashboard, orders, menu CRUD, analytics, settings (info/hours/delivery), notifications.
  - Integrations: Supabase (auth/db), Firebase (Core, Messaging, Crashlytics, Analytics, Performance), Maps (flutter_map), Geolocation.
  - Notifications: FCM with local notifications and device registration to user_devices.
  - Payments: PaymentConfig + WebView-based flow (PayFast-like), COD fallback.
- Completeness estimate: 75–80%. Strong scaffolding; remaining work is in final integrations (payments, deep links), data repositories, unifying routing, and test coverage.

### Codebase Structure & Architecture
- Architecture: Feature-first structure with service layer; GoRouter for navigation; Riverpod for state management; shared widgets and theme centralized in main.dart.
- Key folders:
  - lib/core: config, providers, routing, security, services, utils
  - lib/features: authentication, home, restaurant, order, profile, favourites, onboarding, delivery, map, restaurant_dashboard, role_management
  - lib/shared: widgets and shared models
  - test & integration_test: unit/widget/integration + golden tests
  - database & supabase: SQL migrations, apply scripts, RLS fixes
  - docs & root .md files: PRD and multiple setup/analysis/testing docs
- Noted inconsistencies & gaps:
  - NotificationService navigates to routes like `/order/tracking/:id`, `/promo/:id`, `/chat/:id` that do not exist in router. Router currently uses `/order/track` with `extra` order object.
  - Duplicate order history screens (features/order and features/profile). Should consolidate.
  - Routing defined solely in main.dart; consider modularization under core/routing with route constants.
  - Repositories/data layer abstraction not consistently visible; services likely used directly in UI.
  - Error handling not standardized across features.

### Dependencies & Integrations (pubspec.yaml)
- State/DI: flutter_riverpod ^2.6.1, riverpod_annotation ^2.6.1, riverpod_generator ^2.6.5, state_notifier ^1.0.0 (possibly redundant)
- Navigation: go_router ^16.3.0
- UI: screenutil, cached_network_image, shimmer, carousel_slider, lottie
- Backend/Networking: supabase_flutter ^2.10.3, dio ^5.3.2
- Local Storage: shared_preferences, hive, hive_flutter
- Location/Maps: geolocator, geocoding, flutter_map, latlong2
- Notifications: firebase_messaging, flutter_local_notifications, timezone
- Firebase Suite: core, analytics, performance, crashlytics
- Payments: webview_flutter
- Utils: connectivity_plus, package_info_plus, flutter_secure_storage, image_picker, path_provider, crypto, json_annotation, dotenv, google_sign_in, sign_in_with_apple, intl, uuid, collection, url_launcher, fl_chart
- Dev/Test: very_good_analysis, mocktail, mockito (choose one), integration_test, golden_toolkit, patrol, build_runner, json_serializable, riverpod_lint
- Status: Versions appear compatible with Flutter SDK >=3.8. Some redundancies: mockito + mocktail; state_notifier + Riverpod.

### Features vs PRD Mapping (high level)
- Auth: Email/Password ✅, Google ⚠️ (config pending), Apple ⚠️ (config pending), verification gating ⚠️ (enforce), redirect handling ✅.
- Onboarding: ✅ (ensure persistence of completion state).
- Home/Search: ✅ (ensure filters/pagination complete).
- Restaurant: list/detail/menu ✅; dietary filtering ⚠️ verify.
- Cart/Checkout: Flow ✅; Payments ⚠️ finalize E2E + server verification.
- Orders: Tracking ✅; History ✅/⚠️ duplicate consolidation; Deep links ⚠️.
- Profile: addresses/payments/feedback/screens ✅ (verify implementations compile and work end-to-end).
- Favourites: ✅/⚠️ (ensure persistence & sync).
- Role/Dashboard: Screens & services present ✅; full role enforcement and owner flows validation ⚠️.
- Notifications: Device registration ✅; payload routing ⚠️ (route mismatches).

### UI/UX & Navigation
- GoRouter centrally configured with protected routes and auth redirects.
- Theming is comprehensive in main.dart with Material 3; consider extracting tokens.
- Shared widgets present; accessibility widgets included; ensure consistent use of screenutil.

### Backend & Data Flow
- Supabase auth and token/device storage implemented; migrations included.
- DatabaseService, RoleService, DeliveryTrackingService present.
- Repositories are not consistently visible; introduce per-feature repositories with DTOs and error mapping.

### Code Quality & Standards
- very_good_analysis enabled; multiple analyzer fix/summary docs exist.
- AppLogger used broadly; ensure no secrets logged.
- Recommendation: Standardize Result/Failure model; modularize routing; consolidate duplicate screens.

### Testing & Debugging
- Integration: auth, order tracking, profile flows; golden tests present.
- Unit: providers (restaurant/cart), services tests (payment, location), mock database.
- Gaps: payments E2E, notification deep links, owner flows end-to-end; target coverage threshold via CI.

---

## 2) Spec-Driven Implementation Plan (Remaining Tasks Only)

Each subtask represents one logical action, is clearly actionable, and ordered where sequencing matters. Use [ ] and [x] for progress tracking.

### ✅ Task 1: Authentication & User Management (Remaining)
- [ ] Add Android app SHA-1 and SHA-256 to Firebase project
- [x] Download updated google-services.json and place in android/app (exact path: android/app/google-services.json)
- [x] Replace Google serverClientId in AuthService with production ID
- [ ] Validate Google sign-in on a physical Android device
- [ ] Add reversed client ID to URL Types (iOS Runner)
- [ ] Ensure GoogleService-Info.plist is present and correctly configured
- [ ] Validate Google sign-in on iOS device
- [ ] Enable Sign in with Apple in Apple Developer account
- [ ] Add Sign in with Apple entitlements and Associated Domains to iOS project
- [ ] Configure Apple service ID and redirect URIs in Supabase
- [ ] Validate Apple sign-in on iOS 13+ device
- [x] Redirect unverified users to /auth/verify-email after signup
- [x] Implement resend verification email action
- [x] Poll/refresh session to detect email verification completion
- [x] Restore Supabase session on cold start
- [x] Implement ?redirect= handling to navigate after login
- [x] Upsert FCM token on login and token refresh
- [x] Unsubscribe/delete FCM token on logout

Security hygiene (Android OAuth/Firebase)
- [ ] Remove any client_secret_*.json files from the repository (do not commit OAuth client secrets)
- [ ] Ensure upload-keystore.jks is outside source control or gitignored

### ✅ Task 2: Onboarding (Remaining)
- [x] Persist onboarding completion flag in shared_preferences
- [x] Skip onboarding on app start if flag exists
- [x] Add semantic labels and ensure correct focus order
- [ ] Validate contrast in light/dark modes

### ✅ Task 3: Home, Search, and Discovery (Remaining)
- [x] Define restaurant/category DTOs and mappers
- [x] Implement RestaurantRepository.fetchFeatured
- [x] Implement RestaurantRepository.fetchList with pagination
- [x] Implement RestaurantRepository.fetchByFilters
- [x] Add debounced search input (300–500ms)
- [x] Add pagination controls and loading/empty/error states
- [x] Add dietary filters to query per PRD
- [x] Persist selected dietary filters for session

### ✅ Task 4: Restaurant Detail & Menu (Remaining)
- [x] Define menu item/category/modifier DTOs and mappers
- [x] Implement MenuRepository.getMenuByRestaurant with availability
- [x] Build UI for modifiers/options selection with required groups
- [x] Implement item price calculation from selected options
- [x] Implement toggleFavourite API
- [x] Implement fetchFavourites and local cache sync (Hive)

### ✅ Task 5: Cart & Checkout (Remaining)
- [x] Implement line totals and tax rules per PRD
- [x] Implement delivery fee rules (min order, free delivery promos)
- [x] Implement server-validated promo code application
- [x] Implement webview payment success URL interception
- [x] Implement webview payment cancel URL interception
- [x] Persist “pending payment” state across restarts
- [x] Call server verification API after redirect
- [x] Create order only after server verification (idempotent)
- [x] Show friendly payment error messages and retry/switch options

### ✅ Task 6: Orders (Tracking & History) (Remaining)
- [x] Choose unified route scheme for order tracking (path param vs extra)
- [x] Update NotificationService payload routing to unified scheme
- [x] Throttle driver location updates to reduce map churn
- [x] Optimize map markers/performance
- [x] Improve location permission prompts and fallbacks
- [x] Remove duplicate order history screen(s)
- [x] Implement a single order history screen with pagination
- [x] Add reorder action from order history

### ✅ Task 7: Profile, Addresses, Payments, Feedback (Remaining)
- [ ] Implement AddressRepository CRUD with validation
- [ ] Implement optional map-assisted address entry
- [ ] Implement PaymentMethodRepository CRUD with validation
- [ ] Support setting a default payment method
- [ ] Implement profile update (name, avatar upload)
- [ ] Implement feedback submission to Supabase

### ✅ Task 8: Favourites (Remaining)
- [ ] Implement FavouritesRepository with remote/local sync
- [ ] Implement conflict resolution (server-timestamp precedence)

### ✅ Task 9: Role Management & Restaurant Dashboard (Remaining)
- [ ] Add route guards using RoleService for owner routes
- [ ] Hide owner UI for consumer role in widgets/menus
- [ ] Implement restaurant registration form and document capture
- [ ] Persist and display verification states
- [ ] Implement owner orders board status transitions
- [ ] Send customer notifications on status change
- [ ] Implement owner menu CRUD with images and availability
- [ ] Implement analytics KPIs with fl_chart and date filters
- [ ] Implement restaurant settings (info, operating hours, delivery radius/fee)
- [ ] Subscribe to restaurant_* topics on role activation
- [ ] Unsubscribe from restaurant_* topics on logout/role change

### ✅ Task 10: Notifications & Deep Links (Remaining)
- [x] Remove unsupported payload routes (/chat/:id, /promo/:id) or add matching routes
- [x] Ensure NotificationService only targets valid routes
- [x] Show local notification + in-app banner for foreground messages
- [x] Deep link correctly from background and terminated states
- [x] Upsert token on login and onTokenRefresh
- [x] Delete token on logout

### ✅ Task 11: Maps & Geolocation (Remaining)
- [ ] Configure MapConfig (tile server/API key if needed)
- [ ] Ensure provider TOS compliance documentation
- [x] Implement rationale dialogs for permissions
- [x] Implement denied/forever-denied flows and fallbacks

### ✅ Task 12: Data Layer & Error Handling (Remaining)
- [ ] Implement Result<T>/Failure model (sealed classes)
- [ ] Map Dio/Supabase errors to Failure with user-friendly messages
- [ ] Implement AuthRepository with Result returns
- [ ] Implement RestaurantRepository with Result returns
- [ ] Implement MenuRepository with Result returns
- [ ] Implement CartOrderRepository with Result returns
- [ ] Implement ProfileRepository with Result returns
- [ ] Implement FavouritesRepository with Result returns
- [ ] Implement OwnerRepository with Result returns
- [ ] Adopt Riverpod Notifier/AsyncNotifier with codegen for providers
- [ ] Remove state_notifier if unused after migration

### ✅ Task 13: Security & Privacy (Remaining)
- [x] Scrub sensitive data from logs in AppLogger
- [ ] Run verify_database_setup.sql on staging
- [ ] Run ALL_MIGRATIONS_* and confirm RLS correctness
- [ ] Validate RLS for consumer vs owner access paths
- [ ] Link Privacy Policy and Terms within app and store metadata

### ✅ Task 14: UI/UX Polish & Accessibility (Remaining)
- [ ] Extract theme tokens (spacing, typography, color) into dedicated helpers
- [ ] Apply screenutil consistently on major screens
- [ ] Validate text scaling, dark mode, and focus order on key flows

### ✅ Task 15: Testing & CI (Remaining)
- [ ] Add integration tests: payments success/cancel/error
- [ ] Add integration tests: notification deep links (all app states)
- [ ] Add integration tests: owner flows (menu CRUD, orders, analytics)
- [ ] Enable coverage reporting in CI
- [ ] Set and enforce coverage threshold (>=70%)
- [ ] Choose one mocking framework (mockito or mocktail) and remove the other


### ✅ Task 16: Polishing & Final UX Fit-and-Finish (Cross-cutting)
- Notifications & Deep Links polish
  - [x] Foreground notifications: show local notification + in-app banner with action
  - [x] Parse tap payloads and deep link to new routes:
    - order:<id> → /order/track/<id>
    - promo:<id> → /promo/<id>
    - /promotions → /promotions
  - [x] Wire NotificationService.initialize(onNotificationTap) in main.dart
  - [x] Handle onMessageOpenedApp and onBackgroundMessage consistently
- Payment flow polish
  - [x] Replace any remaining PaymentConfirmationScreen references with PaymentResultScreen
  - [x] Verify order creation still happens before navigating to result; ensure idempotency guards
  - [x] Ensure friendly error from PaymentProvider is surfaced on result screen
  - [x] Refine copy/icons/CTAs (Track Order, Back to Home, Try Again, Use Different Method)
- Routes & consistency
  - [x] Centralize route paths in core/routing/route_paths.dart and use constants across app
  - [x] Align NotificationService payload format to the unified route scheme
- Promotion detail polish
  - [x] Disable "Apply Code" if promo invalid/below min order; show reason text
  - [x] Add retry on load failure + better empty/error states
  - [x] Fire analytics event on promo apply via deep link (via AppLogger.userAction)
- Order tracking polish
  - [x] Add error UI when fetching order by ID fails (retry/back)
  - [x] Ensure DeliveryTrackingService streams unsubscribe on dispose
- Analyzer cleanup (targeted)
  - [x] Replace deprecated withOpacity usages with withValues()
  - [ ] Remove unnecessary imports and casts flagged by analyze
- Targeted tests (widget/deep link)
  - [x] PaymentResultScreen widget tests (success/failure CTAs navigate correctly)
  - [x] PromoDetailScreen apply flow test (disabled state + error actions)
  - [x] Deep link navigation tests for notification taps (payload→route mapping via navigateForPayload)

#### Task 16 — Priority Run Order (next actions)
1) [x] Wire NotificationService tap/deep-link parsing to GoRouter (order/promo/promotions)
2) [x] Add FirebaseMessaging handlers (onMessage, onMessageOpenedApp, onBackgroundMessage) + in-app banner
3) [x] Centralize route constants and update references (RoutePaths + payload helpers wired across main areas)
4) [x] Verify/guard order creation before PaymentResultScreen navigation
5) [x] Add targeted widget tests for PaymentResultScreen and deep link nav

### ✅ Task 17: Release & Deployment (Remaining)
- [ ] Finalize .env.staging and .env.production values
- [ ] Verify Payment, Supabase, Firebase keys for staging/production
- [ ] Validate Firebase Analytics, Crashlytics, Messaging on Android/iOS
- [ ] Prepare store assets (icons, splash, screenshots, descriptions)
- [ ] Execute QA checklist and final UAT
- [ ] Prepare gateway sandbox-to-live switch and webhook verification evidence

---

## 3) Complex Spec Files (Recursive Decomposition)
Create and maintain these markdown specs using the same checklist rules:

- docs/specs/payments_e2e.md
  - Payments E2E Spec: server verification API, WebView intercepts, pending state, retries/backoff, idempotent orders, error UX, integration tests, sandbox runbook.

- docs/specs/notifications_deeplinks.md
  - Notifications & Deep Links Spec: payload->route mapping, NotificationService alignment, app state handling (FG/BG/terminated), token lifecycle, topic subscriptions, tests.

- docs/specs/repository_error_handling_standard.md
  - Repository & Error Handling Spec: Result/Failure types, exception mapping, base contract, provider migration to AsyncNotifier, unit tests.

- docs/specs/role_enforcement_rls.md
  - Role Enforcement & RLS Spec: router guards, UI gating, RLS validation steps/queries, integration tests, staging validation report.

---

## 4) Exit Criteria
- All tasks in remaining plan are checked.
- Complex spec checklists are complete.
- Integration tests pass for auth, checkout/payment, order tracking, owner flows, deep links.
- Coverage threshold met in CI (>=70%).
- Staging UAT approved; production configuration validated; store submission ready.
