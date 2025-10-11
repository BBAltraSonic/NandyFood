import 'package:intl/intl.dart';

/// Helper class to parse and manage restaurant operating hours
class OperatingHours {
  final Map<String, dynamic> hoursData;

  OperatingHours(this.hoursData);

  /// Days of the week in order
  static const List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// Get current day's operating hours
  /// Returns map with 'open' and 'close' keys
  Map<String, dynamic>? getTodayHours() {
    final today = _getCurrentDay();
    return _getHoursForDay(today);
  }

  /// Get hours for a specific day
  Map<String, dynamic>? _getHoursForDay(String day) {
    try {
      final dayData = hoursData[day.toLowerCase()];
      if (dayData == null) return null;

      if (dayData is Map) {
        return Map<String, dynamic>.from(dayData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if restaurant is currently open
  bool get isOpenNow {
    final todayHours = getTodayHours();
    if (todayHours == null) return false;

    final now = DateTime.now();
    final openTime = _parseTime(todayHours['open']);
    final closeTime = _parseTime(todayHours['close']);

    if (openTime == null || closeTime == null) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;

    // Handle cases where closing time is after midnight
    if (closeMinutes < openMinutes) {
      return currentMinutes >= openMinutes || currentMinutes < closeMinutes;
    }

    return currentMinutes >= openMinutes && currentMinutes < closeMinutes;
  }

  /// Get status text (e.g., "Open now", "Closed", "Opens at 10:00 AM")
  String get statusText {
    final todayHours = getTodayHours();

    if (todayHours == null) {
      return 'Closed today';
    }

    if (isOpenNow) {
      final closeTime = _parseTime(todayHours['close']);
      if (closeTime != null) {
        return 'Open until ${_formatTime(closeTime)}';
      }
      return 'Open now';
    } else {
      final openTime = _parseTime(todayHours['open']);
      if (openTime != null) {
        final now = DateTime.now();
        final openDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          openTime.hour,
          openTime.minute,
        );

        // Check if opening time has passed today
        if (now.isAfter(openDateTime)) {
          return 'Closed';
        }
        return 'Opens at ${_formatTime(openTime)}';
      }
      return 'Closed';
    }
  }

  /// Get formatted hours for today (e.g., "10:00 AM - 10:00 PM")
  String? getTodayHoursText() {
    final todayHours = getTodayHours();
    if (todayHours == null) return null;

    final openTime = _parseTime(todayHours['open']);
    final closeTime = _parseTime(todayHours['close']);

    if (openTime == null || closeTime == null) return null;

    return '${_formatTime(openTime)} - ${_formatTime(closeTime)}';
  }

  /// Get all hours for the week
  /// Returns list of maps with 'day', 'hours', and 'isToday' keys
  List<Map<String, dynamic>> getWeekHours() {
    final today = _getCurrentDay();

    return _daysOfWeek.map((day) {
      final hours = _getHoursForDay(day);
      String hoursText = 'Closed';

      if (hours != null) {
        final openTime = _parseTime(hours['open']);
        final closeTime = _parseTime(hours['close']);

        if (openTime != null && closeTime != null) {
          hoursText = '${_formatTime(openTime)} - ${_formatTime(closeTime)}';
        }
      }

      return {
        'day': _capitalize(day),
        'hours': hoursText,
        'isToday': day == today,
      };
    }).toList();
  }

  /// Parse time string (e.g., "10:00", "22:30") to DateTime
  DateTime? _parseTime(dynamic timeValue) {
    try {
      String timeString;
      if (timeValue is String) {
        timeString = timeValue;
      } else if (timeValue is Map && timeValue.containsKey('time')) {
        timeString = timeValue['time'] as String;
      } else {
        return null;
      }

      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      return DateTime(0, 0, 0, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Format time to 12-hour format with AM/PM
  String _formatTime(DateTime time) {
    final format = DateFormat('h:mm a');
    return format.format(time);
  }

  /// Get current day of week in lowercase
  String _getCurrentDay() {
    final now = DateTime.now();
    final dayIndex = now.weekday - 1; // weekday is 1-7, we need 0-6
    return _daysOfWeek[dayIndex];
  }

  /// Capitalize first letter of string
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
