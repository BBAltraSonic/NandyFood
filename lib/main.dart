import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:food_delivery_app/firebase_options.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/signup_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/splash_screen.dart';
import 'package:food_delivery_app/features/home/presentation/screens/home_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/add_edit_payment_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_tracking_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/cart_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_history_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/promotions_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/promo_detail_screen.dart';

import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/routing/route_guards.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_orders_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_menu_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_analytics_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/restaurant_analytics_session_wrapper.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_settings_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_info_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/delivery_settings_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/operating_hours_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_registration_screen.dart';


import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_detail_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/address_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/payment_methods_screen.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
String? pendingInitialNotificationPayload;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
}

String? _payloadToRoute(String payload) {
  final p = payload.trim();
  if (p.startsWith('order:')) {
    final id = p.substring('order:'.length);
    if (id.isNotEmpty) return RoutePaths.orderTrackWithId(id);
  }
  if (p.startsWith('promo:')) {
    final id = p.substring('promo:'.length);
    if (id.isNotEmpty) return RoutePaths.promo(id);
  }
  if (p.startsWith('/')) return p;
  return null;
}

void navigateForPayload(String? payload) {
  if (payload == null || payload.isEmpty) return;
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return;
  final route = _payloadToRoute(payload);
  if (route != null) {
    ctx.go(route);
  }
}

String? derivePayloadFromMessage(RemoteMessage message) {
  final data = message.data;
  if (data.containsKey('route') && data['route'] is String) {
    return data['route'] as String;
  }
  final type = data['type'] as String?;
  if ((type == 'order' || type == 'order_status') && data['order_id'] != null) {
    return 'order:${data['order_id']}';
  }
  if ((type == 'promo' || type == 'promotion') && data['promo_id'] != null) {
    return 'promo:${data['promo_id']}';
  }
  if (data['order_id'] != null) return 'order:${data['order_id']}';
  if (data['promo_id'] != null) return 'promo:${data['promo_id']}';
  return null;
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Register FCM background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request notification permissions (best-effort)
  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {}

  // Capture initial message for cold start deep link
  try {
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      pendingInitialNotificationPayload = derivePayloadFromMessage(initialMsg);
    }
  } catch (_) {}

  // Initialize the DatabaseService
  final dbService = DatabaseService();
  try {
    await dbService.initialize();
  } catch (e) {
    print('Error initializing database service: $e');
  }

    // Handle initial FCM deep link if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingInitialNotificationPayload != null) {
        navigateForPayload(pendingInitialNotificationPayload);
        pendingInitialNotificationPayload = null;
      }
    });

    // Foreground/background message handling is registered inside app State
    // to access BuildContext safely (see _FoodDeliveryAppState.initState).
  // Initialize the NotificationService with tap navigation

  final notificationService = NotificationService();
  try {
    await notificationService.initialize(onNotificationTap: (payload) {
      navigateForPayload(payload);
    });
  } catch (e) {
    print('Error initializing notification service: $e');
  }

  runApp(ProviderScope(child: FoodDeliveryApp()));
}

class FoodDeliveryApp extends ConsumerStatefulWidget {
  const FoodDeliveryApp({super.key});

  @override
  ConsumerState<FoodDeliveryApp> createState() => _FoodDeliveryAppState();
}

class _FoodDeliveryAppState extends ConsumerState<FoodDeliveryApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    // Handle initial FCM deep link if present
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingInitialNotificationPayload != null) {
        navigateForPayload(pendingInitialNotificationPayload);
        pendingInitialNotificationPayload = null;
      }
    });

    // Foreground messages: show local notification + in-app banner with action
    FirebaseMessaging.onMessage.listen((message) {
      final payload = derivePayloadFromMessage(message);
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? 'Tap to view';
      NotificationService().showNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        payload: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => navigateForPayload(payload),
          ),
        ),
      );
    });

    // When app opened via notification tap from BG
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final payload = derivePayloadFromMessage(message);
      navigateForPayload(payload);
    });

  }

  GoRouter _createRouter() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
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
          path: '/order/track',
          builder: (context, state) => OrderTrackingScreen(order: state.extra as Order?),
        ),
        GoRoute(
          path: '/order/track/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return OrderTrackingScreen(orderId: id);
          },
        ),
        GoRoute(
          path: RoutePaths.restaurantRegister,
          builder: (context, state) => const RestaurantRegistrationScreen(),
        ),
        GoRoute(
          path: RoutePaths.restaurantDashboard,
          builder: (context, state) => const RestaurantDashboardScreen(),
          redirect: (context, state) => RouteGuards.requireRestaurantRole(state),
        ),
        GoRoute(
          path: RoutePaths.restaurantOrders,
          builder: (context, state) => const RestaurantOrdersScreen(),
          redirect: (context, state) => RouteGuards.requireRestaurantRole(state),
        ),
        GoRoute(
          path: RoutePaths.restaurantMenu,
          builder: (context, state) => const RestaurantMenuScreen(),
          redirect: (context, state) => RouteGuards.requireRestaurantRole(state),
        ),
        GoRoute(
          path: RoutePaths.restaurantAnalytics,
          builder: (context, state) => const RestaurantAnalyticsSessionWrapper(),
          redirect: (context, state) => RouteGuards.requireRestaurantRole(state),
        ),
        GoRoute(
          path: RoutePaths.restaurantSettings,
          builder: (context, state) => const RestaurantSettingsScreen(),
          redirect: (context, state) => RouteGuards.requireRestaurantRole(state),
        ),

        GoRoute(
          path: '/restaurant/:id',
          builder: (context, state) {
            final restaurantId = state.pathParameters['id'] ?? '';
            final restaurant = state.extra as Restaurant?;
            return RestaurantDetailScreen(
              restaurantId: restaurantId,
              restaurant: restaurant,
            );
          },
        ),
        GoRoute(
          path: '/order/cart',
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/addresses',
          builder: (context, state) => const AddressScreen(),
        ),
        GoRoute(
          path: '/profile/payment-methods',
          builder: (context, state) => const PaymentMethodsScreen(),
        ),
        GoRoute(
          path: '/promo/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return PromoDetailScreen(promoId: id);
          },
        ),
        GoRoute(
          path: '/order/history',
          builder: (context, state) => const OrderHistoryScreen(),
        ),
        GoRoute(
          path: '/promotions',
          builder: (context, state) => const PromotionsScreen(),
        ),
      ],
      // Add redirect logic based on authentication state
      redirect: (BuildContext context, GoRouterState state) {
        try {
          final authState = DatabaseService().client.auth.currentSession;
          final location = state.uri.toString();

          // If user is not authenticated and not on auth screens, redirect to login
          if (authState == null &&
              !location.startsWith('/auth') &&
              location != '/') {
            return RoutePaths.authLogin;
          }

          // If user is authenticated and on auth screens, redirect to home
          if (authState != null && location.startsWith('/auth')) {
            return RoutePaths.home;
          }
        } catch (e) {
          // If there's an error accessing the client (e.g., invalid Supabase config),
          // default to showing login screen
          final location = state.uri.toString();
          if (!location.startsWith('/auth') && location != '/') {
            return RoutePaths.authLogin;
          }
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Food Delivery App',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      textTheme: Typography.blackCupertino,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
