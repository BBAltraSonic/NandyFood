class Config {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', 
      defaultValue: 'https://your-project.supabase.co');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', 
      defaultValue: 'your-anon-key');
  
  // Stripe Configuration
  static const String stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY', 
      defaultValue: 'pk_test_your_stripe_key');
  
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', 
      defaultValue: 'https://api.fooddeliveryapp.com');
  
  // Environment Configuration
  static const bool isDebugMode = bool.fromEnvironment('DEBUG_MODE', defaultValue: true);
}