import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:food_delivery_app/core/utils/logger.dart';
import 'package:food_delivery_app/core/utils/payfast_security.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/core/constants/config.dart';

class SecurePaymentSession {
  final String sessionId;
  final String userId;
  final Order order;
  final double amount;
  final String currency;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? returnUrl;
  final String? cancelUrl;
  final String? notifyUrl;
  
  // Internal state
  bool _isVerified = false;
  String? _verificationToken;
  DateTime? _verifiedAt;

  SecurePaymentSession({
    String? sessionId,
    required this.userId,
    required this.order,
    required this.amount,
    this.currency = 'ZAR', // PayFast primarily uses South African Rand
    this.returnUrl,
    this.cancelUrl,
    this.notifyUrl,
    DateTime? createdAt,
    int expiryMinutes = 30, // Default 30 minutes expiry
  })  : sessionId = sessionId ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        expiresAt = (createdAt ?? DateTime.now()).add(Duration(minutes: expiryMinutes));

  /// Check if the session is still valid
  bool get isValid {
    return DateTime.now().isBefore(expiresAt) && _isVerified;
  }

  /// Check if the session has expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Generate a verification token for this session
  String _generateVerificationToken() {
    final dataToHash = '$sessionId$userId${order.id}$amount$createdAt';
    return sha256.convert(utf8.encode(dataToHash)).toString();
  }

  /// Initialize the session by generating a verification token
  void initialize() {
    _verificationToken = _generateVerificationToken();
    AppLogger.payment('Session initialized', sessionId);
  }

  /// Verify the session with the provided token
  bool verify(String token) {
    if (token != _verificationToken) {
      AppLogger.e('Payment session verification failed: Invalid token', null);
      return false;
    }

    if (isExpired) {
      AppLogger.e('Payment session verification failed: Session expired', null);
      return false;
    }

    _isVerified = true;
    _verifiedAt = DateTime.now();
    AppLogger.payment('Session verified', sessionId);
    return true;
  }

  /// Create a secure payment payload for sending to PayFast
  Map<String, dynamic> toSecurePaymentPayload() {
    if (!isValid) {
      throw Exception('Cannot create payload for invalid session');
    }

    // Sanitize the data to prevent injection
    final sanitizedOrderName = PayFastSecurity.sanitizePaymentData({
      'name': 'Order #${order.id}'
    })['name'] as String;

    return {
      'merchant_id': currency == 'ZAR' ? Config.payfastMerchantId : Config.payfastMerchantIdLive,
      'merchant_key': currency == 'ZAR' ? Config.payfastMerchantKey : Config.payfastMerchantKeyLive,
      'return_url': returnUrl ?? _getDefaultReturnUrl(),
      'cancel_url': cancelUrl ?? _getDefaultCancelUrl(),
      'notify_url': notifyUrl ?? _getDefaultNotifyUrl(),
      'name_first': PayFastSecurity.sanitizePaymentData({'name': order.userId})['name'],
      'email_address': _sanitizeEmail('user@example.com'), // For now, using a placeholder - would come from user profile
      'm_payment_id': sessionId,  // Our internal session ID
      'amount': amount.toStringAsFixed(2),
      'item_name': sanitizedOrderName,
      'item_description': 'Order #${order.id} from NandyFood',
      // Add the signature for validation
      'signature': _generatePayloadSignature(),
    };
  }

  /// Generate signature for the payload
  String _generatePayloadSignature() {
    final params = toSecurePaymentPayload();
    // Remove the signature field before calculating the signature
    final paramsForSignature = Map<String, dynamic>.from(params);
    paramsForSignature.remove('signature');

    return PayFastSecurity.buildSignatureString(paramsForSignature);
  }

  /// Get default return URL
  String _getDefaultReturnUrl() {
    return '${Config.apiBaseUrl}/payment/success?session=${sessionId}';
  }

  /// Get default cancel URL
  String _getDefaultCancelUrl() {
    return '${Config.apiBaseUrl}/payment/cancel?session=${sessionId}';
  }

  /// Get default notify URL
  String _getDefaultNotifyUrl() {
    return '${Config.apiBaseUrl}/payment/notify?session=${sessionId}';
  }

  /// Sanitize email address
  String _sanitizeEmail(String email) {
    return PayFastSecurity.sanitizePaymentData({'email': email})['email'] as String;
  }

  /// Validate the session before processing payment
  bool validateSession() {
    if (isExpired) {
      AppLogger.e('Payment session validation failed: Session expired', null);
      return false;
    }

    if (!_isVerified) {
      AppLogger.e('Payment session validation failed: Session not verified', null);
      return false;
    }

    if (!PayFastSecurity.validatePaymentParameters(
      amount: amount,
      itemName: 'Order #${order.id}',
      returnUrl: returnUrl,
      cancelUrl: cancelUrl,
      notifyUrl: notifyUrl,
      email: 'user@example.com', // Would come from user profile
    )) {
      AppLogger.e('Payment session validation failed: Invalid payment parameters', null);
      return false;
    }

    AppLogger.payment('Session validated', sessionId);
    return true;
  }

  /// Get session info for logging/debugging (without sensitive data)
  Map<String, dynamic> getSessionInfo() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'isValid': isValid,
      'isExpired': isExpired,
    };
  }
}

/// Manager class to handle multiple payment sessions
class PaymentSessionManager {
  static final Map<String, SecurePaymentSession> _activeSessions = {};

  /// Create a new payment session
  static SecurePaymentSession createSession({
    required String userId,
    required Order order,
    required double amount,
    String currency = 'ZAR',
    String? returnUrl,
    String? cancelUrl,
    String? notifyUrl,
  }) {
    final session = SecurePaymentSession(
      userId: userId,
      order: order,
      amount: amount,
      currency: currency,
      returnUrl: returnUrl,
      cancelUrl: cancelUrl,
      notifyUrl: notifyUrl,
    );
    
    session.initialize();
    _activeSessions[session.sessionId] = session;
    
    AppLogger.payment('New payment session created', session.sessionId);
    return session;
  }

  /// Get a payment session by ID
  static SecurePaymentSession? getSession(String sessionId) {
    final session = _activeSessions[sessionId];
    
    // Clean up expired sessions
    if (session != null && session.isExpired) {
      _activeSessions.remove(sessionId);
      AppLogger.payment('Expired session removed', sessionId);
      return null;
    }
    
    return session;
  }

  /// Verify and return a payment session
  static SecurePaymentSession? verifySession(String sessionId, String token) {
    final session = getSession(sessionId);
    if (session == null) {
      return null;
    }

    if (session.verify(token)) {
      return session;
    }

    return null;
  }

  /// Remove a payment session
  static void removeSession(String sessionId) {
    _activeSessions.remove(sessionId);
    AppLogger.payment('Session removed', sessionId);
  }

  /// Clean up expired sessions
  static void cleanupExpiredSessions() {
    final now = DateTime.now();
    final expiredSessionIds = _activeSessions.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final sessionId in expiredSessionIds) {
      _activeSessions.remove(sessionId);
      AppLogger.payment('Expired session cleaned up', sessionId);
    }
  }

  /// Get the number of active sessions
  static int get activeSessionCount => _activeSessions.length;

  /// Get all active session IDs
  static List<String> get activeSessionIds => _activeSessions.keys.toList();
}