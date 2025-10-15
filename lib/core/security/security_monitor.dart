import 'dart:async';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/services/auth_service.dart';

/// Security monitoring and threat detection service
class SecurityMonitor {
  static final SecurityMonitor _instance = SecurityMonitor._internal();
  factory SecurityMonitor() => _instance;
  SecurityMonitor._internal();

  final List<SecurityEvent> _securityEvents = [];
  final Map<String, int> _failedLoginAttempts = {};
  final Map<String, DateTime> _lastActivityTime = {};
  
  Timer? _cleanupTimer;

  /// Initialize security monitoring
  void initialize() {
    AppLogger.info('Security monitoring initialized');
    
    // Clean up old events every hour
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupOldEvents(),
    );
  }

  /// Log a security event
  void logSecurityEvent(SecurityEventType type, String userId, {
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    final event = SecurityEvent(
      type: type,
      userId: userId,
      timestamp: DateTime.now(),
      details: details,
      metadata: metadata,
    );

    _securityEvents.add(event);
    
    // Log to console/monitoring service
    AppLogger.warning(
      'Security Event: ${type.name}',
      details: 'User: $userId, Details: $details',
    );

    // Check for suspicious patterns
    _analyzeThreatPatterns(userId, type);

    // Keep only recent events (last 24 hours)
    if (_securityEvents.length > 1000) {
      _securityEvents.removeRange(0, _securityEvents.length - 1000);
    }
  }

  /// Track failed login attempt
  void trackFailedLogin(String identifier) {
    _failedLoginAttempts[identifier] = 
        (_failedLoginAttempts[identifier] ?? 0) + 1;
    
    final attempts = _failedLoginAttempts[identifier]!;
    
    logSecurityEvent(
      SecurityEventType.failedLogin,
      identifier,
      details: 'Attempt $attempts',
    );

    // Trigger account lockout after 5 failed attempts
    if (attempts >= 5) {
      logSecurityEvent(
        SecurityEventType.accountLockout,
        identifier,
        details: 'Too many failed login attempts',
      );
    }
  }

  /// Clear failed login attempts (after successful login)
  void clearFailedLoginAttempts(String identifier) {
    _failedLoginAttempts.remove(identifier);
  }

  /// Check if account is locked out
  bool isAccountLockedOut(String identifier) {
    return (_failedLoginAttempts[identifier] ?? 0) >= 5;
  }

  /// Track user activity for session monitoring
  void trackUserActivity(String userId) {
    _lastActivityTime[userId] = DateTime.now();
  }

  /// Check for inactive sessions
  bool isSessionInactive(String userId, {Duration timeout = const Duration(minutes: 30)}) {
    final lastActivity = _lastActivityTime[userId];
    if (lastActivity == null) return false;
    
    return DateTime.now().difference(lastActivity) > timeout;
  }

  /// Analyze patterns for potential threats
  void _analyzeThreatPatterns(String userId, SecurityEventType type) {
    // Check for rapid successive failures
    final recentEvents = _securityEvents.where((e) =>
      e.userId == userId &&
      e.type == type &&
      DateTime.now().difference(e.timestamp) < const Duration(minutes: 5)
    ).length;

    if (recentEvents >= 3) {
      logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        userId,
        details: 'Multiple ${type.name} events in short time',
      );
    }
  }

  /// Clean up old security events
  void _cleanupOldEvents() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _securityEvents.removeWhere((event) => event.timestamp.isBefore(cutoff));
    
    AppLogger.debug('Cleaned up old security events');
  }

  /// Get security events for a user
  List<SecurityEvent> getUserSecurityEvents(String userId) {
    return _securityEvents
        .where((e) => e.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Generate security report
  Map<String, dynamic> generateSecurityReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentEvents = _securityEvents
        .where((e) => e.timestamp.isAfter(last24Hours))
        .toList();

    return {
      'report_generated': now.toIso8601String(),
      'total_events_24h': recentEvents.length,
      'failed_logins': recentEvents
          .where((e) => e.type == SecurityEventType.failedLogin)
          .length,
      'suspicious_activities': recentEvents
          .where((e) => e.type == SecurityEventType.suspiciousActivity)
          .length,
      'account_lockouts': recentEvents
          .where((e) => e.type == SecurityEventType.accountLockout)
          .length,
      'unauthorized_access': recentEvents
          .where((e) => e.type == SecurityEventType.unauthorizedAccess)
          .length,
      'data_breaches': recentEvents
          .where((e) => e.type == SecurityEventType.dataBreachAttempt)
          .length,
    };
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    AppLogger.info('Security monitoring disposed');
  }
}

/// Types of security events
enum SecurityEventType {
  failedLogin,
  successfulLogin,
  accountLockout,
  suspiciousActivity,
  unauthorizedAccess,
  dataBreachAttempt,
  paymentFraud,
  sessionHijacking,
  passwordReset,
  accountDeletion,
  privilegeEscalation,
  dataExport,
}

/// Security event model
class SecurityEvent {
  final SecurityEventType type;
  final String userId;
  final DateTime timestamp;
  final String? details;
  final Map<String, dynamic>? metadata;

  SecurityEvent({
    required this.type,
    required this.userId,
    required this.timestamp,
    this.details,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
    'metadata': metadata,
  };
}
