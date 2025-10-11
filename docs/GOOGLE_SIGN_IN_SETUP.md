# Google Sign-In Configuration Guide

This guide will walk you through setting up Google Sign-In for the NandyFood app.

## Prerequisites

- Google Cloud Console account
- Android Studio (for Android setup)
- Xcode (for iOS setup)

## Step 1: Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Enter project name: `NandyFood` (or your preferred name)
4. Click "Create"

## Step 2: Enable Google Sign-In API

1. In your Google Cloud project, go to **APIs & Services** → **Library**
2. Search for "Google Sign-In API"
3. Click on it and click **Enable**

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Select **External** (unless you have a Google Workspace)
3. Click **Create**
4. Fill in the required fields:
   - **App name**: NandyFood
   - **User support email**: Your email
   - **Developer contact email**: Your email
5. Click **Save and Continue**
6. Skip **Scopes** for now (click **Save and Continue**)
7. Skip **Test users** (click **Save and Continue**)
8. Review and click **Back to Dashboard**

## Step 4: Create OAuth 2.0 Credentials

### For Android

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **Android** as application type
4. Enter the following:
   - **Name**: NandyFood Android
   - **Package name**: `com.nandyfood.app` (or your package name from `android/app/build.gradle`)
   - **SHA-1 certificate fingerprint**: See below for how to get this

#### Getting SHA-1 Fingerprint

**For Debug Build:**
```bash
# On Windows
cd android
./gradlew signingReport

# On macOS/Linux
cd android
./gradlew signingReport
```

Look for the **SHA-1** under `Variant: debug` and copy it.

**For Release Build (Production):**
You'll need the SHA-1 from your release keystore. If you don't have one yet, create it:
```bash
keytool -genkey -v -keystore ~/release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

Then get the SHA-1:
```bash
keytool -list -v -keystore ~/release-keystore.jks -alias release
```

5. Click **Create**
6. **Important**: Copy the **Client ID** that appears (format: `xxxxx.apps.googleusercontent.com`)

### For iOS

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **iOS** as application type
4. Enter the following:
   - **Name**: NandyFood iOS
   - **Bundle ID**: `com.nandyfood.app` (or your bundle ID from `ios/Runner.xcodeproj`)
5. Click **Create**
6. **Important**: Copy the **Client ID** and **iOS URL scheme**

### For Web (Optional but Recommended)

1. Create another OAuth client ID
2. Select **Web application**
3. Enter name: `NandyFood Web`
4. Click **Create**

## Step 5: Configure Supabase

1. Go to your [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Go to **Authentication** → **Providers**
4. Find **Google** and enable it
5. Paste your **Web Client ID** (from Step 4) into the **Client ID** field
6. Generate and paste the **Client Secret** from Google Cloud Console:
   - In Google Cloud Console, go to your Web OAuth client
   - Click on it to view details
   - Copy the **Client Secret**
7. Click **Save**

## Step 6: Update Your Flutter App

### Android Configuration

1. Open `android/app/build.gradle`
2. Verify your `applicationId` matches the package name you used in Step 4

### iOS Configuration

1. Open your project in Xcode: `open ios/Runner.xcworkspace`
2. Select **Runner** in the project navigator
3. Go to **Signing & Capabilities**
4. Verify your **Bundle Identifier** matches what you used in Step 4
5. Open `ios/Runner/Info.plist`
6. Add the URL scheme (replace `YOUR_IOS_URL_SCHEME` with the one from Step 4):

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Example: com.googleusercontent.apps.123456789-abcdefg -->
            <string>YOUR_IOS_URL_SCHEME</string>
        </array>
    </dict>
</array>
```

### Update AuthService

Open `lib/core/services/auth_service.dart` and replace the placeholder:

```dart
_googleSignIn ??= GoogleSignIn(
  serverClientId: Platform.isAndroid
      ? 'YOUR_ANDROID_CLIENT_ID.apps.googleusercontent.com'  // <-- Replace this
      : null,
);
```

With your actual Android Client ID from Step 4.

## Step 7: Test the Integration

### Testing on Android

1. Make sure you're using the correct SHA-1 fingerprint
2. Run the app:
   ```bash
   flutter run
   ```
3. Tap "Continue with Google"
4. You should see the Google Sign-In sheet
5. Select an account and sign in

### Testing on iOS

1. Make sure your Bundle ID and URL scheme are correct
2. Run the app on a physical device (Google Sign-In doesn't work well on simulator)
3. Tap "Continue with Google"
4. You should see the Google Sign-In sheet
5. Select an account and sign in

## Common Issues & Solutions

### Issue 1: "10: Developer Error" on Android

**Cause**: SHA-1 fingerprint mismatch or not configured

**Solution**:
1. Double-check your SHA-1 fingerprint
2. Make sure you added **both** debug and release SHA-1 fingerprints
3. It can take 5-10 minutes for Google to propagate changes

### Issue 2: "Sign in failed" on iOS

**Cause**: URL scheme not configured or Bundle ID mismatch

**Solution**:
1. Verify your `Info.plist` has the correct URL scheme
2. Verify your Bundle ID matches what you configured in Google Cloud Console
3. Clean and rebuild: `flutter clean && flutter pub get && flutter run`

### Issue 3: "Access blocked: This app's request is invalid"

**Cause**: OAuth consent screen not configured properly

**Solution**:
1. Go back to Google Cloud Console → OAuth consent screen
2. Make sure all required fields are filled
3. Add your test email to "Test users" if app is in testing mode

### Issue 4: User info not being saved

**Cause**: Supabase provider not configured or user profile creation failing

**Solution**:
1. Check Supabase logs for errors
2. Verify the `user_profiles` table exists
3. Check that RLS policies allow inserts

## Security Notes

1. **Never commit** your OAuth credentials to version control
2. Use environment variables for sensitive data:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   final clientId = dotenv.env['GOOGLE_CLIENT_ID'];
   ```
3. For production, always use release SHA-1 fingerprints
4. Keep your OAuth Client Secret secure (server-side only)

## Next Steps

Once Google Sign-In is working:

1. Test the full flow (sign in, sign out, sign in again)
2. Verify user profiles are being created in Supabase
3. Test error handling (cancel sign-in, network errors, etc.)
4. Move on to Apple Sign-In configuration (see `APPLE_SIGN_IN_SETUP.md`)

## Resources

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
