import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key';

  // Paystack Configuration
  static String get paystackPublicKey =>
      dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? 'pk_test_your_paystack_key';
  static String get paystackSecretKey =>
      dotenv.env['PAYSTACK_SECRET_KEY'] ?? 'sk_test_your_paystack_secret';

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.fooddeliveryapp.com';

  // Environment Configuration
  static bool get isDebugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
}
