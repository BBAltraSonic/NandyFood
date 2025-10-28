# Claude Context for NandyFood Project

This file provides context and guidance for Claude AI when working with the NandyFood Flutter application.

## Project Overview

**NandyFood** is a comprehensive food delivery platform built with Flutter and Supabase. It's a production-ready application supporting multiple user roles (customers, restaurant owners, delivery drivers, administrators) with real-time features and offline-first architecture.

## Key Technologies

- **Flutter**: 3.35.5 (Mobile app framework)
- **Dart**: 3.8.0 (Programming language)
- **Riverpod**: 2.6.1 (State management)
- **Supabase**: 2.10.3 (Backend services - auth, database, storage, realtime)
- **Firebase**: Push notifications and analytics
- **Hive**: Local caching for offline support

## Architecture

### Clean Architecture Pattern
```
lib/
├── core/           # Infrastructure, config, services
├── features/       # Feature modules (auth, restaurant, order, etc.)
├── shared/         # Shared models, widgets, theme
└── main.dart       # Entry point
```

### Key Services (21 total)
- `AuthService` - Authentication management
- `RestaurantService` - Restaurant operations
- `OrderService` - Order processing
- `PaymentService` - Payment processing
- `LocationService` - GPS and address management
- `NotificationService` - Push notifications
- And 15+ other specialized services

### State Management
Uses Riverpod with code generation. Key providers:
- `authStateProvider` - Authentication state
- `cartProvider` - Shopping cart
- `restaurantsProvider` - Restaurant listings
- `orderHistoryProvider` - User orders

## Database Schema

### Core Tables
- `user_profiles` - User information
- `user_roles` - Role-based access (consumer, restaurant_owner, driver, admin)
- `restaurants` - Restaurant data
- `menu_items` - Menu items
- `orders` - Customer orders
- `order_items` - Order details
- `deliveries` - Delivery tracking

### Security
All tables implement Row Level Security (RLS) policies for data protection.

## Development Guidelines

### When Making Changes

1. **Code Style**: Follow Effective Dart guidelines, use `very_good_analysis` linter
2. **Testing**: Add unit tests for new services, widget tests for UI components
3. **State Management**: Use Riverpod providers, generate code with `dart run build_runner build`
4. **Error Handling**: Use proper error handling with user-friendly messages
5. **Logging**: Use `AppLogger` for debugging with appropriate log levels

### Common Tasks

#### Adding New Features
1. Create feature module under `lib/features/`
2. Add models in `lib/shared/models/`
3. Create service in `lib/core/services/`
4. Add Riverpod providers
5. Write tests
6. Update documentation

#### Database Changes
1. Create migration in `supabase/migrations/`
2. Update corresponding models
3. Update RLS policies
4. Test with different user roles

#### Adding New Providers
1. Create provider using Riverpod syntax
2. Add to appropriate feature module
3. Run `dart run build_runner build --delete-conflicting-outputs`
4. Write unit tests

### Environment Setup

Required environment variables in `.env`:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
ENVIRONMENT=development
```

### Testing Commands

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/unit/services/auth_service_test.dart
```

### Build Commands

```bash
# Development
flutter run

# Release builds
flutter build appbundle --release  # Android
flutter build ipa --release        # iOS
```

## Important Notes

### Security Considerations
- Never commit API keys or sensitive data
- Use Supabase RLS policies for data access control
- Validate all user inputs
- Use secure storage for sensitive local data

### Performance
- Use lazy loading for large lists
- Cache network images with `cached_network_image`
- Implement proper pagination
- Monitor bundle size

### Real-time Features
- Order status updates via Supabase Realtime
- Driver location tracking
- Push notifications via Firebase

## Current Status

- **Core Features**: 85% complete, production ready
- **Testing**: 60% complete, in progress
- **Documentation**: 70% complete
- **Performance**: 80% optimized

## Common Issues & Solutions

1. **Provider Not Found**: Run `dart run build_runner build`
2. **Supabase Connection**: Check `.env` file and network
3. **Build Errors**: Run `flutter clean && flutter pub get`
4. **Payment Issues**: Verify environment-specific credentials

## File Locations

- **Main App**: `lib/main.dart`
- **App Config**: `lib/core/config/app_config.dart`
- **Routing**: `lib/core/routing/app_router.dart`
- **Theme**: `lib/shared/theme/app_theme.dart`
- **Models**: `lib/shared/models/`
- **Services**: `lib/core/services/`
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`

## Documentation

- **README.md**: Comprehensive project documentation
- **docs/**: Additional documentation files
- **SPEC_DRIVEN_COMPLETION_PLAN.md**: Implementation roadmap

---

When working on this project, prioritize security, performance, and user experience. The codebase follows clean architecture principles and is designed for scalability.