import 'package:flutter/services.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Service to play audio notifications for restaurant orders
/// Uses platform channels to play system sounds
class AudioNotificationService {
  static const _platform = MethodChannel('com.nandyfood.app/notifications');

  /// Play new order notification sound
  Future<void> playNewOrderSound() async {
    try {
      // Try to use platform-specific sound
      await _platform.invokeMethod('playNewOrderSound');
      AppLogger.info('🔊 Playing new order sound via platform');
    } on PlatformException catch (e) {
      // Fallback: use system feedback
      AppLogger.warning('Platform sound not available, using fallback: ${e.message}');
      await HapticFeedback.vibrate();
      
      // Trigger multiple haptic feedbacks for emphasis
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.vibrate();
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        HapticFeedback.vibrate();
      });
    } catch (e) {
      AppLogger.error('Error playing notification sound: $e');
    }
  }

  /// Play order status change sound (softer notification)
  Future<void> playStatusChangeSound() async {
    try {
      await _platform.invokeMethod('playStatusChangeSound');
      AppLogger.info('🔊 Playing status change sound');
    } on PlatformException catch (e) {
      // Fallback: single haptic
      AppLogger.warning('Platform sound not available: ${e.message}');
      await HapticFeedback.lightImpact();
    } catch (e) {
      AppLogger.error('Error playing status sound: $e');
    }
  }

  /// Vibrate device for new order
  Future<void> vibrateForNewOrder() async {
    try {
      // Pattern: vibrate 200ms, pause 100ms, repeat 3 times
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      AppLogger.error('Error vibrating: $e');
    }
  }

  /// Check if platform-specific audio is available
  Future<bool> isPlatformAudioAvailable() async {
    try {
      final result = await _platform.invokeMethod<bool>('isAudioAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
