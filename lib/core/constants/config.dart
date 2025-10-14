import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';

  // PayFast Configuration
  static String get payfastMerchantId =>
      dotenv.env['PAYFAST_MERCHANT_ID'] ?? '10000100';
  static String get payfastMerchantKey =>
      dotenv.env['PAYFAST_MERCHANT_KEY'] ?? '46f0cd694581a';
  static String get payfastPassphrase =>
      dotenv.env['PAYFAST_PASSPHRASE'] ?? 'nhm17aop730sh';
  static String get payfastBaseUrl =>
      dotenv.env['PAYFAST_BASE_URL'] ?? 'https://sandbox.payfast.co.za';
  static String get payfastValidateUrl =>
      dotenv.env['PAYFAST_VALIDATE_URL'] ?? 'https://sandbox.payfast.co.za/api/validate';
  static String get payfastProcessUrl =>
      dotenv.env['PAYFAST_PROCESS_URL'] ?? 'https://sandbox.payfast.co.za/eng/process';
  static String get payfastEnvironment =>
      dotenv.env['PAYFAST_ENVIRONMENT'] ?? 'test';

  // PayFast Live Configuration
  static String get payfastMerchantIdLive =>
      dotenv.env['PAYFAST_MERCHANT_ID_LIVE'] ?? 'your-live-merchant-id';
  static String get payfastMerchantKeyLive =>
      dotenv.env['PAYFAST_MERCHANT_KEY_LIVE'] ?? 'your-live-merchant-key';
  static String get payfastPassphraseLive =>
      dotenv.env['PAYFAST_PASSPHRASE_LIVE'] ?? 'your-live-passphrase';
  static String get payfastBaseUrlLive =>
      dotenv.env['PAYFAST_BASE_URL_LIVE'] ?? 'https://www.payfast.co.za';
  static String get payfastValidateUrlLive =>
      dotenv.env['PAYFAST_VALIDATE_URL_LIVE'] ?? 'https://api.payfast.co.za/api/validate';
  static String get payfastProcessUrlLive =>
      dotenv.env['PAYFAST_PROCESS_URL_LIVE'] ?? 'https://www.payfast.co.za/eng/process';

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.fooddeliveryapp.com';

  // Environment Configuration
  static bool get isDebugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
}
