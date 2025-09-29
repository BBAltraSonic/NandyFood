# Quickstart Guide: Modern Food Delivery App

## Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (bundled with Flutter)
- Git
- Supabase account (for backend services)
- Stripe account (for payment processing)
- Android Studio or VS Code with Flutter plugin

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd <project-directory>
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment Variables
Create a `.env` file in the project root with the following variables:
```
SUPABASE_URL=<your_supabase_project_url>
SUPABASE_ANON_KEY=<your_supabase_anon_key>
STRIPE_PUBLISHABLE_KEY=<your_stripe_publishable_key>
```

### 4. Run the Application
```bash
flutter run
```

## Testing the Core Features

### 1. User Registration and Login
1. Launch the app
2. Navigate to the sign-up screen
3. Create a new account with a valid email and password
4. Verify login functionality by signing out and signing back in

### 2. Browse Restaurants
1. On the home screen, verify that nearby restaurants are displayed
2. Check that the map shows restaurant locations
3. Test filtering and sorting functionality

### 3. Place an Order
1. Select a restaurant from the list
2. Browse the menu and add items to the cart
3. Proceed to checkout and complete the order
4. Verify order confirmation

### 4. Track Order
1. Navigate to the order tracking screen
2. Verify real-time location tracking of the delivery
3. Check that status updates are displayed correctly

## API Contract Endpoints

### Authentication
- `POST /auth/signup` - Create new user account
- `POST /auth/login` - Authenticate user
- `POST /auth/logout` - Log out user
- `GET /auth/profile` - Get user profile
- `PUT /auth/profile` - Update user profile

### Restaurants
- `GET /restaurants` - Get list of available restaurants
- `GET /restaurants/{id}` - Get specific restaurant details
- `GET /restaurants/{id}/menu` - Get restaurant menu

### Orders
- `POST /orders` - Create new order
- `GET /orders` - Get user's order history
- `GET /orders/{id}` - Get specific order details
- `PUT /orders/{id}/cancel` - Cancel an order

### Payments
- `POST /payments/process` - Process payment for an order

### Delivery
- `GET /delivery/{orderId}` - Get delivery status for an order
- `PUT /delivery/{orderId}/location` - Update delivery location (driver only)

## Running Tests
```bash
# Run all unit tests
flutter test

# Run widget tests
flutter test --target=test/widget/

# Run integration tests
flutter drive --target=test/integration/
```

## Development Commands
```bash
# Generate code (for models, services, etc.)
flutter packages pub run build_runner build

# Format code
flutter format lib/

# Analyze code
flutter analyze

# Build for iOS
flutter build ios

# Build for Android
flutter build apk