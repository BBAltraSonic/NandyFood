# Nandy Food - Modern Food Delivery Application

A comprehensive food delivery application built with Flutter, featuring restaurant discovery, menu browsing, order management, user authentication, and payment processing.

## 🚀 Features

- **User Authentication**: Secure login/signup with profile management
- **Restaurant Discovery**: Browse restaurants with search and filtering capabilities
- **Menu Management**: View detailed menus with item descriptions and pricing
- **Shopping Cart**: Add/remove items with real-time price calculation
- **Order Management**: Place orders and track delivery status
- **Payment Processing**: Integrated payment system for seamless transactions
- **Order History**: View past orders and re-order favorite meals
- **Profile Management**: Manage personal information, addresses, and payment methods

## 📱 Screens & Navigation

- Splash Screen
- Login/Signup Screens
- Home Screen with restaurant listings
- Search Functionality
- Restaurant Detail Screens
- Menu Screens
- Cart & Checkout
- Order Tracking
- Profile & Settings
- Order History

## 🏗️ Architecture

The application follows a clean architecture pattern with:

- **Presentation Layer**: UI and state management using Provider pattern
- **Domain Layer**: Business logic and use cases
- **Data Layer**: Repository implementations and service classes

### Key Components:

- **State Management**: Provider for efficient state handling
- **Navigation**: Bottom Navigation for main sections
- **Themes**: Customizable app theme
- **Models**: Data models with JSON serialization
- **Services**: Authentication, Database, Storage, Payment, and Delivery Tracking

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/     # Configuration and constants
│   ├── providers/     # Core state providers
│   └── services/      # Core services (auth, database, etc.)
├── features/
│   ├── authentication/ # Auth screens, providers, widgets
│   ├── home/          # Home screen and search
│   ├── order/         # Order management
│   ├── profile/       # Profile management
│   └── restaurant/    # Restaurant discovery
├── shared/
│   ├── models/        # Shared data models
│   ├── theme/         # App theme
│   └── widgets/       # Reusable UI components
└── main.dart          # App entry point
```

## 🛠️ Technologies Used

- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Provider**: State management solution
- **JSON Serialization**: For data models
- **Platform-specific UI**: iOS and Android implementations

## 🧪 Testing

Comprehensive testing is implemented with:
- Unit tests for services and providers
- Widget tests for UI components
- Integration tests for critical user flows

## 📦 Dependencies

- Flutter SDK
- Provider for state management
- HTTP client for API communication
- JSON serialization for data handling
- Platform-specific plugins

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter plugin
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/BBAltraSonic/NandyFood.git
   cd NandyFood
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

### Development

For development, you can run the app in debug mode:

```bash
flutter run --debug
```

To run tests:
```bash
flutter test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions, please file an issue in the repository.

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- All open-source contributors whose libraries power this application
- The community for continuous feedback and support