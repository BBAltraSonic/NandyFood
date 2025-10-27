import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';

  // PayFast Configuration
  static String get payfastMerchantId =>
      dotenv.env['PAYFAST_MERCHANT_ID'] ?? '10000100'; // Sandbox default
  static String get payfastMerchantKey =>
      dotenv.env['PAYFAST_MERCHANT_KEY'] ?? '46f0cd694581a'; // Sandbox default
  static String get payfastPassphrase =>
      dotenv.env['PAYFAST_PASSPHRASE'] ?? 'test_passphrase';
  static String get payfastMode =>
      dotenv.env['PAYFAST_MODE'] ?? 'sandbox'; // sandbox or live
  static String get payfastReturnUrl =>
      dotenv.env['PAYFAST_RETURN_URL'] ??
      'https://nandyfood.com/payment/success';
  static String get payfastCancelUrl =>
      dotenv.env['PAYFAST_CANCEL_URL'] ??
      'https://nandyfood.com/payment/cancel';
  static String get payfastNotifyUrl =>
      dotenv.env['PAYFAST_NOTIFY_URL'] ??
      'https://nandyfood.com/api/payment/webhook';

  // PayFast API URLs
  static String get payfastApiUrl => payfastMode == 'live'
      ? 'https://www.payfast.co.za/eng/process'
      : 'https://sandbox.payfast.co.za/eng/process';

  static String get payfastValidateUrl => payfastMode == 'live'
      ? 'https://www.payfast.co.za/eng/query/validate'
      : 'https://sandbox.payfast.co.za/eng/query/validate';

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.fooddeliveryapp.com';

  // Environment Configuration
  static bool get isDebugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get isProduction => payfastMode == 'live';
  static bool get isSandbox => payfastMode == 'sandbox';

  // Backend payment verification endpoint
  static String get paymentVerifyUrl =>
      dotenv.env['PAYMENT_VERIFY_URL'] ?? '$apiBaseUrl/payment/payfast/verify';

}
