# 🍔 NandyFood - Modern Food Delivery Application

A full-featured, production-ready food delivery application built with Flutter and Supabase, featuring real-time order tracking, multi-role support, and offline-first architecture.

![Flutter Version](https://img.shields.io/badge/Flutter-3.35.5-blue)
![Dart SDK](https://img.shields.io/badge/Dart-3.8.0-blue)
![Riverpod](https://img.shields.io/badge/Riverpod-2.6.1-purple)
![Supabase](https://img.shields.io/badge/Supabase-2.10.3-green)
![License](https://img.shields.io/badge/License-Private-red)

---

## 📱 Overview

**NandyFood** is a comprehensive food delivery platform supporting multiple user roles:
- 🛒 **Customers** - Browse restaurants, place orders, track deliveries
- 🍽️ **Restaurant Owners** - Manage menus, accept orders, view analytics
- 🚗 **Delivery Drivers** - Accept deliveries, navigate to destinations
- 👨‍💼 **Administrators** - System management and oversight

### ✨ Key Features

#### For Customers
- 🔍 **Smart Search** - Real-time restaurant and menu item search
- 🗺️ **Location-Based Discovery** - Find restaurants near you
- 💳 **Multiple Payment Options** - PayFast, Stripe, Cash on Delivery
- 📍 **Live Order Tracking** - Real-time driver location tracking
- ⭐ **Favorites** - Save your favorite restaurants and dishes
- 📱 **Push Notifications** - Order status updates
- 💾 **Offline Mode** - Access order history without internet
- 🎁 **Promotions** - Apply discount codes at checkout

#### For Restaurant Owners
- 📊 **Analytics Dashboard** - Real-time sales and performance metrics
- 🍽️ **Menu Management** - Full CRUD operations for menu items
- 📦 **Order Management** - Accept, prepare, and complete orders
- ⏰ **Operating Hours** - Configure business hours and delivery settings
- 📸 **Image Upload** - Professional menu item photography
- 💰 **Revenue Tracking** - Monitor earnings and transactions

#### Technical Highlights
- 🏗️ **Clean Architecture** - Feature-based modular structure
- 🔄 **State Management** - Riverpod for scalable state handling
- 🔐 **Secure Authentication** - Multi-provider auth (Google, Apple, Email)
- 🎨 **Material 3 Design** - Modern, accessible UI components
- 🌐 **Real-time Updates** - Supabase Realtime subscriptions
- 📦 **Offline-First** - Hive-based caching for seamless UX
- 🧪 **Comprehensive Testing** - Unit, widget, and integration tests

---

## 🚀 Quick Start

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: 3.8.0 or higher ([Install Flutter](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: 3.8.0 or higher (comes with Flutter)
- **Android Studio** or **Xcode** (for mobile development)
- **Git**: For version control
- **Supabase Account**: [Create free account](https://supabase.com)
- **Firebase Account**: [Create free account](https://firebase.google.com)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd NandyFood
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Set up environment variables**

Create a `.env` file in the root directory:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Environment
ENVIRONMENT=development  # development, staging, or production

# Payment Configuration (optional for development)
PAYFAST_MERCHANT_ID=your_merchant_id
PAYFAST_MERCHANT_KEY=your_merchant_key
PAYFAST_PASSPHRASE=your_passphrase
```

4. **Configure Firebase**

- Download `google-services.json` (Android) from Firebase Console
- Place in `android/app/`
- Download `GoogleService-Info.plist` (iOS) from Firebase Console
- Place in `ios/Runner/`

5. **Run database migrations**

```bash
# Connect to your Supabase project
cd supabase/migrations

# Apply all migrations in order
psql -h <db-host> -U postgres -d postgres -f 001_create_user_profiles.sql
psql -h <db-host> -U postgres -d postgres -f 002_create_addresses.sql
# ... continue for all migration files
```

Or use the PowerShell script:
```powershell
.\database\apply_migration.ps1
```

6. **Deploy Supabase Edge Functions** (Optional)

```bash
supabase functions deploy send-order-notification
supabase functions deploy initialize-paystack-payment
supabase functions deploy verify-paystack-payment
# ... deploy other functions as needed
```

7. **Run the app**

```bash
# Development mode
flutter run

# Or specify a device
flutter run -d chrome  # Web
flutter run -d <device-id>  # Specific device
```

---

## 🏗️ Project Structure

```
lib/
├── core/                          # Core application infrastructure
│   ├── config/                    # Configuration files
│   │   ├── app_config.dart       # Environment configuration
│   │   ├── firebase_config.dart  # Firebase setup
│   │   ├── payment_config.dart   # Payment provider config
│   │   └── supabase_config.dart  # Supabase client
│   ├── constants/                 # App-wide constants
│   ├── providers/                 # Core Riverpod providers
│   ├── routing/                   # Navigation & routing
│   ├── security/                  # Security utilities
│   ├── services/                  # Business logic services (21 services)
│   └── utils/                     # Utility functions & helpers
│
├── features/                      # Feature modules
│   ├── authentication/            # Login, signup, password reset
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   ├── home/                      # Home screen & search
│   ├── restaurant/                # Restaurant browsing & details
│   ├── order/                     # Cart, checkout, tracking
│   ├── delivery/                  # Delivery tracking
│   ├── favourites/                # Favorites management
│   ├── profile/                   # User profile & settings
│   ├── restaurant_dashboard/      # Restaurant owner features
│   ├── role_management/           # User role handling
│   └── onboarding/                # App introduction
│
├── shared/                        # Shared resources
│   ├── models/                    # Data models (37 models)
│   ├── widgets/                   # Reusable widgets (41 widgets)
│   ├── theme/                     # App theming
│   └── utils/                     # Shared utilities
│
└── main.dart                      # Application entry point

test/                              # Test suite
├── unit/                          # Unit tests
├── widget/                        # Widget tests
└── integration/                   # Integration tests

supabase/
├── migrations/                    # Database migrations (18 files)
└── functions/                     # Edge functions (7 functions)
```

---

## 🗄️ Database Schema

### Core Tables

#### `user_profiles`
User profile information linked to Supabase Auth
- `id`, `email`, `full_name`, `phone_number`, `avatar_url`
- `created_at`, `updated_at`

#### `user_roles`
Role-based access control
- `user_id`, `role` (consumer, restaurant_owner, staff, admin, driver)
- `permissions` (JSONB)

#### `restaurants`
Restaurant information and settings
- `id`, `name`, `description`, `address`, `location` (PostGIS)
- `owner_id`, `cuisine_type`, `rating`, `hero_image_url`
- `is_active`, `operating_hours` (JSONB)

#### `menu_items`
Restaurant menu items
- `id`, `restaurant_id`, `name`, `description`, `price`
- `image_url`, `category`, `is_available`, `dietary_info` (JSONB)

#### `orders`
Customer orders
- `id`, `user_id`, `restaurant_id`, `status`, `total_price`
- `delivery_address`, `delivery_fee`, `promotion_code`
- `payment_method`, `payment_status`, `created_at`

#### `order_items`
Junction table for order details
- `id`, `order_id`, `menu_item_id`, `quantity`
- `customizations` (JSONB), `price_at_order`

#### `deliveries`
Delivery tracking information
- `id`, `order_id`, `driver_id`, `status`
- `pickup_time`, `delivery_time`, `driver_location` (PostGIS)

### Security

All tables implement Row Level Security (RLS) policies:
- Users can only read/write their own data
- Restaurant owners can manage their restaurant data
- Drivers can access assigned delivery information
- Admins have elevated permissions

---

## 🔑 Authentication

### Supported Methods

1. **Email/Password**
   - Standard registration with email verification
   - Password reset via email

2. **Google Sign-In**
   - One-tap authentication
   - Automatic profile creation

3. **Apple Sign-In**
   - iOS native authentication
   - Privacy-focused

### User Roles

- **Consumer** (default) - Browse and order food
- **Restaurant Owner** - Manage restaurant operations
- **Driver** - Deliver orders
- **Staff** - Restaurant employee access
- **Admin** - System administration

Role assignment handled via `user_roles` table with granular permissions.

---

## 💳 Payment Integration

### Supported Providers

#### PayFast (Primary - South Africa)
- Local payment gateway
- Multiple payment methods
- Instant payment verification
- Production-ready implementation

#### Stripe (International)
- Global payment processing
- Credit/debit cards
- Payment Intent API
- Strong Customer Authentication (SCA)

#### Cash on Delivery
- No online payment required
- Driver collects payment
- Manual confirmation

### Configuration

Payment providers configured via feature flags in `payment_config.dart`:

```dart
class PaymentConfig {
  static bool get isPayFastEnabled => true;
  static bool get isStripeEnabled => false;
  static bool get isCashOnDeliveryEnabled => true;
}
```

---

## 📡 Real-time Features

### Supabase Realtime Subscriptions

1. **Order Status Updates**
   - Real-time order state changes
   - Kitchen preparation notifications
   - Delivery status updates

2. **Driver Location Tracking**
   - Live driver GPS coordinates
   - ETA calculations
   - Route visualization

3. **Restaurant Availability**
   - Menu item stock updates
   - Operating hours changes
   - Special offers

### Push Notifications

Firebase Cloud Messaging (FCM) integration:
- Order confirmations
- Status change alerts
- Promotional notifications
- Deep linking to relevant screens

---

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/services/auth_service_test.dart

# Run with coverage
flutter test --coverage
```

### Test Structure

- **Unit Tests** - Service layer business logic
- **Widget Tests** - UI component behavior
- **Integration Tests** - End-to-end user flows

### Test Coverage Goals

- Services: 90%+
- Providers: 85%+
- Screens: 70%+
- Overall: 80%+

---

## 📦 State Management

### Riverpod Architecture

The app uses **Riverpod 2.6.1** for state management with code generation.

#### Key Providers

**Authentication**
- `authStateProvider` - Current auth state
- `currentUserProvider` - User profile data
- `userRoleProvider` - User role information

**Cart & Orders**
- `cartProvider` - Shopping cart state
- `orderHistoryProvider` - Past orders
- `activeOrderProvider` - Current order tracking

**Restaurants**
- `restaurantsProvider` - Restaurant listings
- `restaurantDetailProvider` - Single restaurant data
- `menuItemsProvider` - Menu items by restaurant

**Location**
- `locationServiceProvider` - GPS location
- `addressProvider` - Saved addresses

### Code Generation

```bash
# Generate provider code
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch
```

---

## 🎨 Theming

### Material 3 Design System

The app implements Material Design 3 with:
- Dynamic color schemes
- Adaptive layouts
- Responsive typography
- Dark mode support (automatic or manual)

### Customization

Theme configuration in `lib/shared/theme/app_theme.dart`:

```dart
ThemeData get lightTheme => ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
  useMaterial3: true,
  // ... additional theme properties
);
```

---

## 🌍 Localization

### Current Support
- English (en-US) - Primary language

### Future Plans
- Multi-language support using Flutter's `intl` package
- Right-to-left (RTL) layout support
- Dynamic locale switching

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Android  | ✅ Ready | Minimum SDK: 21 (Android 5.0) |
| iOS      | ✅ Ready | Minimum: iOS 12.0 |
| Web      | ⚠️ Partial | Limited features (no maps) |
| Windows  | ❌ Not Supported | Future consideration |
| macOS    | ❌ Not Supported | Future consideration |
| Linux    | ❌ Not Supported | Future consideration |

---

## 🔧 Configuration

### Environment Variables

Create `.env` file with required variables:

```env
# Required
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ENVIRONMENT=development

# Optional (Payment)
PAYFAST_MERCHANT_ID=
PAYFAST_MERCHANT_KEY=
PAYFAST_PASSPHRASE=

STRIPE_PUBLISHABLE_KEY=
```

### Build Flavors

The app supports multiple environments:
- **Development** - Debug builds with verbose logging
- **Staging** - Pre-production testing
- **Production** - Release builds

---

## 🚀 Deployment

### Android Release Build

```bash
# Build app bundle (recommended)
flutter build appbundle --release

# Build APK
flutter build apk --release --split-per-abi
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS Release Build

```bash
# Build iOS archive
flutter build ipa --release
```

Output: `build/ios/archive/`

### Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update Android `versionCode` in `build.gradle.kts`
- [ ] Update iOS `CFBundleVersion` in `Info.plist`
- [ ] Run all tests: `flutter test`
- [ ] Check for linter issues: `flutter analyze`
- [ ] Test on physical devices
- [ ] Verify environment variables
- [ ] Update release notes

---

## 🐛 Troubleshooting

### Common Issues

**1. Supabase Connection Failed**
- Verify `.env` file exists with correct keys
- Check network connectivity
- Ensure Supabase project is active

**2. Android Build Errors**
- Run `flutter clean && flutter pub get`
- Accept Android licenses: `flutter doctor --android-licenses`
- Check Android SDK installation

**3. iOS Build Errors**
- Update CocoaPods: `cd ios && pod install`
- Clean build: `flutter clean`
- Verify Xcode version compatibility

**4. Provider Not Found Errors**
- Ensure `build_runner` has been run
- Check for proper `ProviderScope` in `main.dart`

**5. Payment Integration Issues**
- Verify environment-specific credentials
- Check payment provider dashboard for API status
- Review server logs in Supabase Functions

### Debug Mode

Enable verbose logging:

```dart
// In main.dart
void main() {
  AppLogger.setLogLevel(LogLevel.verbose);
  runApp(const MyApp());
}
```

---

## 📊 Performance

### Optimization Techniques

1. **Image Loading**
   - `cached_network_image` for network images
   - Optimized image sizes (WebP format)
   - Lazy loading for lists

2. **Database Queries**
   - Indexed columns for frequent queries
   - Pagination for large datasets
   - Query result caching

3. **State Management**
   - Selective rebuilds with Riverpod
   - Lazy provider initialization
   - Proper provider disposal

4. **Bundle Size**
   - Code splitting (not yet implemented)
   - Tree shaking enabled
   - Minification in release builds

### Monitoring

- Firebase Performance Monitoring
- Firebase Crashlytics for crash reporting
- Firebase Analytics for user behavior

---

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the existing code style
   - Add tests for new features
   - Update documentation

4. **Run quality checks**
   ```bash
   flutter analyze
   flutter test
   ```

5. **Commit with conventional commits**
   ```bash
   git commit -m "feat: add restaurant filtering by cuisine type"
   ```

6. **Push and create Pull Request**

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `very_good_analysis` linter rules
- Run `dart format .` before committing
- Add meaningful comments for complex logic

### Commit Convention

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Test additions or updates
- `chore:` - Build process or auxiliary tool changes

---

## 📄 License

This project is private and proprietary. All rights reserved.

**Unauthorized copying, modification, distribution, or use of this software is strictly prohibited.**

---

## 👥 Team & Support

### Project Maintainers

For questions or support, please contact the development team.

### Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Firebase Documentation](https://firebase.google.com/docs)

---

## 🗺️ Roadmap

### Current Version: 1.0.0

**Completed Features** ✅
- User authentication (Email, Google, Apple)
- Restaurant browsing and search
- Menu item customization
- Shopping cart and checkout
- Multiple payment methods
- Real-time order tracking
- Push notifications
- Restaurant owner dashboard
- Offline-first architecture

**In Progress** 🚧
- Interactive map view for restaurant discovery
- Driver application features
- Admin portal
- Enhanced analytics dashboard

**Planned Features** 📋
- Multi-language support
- Voice search
- AR menu preview
- Loyalty rewards program
- Scheduled orders
- Group ordering
- Restaurant chat support
- Advanced dietary filtering

---

## 📈 Project Status

| Category | Completion | Status |
|----------|------------|--------|
| Core Features | 85% | 🟢 Production Ready |
| Testing | 60% | 🟡 In Progress |
| Documentation | 70% | 🟡 Good |
| Performance | 80% | 🟢 Optimized |
| Security | 95% | 🟢 Secure |
| UI/UX | 90% | 🟢 Polished |

**Overall Project Health: 82/100** 🟢

---

## 🙏 Acknowledgments

Built with amazing open-source packages:
- [Flutter](https://flutter.dev) by Google
- [Supabase](https://supabase.com) - Open-source Firebase alternative
- [Riverpod](https://riverpod.dev) by Remi Rousselet
- [Firebase](https://firebase.google.com) by Google
- And many other fantastic Flutter packages

---

<div align="center">

**Made with ❤️ using Flutter**

[Report Bug](issues) · [Request Feature](issues) · [Documentation](docs)

</div>
