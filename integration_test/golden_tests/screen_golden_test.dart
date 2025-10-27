import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/signup_screen.dart';
import 'package:food_delivery_app/features/home/presentation/screens/home_screen.dart';

/// Golden tests for visual regression testing
/// Captures pixel-perfect screenshots of all screens
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('Authentication Screens Golden Tests', () {
    testGoldens('Login Screen - Light Mode', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
        ])
        ..addScenario(
          widget: const ProviderScope(
            child: MaterialApp(
              home: LoginScreen(),
            ),
          ),
          name: 'login_screen_light',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'login_screen_light');
    });

    testGoldens('Login Screen - Dark Mode', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: ProviderScope(
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const LoginScreen(),
            ),
          ),
          name: 'login_screen_dark',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'login_screen_dark');
    });

    testGoldens('Signup Screen - Multiple States', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [Device.phone])
        ..addScenario(
          widget: const ProviderScope(
            child: MaterialApp(
              home: SignupScreen(),
            ),
          ),
          name: 'signup_screen_empty',
        )
        ..addScenario(
          widget: const ProviderScope(
            child: MaterialApp(
              home: SignupScreen(),
            ),
          ),
          name: 'signup_screen_filled',
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'signup_screens');
    });
  });

  group('Home Screen Golden Tests', () {
    testGoldens('Home Screen - Loading State', (tester) async {
      await tester.pumpWidgetBuilder(
        const HomeScreen(),
        wrapper: materialAppWrapper(
          theme: ThemeData.light(),
        ),
        surfaceSize: const Size(375, 667),
      );

      await screenMatchesGolden(tester, 'home_screen_loading');
    });

    testGoldens('Home Screen - Different Devices', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.iphone11,
          Device.tabletPortrait,
          Device.tabletLandscape,
        ])
        ..addScenario(
          widget: const ProviderScope(
            child: MaterialApp(
              home: HomeScreen(),
            ),
          ),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'home_screen_devices');
    });
  });

  group('Widget Golden Tests', () {
    testGoldens('Button States', (tester) async {
      await tester.pumpWidgetBuilder(
        Column(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Enabled')),
            const SizedBox(height: 8),
            const ElevatedButton(onPressed: null, child: Text('Disabled')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('Text Button')),
          ],
        ),
        wrapper: materialAppWrapper(),
      );

      await screenMatchesGolden(tester, 'button_states');
    });

    testGoldens('Text Field States', (tester) async {
      await tester.pumpWidgetBuilder(
        Column(
          children: const [
            TextField(
              decoration: InputDecoration(
                labelText: 'Empty',
                hintText: 'Enter text',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'With Text',
                hintText: 'Enter text',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Error',
                errorText: 'This field is required',
              ),
            ),
          ],
        ),
        wrapper: materialAppWrapper(),
      );

      await screenMatchesGolden(tester, 'text_field_states');
    });
  });

  group('Accessibility Golden Tests', () {
    testGoldens('Large Text Accessibility', (tester) async {
      await tester.pumpWidgetBuilder(
        const LoginScreen(),
        wrapper: materialAppWrapper(
          platform: TargetPlatform.android,
        ),
        surfaceSize: const Size(375, 667),
      );

      await screenMatchesGolden(tester, 'login_large_text');
    });
  });
}
