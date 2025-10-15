# Firebase Configuration Guide for NandyFood

**Last Updated:** January 2025  
**Status:** Ready for Configuration  
**Prerequisites:** Flutter project with Firebase packages installed

---

## Overview

NandyFood uses Firebase for the following services:
- **Firebase Core** - Foundation for all Firebase services
- **Firebase Messaging (FCM)** - Push notifications
- **Firebase Analytics** - User behavior tracking
- **Firebase Performance** - Performance monitoring
- **Firebase Crashlytics** - Crash reporting

---

## Prerequisites

### 1. Firebase Console Access
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a Firebase account if you don't have one
- You'll need admin access to create a new project

### 2. Required Tools
```bash
# Install FlutterFire CLI (if not already installed)
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

### 3. Flutter & Dart Versions
- Flutter: >= 3.8.0 ✅ (already configured in pubspec.yaml)
- Dart: >= 3.8.0 ✅ (already configured in pubspec.yaml)

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project details:
   - **Project name:** `NandyFood` (or your preferred name)
   - **Enable Google Analytics:** Yes (recommended)
   - **Analytics location:** South Africa
4. Click **"Create project"**
5. Wait for project setup to complete

---

## Step 2: Configure Firebase with FlutterFire CLI

### Run FlutterFire Configure

```bash
cd "C:\Users\BB\Documents\NandyFood"

# Configure Firebase for all platforms
flutterfire configure
```

### Interactive Prompts

You'll be asked to:

1. **Select a Firebase project:**
   - Choose "NandyFood" (or the project you created)
   - Or create a new project from the CLI

2. **Select platforms to configure:**
   - ✅ Android (press Space to select)
   - ✅ iOS (press Space to select)
   - ✅ Web (optional, press Space to select)
   - ✅ macOS (optional)
   - Press Enter to confirm

3. **Android package name:**
   - Default: `com.example.food_delivery_app`
   - Recommended: Change to `com.nandyfood.app` or your custom package

4. **iOS bundle ID:**
   - Default: `com.example.foodDeliveryApp`
   - Recommended: Change to `com.nandyfood.app` or match Android package

### What FlutterFire Does

The command will:
- ✅ Create/update `lib/firebase_options.dart` with platform-specific configuration
- ✅ Register your app with Firebase Console
- ✅ Download configuration files (google-services.json, GoogleService-Info.plist)
- ✅ Add necessary Firebase configuration to your project

---

## Step 3: Android Configuration

### 3.1 Verify google-services.json

FlutterFire should have placed this file automatically:

```
android/app/google-services.json
```

If not present, manually download from Firebase Console:
1. Go to Project Settings → General
2. Under "Your apps" → Android app
3. Click "Download google-services.json"
4. Place it in `android/app/`

### 3.2 Verify build.gradle Configuration

FlutterFire should have updated these files. Verify:

**File:** `android/build.gradle`
```gradle
buildscript {
    dependencies {
        // Should be present
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**File:** `android/app/build.gradle`
```gradle
// At the bottom of the file
apply plugin: 'com.google.gms.google-services'

android {
    defaultConfig {
        // Verify package name matches Firebase
        applicationId "com.nandyfood.app"
        minSdkVersion 23  // Required for Firebase
        targetSdkVersion flutter.targetSdkVersion
    }
}
```

---

## Step 4: iOS Configuration

### 4.1 Verify GoogleService-Info.plist

FlutterFire should have placed this file automatically:

```
ios/Runner/GoogleService-Info.plist
```

If not present, manually download from Firebase Console:
1. Go to Project Settings → General
2. Under "Your apps" → iOS app
3. Click "Download GoogleService-Info.plist"
4. Add it to Xcode: Runner → Runner folder

### 4.2 Configure APNs (Apple Push Notification Service)

Required for push notifications on iOS:

1. **Generate APNs Key** (one-time setup):
   - Go to [Apple Developer](https://developer.apple.com/account/)
   - Certificates, Identifiers & Profiles
   - Keys → Create a key
   - Enable "Apple Push Notifications service (APNs)"
   - Download the .p8 key file

2. **Upload APNs Key to Firebase:**
   - Firebase Console → Project Settings
   - Cloud Messaging tab
   - Under "Apple app configuration" → Upload APNs authentication key
   - Enter Key ID and Team ID

3. **Update Xcode Project:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner → Signing & Capabilities
   - Click "+ Capability"
   - Add "Push Notifications"
   - Add "Background Modes" → Enable "Remote notifications"

4. **Update Info.plist:**
   ```xml
   <key>FirebaseAppDelegateProxyEnabled</key>
   <false/>
   ```

---

## Step 5: Verify Configuration

### 5.1 Check firebase_options.dart

After running `flutterfire configure`, verify the file was created:

**File:** `lib/firebase_options.dart`

Should contain something like:

```dart
// File generated by FlutterFire CLI.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      // ... etc
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  // ... iOS, web, etc.
}
```

### 5.2 Test Firebase Connection

Run the app and check initialization:

```bash
cd "C:\Users\BB\Documents\NandyFood"
flutter run
```

Look for log output:
```
✅ SUCCESS: Firebase initialized successfully
✅ SUCCESS: FCM token: ABCD1234...
✅ SUCCESS: Notification service initialized
```

---

## Step 6: Enable Firebase Services

### 6.1 Enable Firebase Cloud Messaging (FCM)

1. Firebase Console → Build → Cloud Messaging
2. Click "Get started" if not already enabled
3. No additional configuration needed (already handled by setup)

### 6.2 Enable Firebase Analytics

1. Firebase Console → Build → Analytics
2. Should be enabled by default
3. Verify events are being logged (may take 24 hours for first data)

### 6.3 Enable Firebase Crashlytics

1. Firebase Console → Build → Crashlytics
2. Click "Enable Crashlytics"
3. Follow setup wizard (mostly automatic)

### 6.4 Enable Firebase Performance Monitoring

1. Firebase Console → Build → Performance Monitoring
2. Click "Get started"
3. Enable monitoring

---

## Step 7: Environment Variables

Update `.env` file with Firebase-related settings:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=nandyfood
FIREBASE_ENABLED=true

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_PERFORMANCE_MONITORING=true
ENABLE_FCM=true
```

---

## Step 8: Test Push Notifications

### 8.1 Get FCM Token

Run the app and look for the FCM token in logs:

```
✅ SUCCESS: FCM token: eXaMpLe-FcM-ToKeN-123456789...
```

Copy this token for testing.

### 8.2 Send Test Notification

1. Firebase Console → Engage → Cloud Messaging
2. Click "Send your first message"
3. Enter notification details:
   - **Notification title:** "Test Notification"
   - **Notification text:** "Hello from Firebase!"
4. Click "Send test message"
5. Paste your FCM token
6. Click "Test"

### 8.3 Verify Receipt

- **App in Foreground:** Should see notification banner in app
- **App in Background:** Should see system notification
- **App Terminated:** Should see system notification

---

## Step 9: Database Migration

The Firebase setup is separate from Supabase, but you need to apply the FCM token storage migration:

```sql
-- Already created: supabase/migrations/002_create_user_devices_table.sql
-- Apply via Supabase Dashboard or CLI
```

1. Go to Supabase Dashboard
2. SQL Editor
3. Paste migration content from `supabase/migrations/002_create_user_devices_table.sql`
4. Run migration

---

## Troubleshooting

### Issue: "FlutterFire command not found"

**Solution:**
```bash
# Add Dart pub global bin to PATH
# Windows:
$env:PATH += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"

# Or install again
dart pub global activate flutterfire_cli
```

### Issue: "No Firebase project found"

**Solution:**
1. Ensure you created a Firebase project first
2. Ensure you're logged into Firebase CLI
3. Run: `firebase login` (if using Firebase CLI)

### Issue: Android build fails with "google-services.json not found"

**Solution:**
1. Verify file exists at `android/app/google-services.json`
2. Verify package name in google-services.json matches build.gradle
3. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

### Issue: iOS push notifications not working

**Solution:**
1. Verify APNs key is uploaded to Firebase
2. Verify Push Notifications capability is enabled in Xcode
3. Verify device has a valid APNs token
4. Check iOS logs for errors: `flutter run --verbose`

### Issue: "FirebaseOptions not found"

**Solution:**
1. Run `flutterfire configure` again
2. Verify `lib/firebase_options.dart` was created
3. If still missing, check file permissions and try manual creation

---

## Post-Configuration Checklist

- [ ] Firebase project created
- [ ] `flutterfire configure` executed successfully
- [ ] `firebase_options.dart` generated
- [ ] Android google-services.json present
- [ ] iOS GoogleService-Info.plist present
- [ ] APNs key uploaded (iOS)
- [ ] App runs without Firebase errors
- [ ] FCM token generated
- [ ] Test notification received
- [ ] Supabase migration applied
- [ ] Analytics events visible in console (after 24h)
- [ ] Crashlytics enabled

---

## Next Steps

After successful configuration:

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Verify all services:**
   - Check logs for successful initialization
   - Test push notifications
   - Verify analytics events (DebugView in Firebase Console)
   - Test crash reporting (use test crash button in settings)

3. **Production Setup:**
   - Update package names to production values
   - Generate production signing keys
   - Configure production APNs certificates
   - Update Firebase project settings for production

---

## Configuration Files Summary

| File | Location | Purpose | Created By |
|------|----------|---------|------------|
| `firebase_options.dart` | `lib/` | Platform configuration | FlutterFire CLI |
| `google-services.json` | `android/app/` | Android config | FlutterFire CLI or manual |
| `GoogleService-Info.plist` | `ios/Runner/` | iOS config | FlutterFire CLI or manual |
| `.env` | Root | Environment variables | Manual |

---

## Support & Resources

### Official Documentation
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

### Project Documentation
- `docs/FIREBASE_SETUP_GUIDE.md` - Original setup guide
- `docs/DAY20_AUTH_ENHANCEMENTS.md` - Authentication setup
- `PHASE2_PROGRESS.md` - Phase 2 implementation progress

### Getting Help
- Firebase Support: https://firebase.google.com/support
- FlutterFire Issues: https://github.com/firebase/flutterfire/issues
- NandyFood Documentation: See docs/ folder

---

**Status:** ✅ Ready to Configure  
**Estimated Time:** 30-45 minutes  
**Difficulty:** Intermediate  
**Prerequisites:** Firebase account, FlutterFire CLI installed
