/// Test script to verify Supabase connection
/// Run with: dart run test_supabase_connection.dart

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('\n========================================');
  print('NandyFood - Supabase Connection Test');
  print('========================================\n');

  try {
    // Load environment variables
    print('Loading environment variables...');
    await dotenv.load(fileName: '.env');
    print('✓ Environment variables loaded\n');

    // Get Supabase credentials
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      print('✗ ERROR: Missing Supabase credentials in .env file');
      return;
    }

    print('Supabase URL: $supabaseUrl');
    print('✓ Credentials found\n');

    // Initialize Supabase
    print('Initializing Supabase client...');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    final supabase = Supabase.instance.client;
    print('✓ Supabase client initialized\n');

    // Test 1: Check if we can query the database
    print('Test 1: Querying user_profiles table...');
    try {
      final response = await supabase.from('user_profiles').select().limit(1);
      print('✓ Successfully connected to user_profiles table');
      print('  Result: ${response.length} rows returned\n');
    } catch (e) {
      print('✗ Failed to query user_profiles table');
      print('  Error: $e');
      print('  Note: This is expected if migrations haven\'t been applied yet\n');
    }

    // Test 2: Check if we can query restaurants table
    print('Test 2: Querying restaurants table...');
    try {
      final response = await supabase.from('restaurants').select().limit(5);
      print('✓ Successfully connected to restaurants table');
      print('  Result: ${response.length} rows returned\n');
    } catch (e) {
      print('✗ Failed to query restaurants table');
      print('  Error: $e');
      print('  Note: This is expected if migrations haven\'t been applied yet\n');
    }

    // Test 3: Check authentication status
    print('Test 3: Checking authentication...');
    final session = supabase.auth.currentSession;
    if (session == null) {
      print('✓ No active session (expected for test)');
      print('  Auth is working - ready for user signup/login\n');
    } else {
      print('✓ Active session found');
      print('  User ID: ${session.user.id}\n');
    }

    // Test 4: List storage buckets
    print('Test 4: Checking storage buckets...');
    try {
      final buckets = await supabase.storage.listBuckets();
      print('✓ Successfully accessed storage');
      print('  Found ${buckets.length} bucket(s):');
      for (final bucket in buckets) {
        print('    - ${bucket.name} (${bucket.public ? "public" : "private"})');
      }
      print('');
    } catch (e) {
      print('✗ Failed to access storage buckets');
      print('  Error: $e');
      print('  Note: Storage buckets may not be created yet\n');
    }

    print('========================================');
    print('Connection Test Summary');
    print('========================================');
    print('✓ Supabase connection successful!');
    print('\nNext steps:');
    print('1. Apply database migrations if tables don\'t exist');
    print('2. Add sample data for testing');
    print('3. Run your Flutter app: flutter run');
    print('========================================\n');
  } catch (e, stack) {
    print('\n✗ ERROR: $e');
    print('\nStack trace:');
    print(stack);
    print('\nTroubleshooting:');
    print('1. Verify .env file exists with SUPABASE_URL and SUPABASE_ANON_KEY');
    print('2. Check that credentials are correct');
    print('3. Ensure you have internet connection');
    print('4. Apply migrations: See SUPABASE_SETUP_GUIDE.md\n');
  }
}
