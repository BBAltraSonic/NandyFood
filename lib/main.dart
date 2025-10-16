import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/firebase_options.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';
import 'package:food_delivery_app/core/providers/theme_provider.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/signup_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/splash_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/verify_email_screen.dart';
import 'package:food_delivery_app/features/home/presentation/screens/home_screen.dart';
import 'package:food_delivery_app/features/home/presentation/screens/search_screen.dart';
import 'package:food_delivery_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_detail_screen.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_list_screen.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/menu_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/cart_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/checkout_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_confirmation_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_tracking_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_history_screen.dart' as order_history;
import 'package:food_delivery_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/settings_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/order_history_screen.dart' as profile_order_history;
import 'package:food_delivery_app/features/profile/presentation/screens/address_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/add_edit_address_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/payment_methods_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/add_edit_payment_screen.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/features/role_management/presentation/screens/role_selection_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_registration_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_orders_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_menu_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/add_edit_menu_item_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_analytics_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_settings_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_info_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/operating_hours_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/delivery_settings_screen.dart';

Future<void> main() async {
  AppLogger.section('🚀 NANDYFOOD APP STARTING');
  AppLogger.function('main', 'ENTER');

  final startTime = DateTime.now();

  AppLogger.init('Initializing Flutter bindings...');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.success('Flutter bindings initialized');

  // Load environment variables
  AppLogger.init('Loading environment variables from .env file...');
  try {
    await dotenv.load(fileName: '.env');
    AppLogger.success(
      '.env file loaded successfully',
      details: 'Found ${dotenv.env.keys.length} environment variables',
    );
  } catch (e) {
    AppLogger.warning('.env file not found - using default configuration');
    AppLogger.debug('Will use hardcoded/default values for configuration');
  }

  // Initialize Firebase
  AppLogger.init('Initializing Firebase...');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.success('Firebase initialized successfully');
    
    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    AppLogger.success('FCM background handler registered');
  } catch (e, stack) {
    AppLogger.error('Failed to initialize Firebase', error: e, stack: stack);
  }

  // Initialize Notification Service
  AppLogger.init('Initializing notification service...');
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    AppLogger.success(
      'Notification service initialized',
      details: 'FCM token: ${notificationService.fcmToken?.substring(0, 20)}...',
    );
  } catch (e, stack) {
    AppLogger.error('Failed to initialize notifications', error: e, stack: stack);
  }

  // Payment system - currently using cash on delivery
  AppLogger.init('Initializing payment system...');
  AppLogger.success('Cash on delivery payment enabled');
  AppLogger.info(
    'Card payments can be added later via payment gateway integration',
  );

  // Initialize the DatabaseService
  AppLogger.init('Initializing database connection...');
  try {
    final dbService = DatabaseService();
    await dbService.initialize();
    AppLogger.success(
      'Database service initialized',
      details: 'Supabase client ready for operations',
    );
  } catch (e, stack) {
    AppLogger.error('Failed to initialize database', error: e, stack: stack);
  }

  final totalTime = DateTime.now().difference(startTime);
  AppLogger.performance('App initialization', totalTime);

  AppLogger.separator();
  AppLogger.init('Starting Flutter application...');
  runApp(const ProviderScope(child: FoodDeliveryApp()));
  AppLogger.function('main', 'EXIT');
}

class FoodDeliveryApp extends ConsumerStatefulWidget {
  const FoodDeliveryApp({super.key});

  @override
  ConsumerState<FoodDeliveryApp> createState() => _FoodDeliveryAppState();
}

// Export router creator for testing
GoRouter createRouter() {
  AppLogger.function('createRouter', 'ENTER');
  AppLogger.info('Setting up app navigation routes...');

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      // Splash & Onboarding
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) {
          // Check for role query parameter
          final roleParam = state.uri.queryParameters['role'];
          final preselectedRole = roleParam == 'restaurant' 
            ? UserRoleType.restaurantOwner 
            : null; // null = default to consumer
          
          return SignupScreen(preselectedRole: preselectedRole);
        },
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/auth/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // Home & Search
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // Restaurants
      GoRoute(
        path: '/restaurants',
        builder: (context, state) => const RestaurantListScreen(),
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final restaurantId = state.pathParameters['id']!;
          final restaurant = state.extra as Restaurant?;
          return RestaurantDetailScreen(
            restaurantId: restaurantId,
            restaurant: restaurant,
          );
        },
      ),
      GoRoute(
        path: '/restaurant/:id/menu',
        builder: (context, state) {
          final restaurantId = state.pathParameters['id']!;
          final restaurant = state.extra as Restaurant?;
          return MenuScreen(
            restaurantId: restaurantId,
            restaurant: restaurant,
          );
        },
      ),

      // Cart & Checkout
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order/confirmation',
        builder: (context, state) {
          final order = state.extra as Order?;
          return OrderConfirmationScreen(order: order);
        },
      ),
      GoRoute(
        path: '/order/track',
        builder: (context, state) {
          final order = state.extra as Order?;
          return OrderTrackingScreen(order: order);
        },
      ),
      GoRoute(
        path: '/order/history',
        builder: (context, state) => const order_history.OrderHistoryScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/app-settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/order-history',
        builder: (context, state) =>
            const profile_order_history.OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: '/profile/add-address',
        builder: (context, state) => const AddEditAddressScreen(),
      ),
      GoRoute(
        path: '/profile/edit-address/:id',
        builder: (context, state) {
          final addressId = state.pathParameters['id'];
          return AddEditAddressScreen(addressId: addressId);
        },
      ),
      GoRoute(
        path: '/profile/payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/profile/add-payment',
        builder: (context, state) => const AddEditPaymentScreen(),
      ),
      GoRoute(
        path: '/profile/edit-payment/:id',
        builder: (context, state) {
          final paymentId = state.pathParameters['id'];
          return AddEditPaymentScreen(paymentMethodId: paymentId);
        },
      ),

      // Role Management
      GoRoute(
        path: '/role/select',
        builder: (context, state) => const RoleSelectionScreen(),
      ),

      // Restaurant Dashboard
      GoRoute(
        path: '/restaurant/dashboard',
        builder: (context, state) => const RestaurantDashboardScreen(),
      ),
      GoRoute(
        path: '/restaurant/register',
        builder: (context, state) {
          final fromSignup = state.uri.queryParameters['fromSignup'] == 'true';
          return RestaurantRegistrationScreen(fromSignup: fromSignup);
        },
      ),
      GoRoute(
        path: '/restaurant/orders',
        builder: (context, state) {
          final status = state.uri.queryParameters['status'];
          return RestaurantOrdersScreen(initialStatus: status);
        },
      ),
      GoRoute(
        path: '/restaurant/menu',
        builder: (context, state) => const RestaurantMenuScreen(),
      ),
      GoRoute(
        path: '/restaurant/menu/add',
        builder: (context, state) {
          final restaurantId = state.extra as String;
          return AddEditMenuItemScreen(restaurantId: restaurantId);
        },
      ),
      GoRoute(
        path: '/restaurant/menu/edit/:itemId',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId'];
          final item = state.extra as MenuItem?;
          return AddEditMenuItemScreen(
            itemId: itemId,
            existingItem: item,
            restaurantId: item?.restaurantId ?? '',
          );
        },
      ),
      GoRoute(
        path: '/restaurant/analytics',
        builder: (context, state) {
          // TODO: Get restaurantId from authenticated user's session instead of query params
          final restaurantId = state.uri.queryParameters['restaurantId'] ?? 'default_restaurant';
          return RestaurantAnalyticsScreen(restaurantId: restaurantId);
        },
      ),
      GoRoute(
        path: '/restaurant/settings',
        builder: (context, state) => const RestaurantSettingsScreen(),
      ),
      GoRoute(
        path: '/restaurant/settings/info',
        builder: (context, state) => const RestaurantInfoScreen(),
      ),
      GoRoute(
        path: '/restaurant/settings/hours',
        builder: (context, state) => const OperatingHoursScreen(),
      ),
      GoRoute(
        path: '/restaurant/settings/delivery',
        builder: (context, state) => const DeliverySettingsScreen(),
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.uri.toString();
      
      // Check if database is initialized before accessing client
      Session? authState;
      bool isAuthenticated = false;
      
      if (DatabaseService().isInitialized) {
        authState = DatabaseService().client.auth.currentSession;
        isAuthenticated = authState != null;
      }

      AppLogger.navigation(
        location,
        isAuthenticated ? 'Authenticated' : 'Guest',
      );

      // Only require authentication for profile and order-specific screens
      final protectedRoutes = [
        '/profile',
        '/profile/payment-methods',
        '/profile/add-payment',
        '/profile/addresses',
        '/profile/settings',
        '/order/history',
        '/restaurant/dashboard',
        '/restaurant/orders',
        '/restaurant/menu',
        '/restaurant/analytics',
        '/restaurant/settings',
      ];

      // Check if current route requires authentication
      final requiresAuth = protectedRoutes.any(
        (route) => location.startsWith(route),
      );

      if (requiresAuth && !isAuthenticated) {
        AppLogger.info(
          'Protected route accessed - redirecting to login',
          data: {'requested': location},
        );
        return '/auth/login?redirect=$location';
      }

      // If user is authenticated and on auth screens, redirect to home
      if (isAuthenticated && location.startsWith('/auth')) {
        AppLogger.info(
          'Authenticated user on auth screen - redirecting to home',
        );
        return '/home';
      }

      // Allow guest access to all other routes
      return null;
    },
  );

  AppLogger.success('Router created with ${router.configuration.routes.length} routes configured');
  AppLogger.function('createRouter', 'EXIT', result: 'GoRouter instance');
  return router;
}

class _FoodDeliveryAppState extends ConsumerState<FoodDeliveryApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    AppLogger.lifecycle(
      'FoodDeliveryApp.initState',
      details: 'Creating router and initializing app state',
    );
    _router = createRouter();
    AppLogger.success(
      'Router created with ${_router.configuration.routes.length} routes',
    );
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.widgetBuild('FoodDeliveryApp');

    final themeState = ref.watch(themeProvider);
    AppLogger.info(
      'Building app with theme',
      data: {
        'mode': themeState.themeMode.toString(),
        'flutter_mode': themeState.flutterThemeMode.toString(),
      },
    );

    return MaterialApp.router(
      title: 'Food Delivery App',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeState.flutterThemeMode,
      routerConfig: _router,
    );
  }

  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFFFF6B35);
    const secondaryColor = Color(0xFFF7931E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A1A),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFF4A4A4A),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFF6A6A6A),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF8A8A8A),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF1A1A1A),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withValues(alpha: 0.1),
        labelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFFFF6B35);
    const secondaryColor = Color(0xFFF7931E);
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        background: darkBackground,
      ),
      scaffoldBackgroundColor: darkBackground,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Color(0xFFE0E0E0),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Color(0xFFB0B0B0),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF909090),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade800, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: darkSurface,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
