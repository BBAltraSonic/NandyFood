# Firebase Setup Guide for NandyFood
## Phase 2 Week 5 Day 21-22: Firebase Cloud Messaging Configuration

This guide walks through the complete setup of Firebase for the NandyFood app, including Firebase Cloud Messaging (FCM) for push notifications.

---

## Prerequisites

1. **Flutter SDK** installed and configured
2. **Firebase CLI** installed (`npm install -g firebase-tools`)
3. **FlutterFire CLI** installed (`dart pub global activate flutterfire_cli`)
4. A **Firebase project** created at [Firebase Console](https://console.firebase.google.com/)

---

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `nandyfood` (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click "Create Project"

---

## Step 2: Configure FlutterFire

Run the FlutterFire configuration command in your project root:

```bash
# Login to Firebase (if not already)
firebase login

# Configure FlutterFire
flutterfire configure --project=nandyfood
```

This will:
- Create/update `firebase_options.dart` with your project configuration
- Register your apps (iOS and Android) in Firebase
- Download configuration files

**What gets created:**
- `lib/firebase_options.dart` - Platform-specific Firebase configuration
- `android/app/google-services.json` - Android configuration
- `ios/Runner/GoogleService-Info.plist` - iOS configuration

---

## Step 3: Android Configuration

### 3.1 Update `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

### 3.2 Update `android/app/build.gradle`

Add at the bottom of the file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3.3 Update `android/app/src/main/AndroidManifest.xml`

Add FCM permissions and metadata:

```xml
<manifest>
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- ... existing code ... -->
        
        <!-- Add FCM default notification channel -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="food_delivery_channel" />
            
        <!-- Add FCM icon -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
            
        <!-- Add FCM color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/notification_color" />
    </application>
</manifest>
```

### 3.4 Create notification channel color

Create `android/app/src/main/res/values/colors.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#FF6B35</color>
</resources>
```

---

## Step 4: iOS Configuration

### 4.1 Add Push Notification Capability

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **Push Notifications**
6. Add **Background Modes** and check:
   - Remote notifications
   - Background fetch

### 4.2 Update `ios/Runner/Info.plist`

Add notification permissions:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>fetch</string>
</array>
```

### 4.3 Configure APNs

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, IDs & Profiles**
3. Create an **Apple Push Notification service SSL Certificate**
4. Download and upload to Firebase Console:
   - Firebase Console → Project Settings → Cloud Messaging → iOS app
   - Upload APNs Authentication Key or Certificate

---

## Step 5: Enable Firebase Services

### 5.1 Enable Cloud Messaging

1. Go to Firebase Console → **Cloud Messaging**
2. Note your **Server Key** (needed for Supabase Edge Functions)
3. Save the Server Key in your `.env` file:
   ```env
   FCM_SERVER_KEY=your_server_key_here
   ```

### 5.2 Enable Firebase Analytics (Optional)

Already configured if you chose to enable it during project creation.

### 5.3 Enable Firebase Crashlytics (Recommended)

```bash
flutterfire configure --project=nandyfood --enable-crashlytics
```

---

## Step 6: Supabase Integration

### 6.1 Run the Migration

Execute the migration to create the `user_devices` table:

```bash
# Using Supabase CLI
supabase db push database/migrations/002_create_user_devices_table.sql

# OR using Supabase Dashboard
# Go to SQL Editor and paste the contents of the migration file
```

### 6.2 Configure FCM Server Key in Supabase

The FCM Server Key will be needed for sending notifications from Supabase Edge Functions.

Store it as a secret:
```bash
supabase secrets set FCM_SERVER_KEY=your_server_key_here
```

---

## Step 7: Test the Setup

### 7.1 Run the App

```bash
flutter run
```

Check the logs for:
```
✅ Firebase initialized successfully
✅ FCM background handler registered
✅ Notification service initialized
✅ FCM token: <your_token>
```

### 7.2 Send Test Notification

1. Go to Firebase Console → **Cloud Messaging**
2. Click **Send your first message**
3. Enter a notification title and body
4. Click **Send test message**
5. Enter your FCM token (from app logs)
6. Click **Test**

You should receive a notification on your device!

---

## Step 8: Verify Database Integration

Check that the FCM token was stored:

```sql
-- Run in Supabase SQL Editor
SELECT * FROM user_devices;
```

You should see an entry with your FCM token, platform, and device info.

---

## Troubleshooting

### Android Issues

**Issue:** `google-services.json` not found
- Solution: Re-run `flutterfire configure`

**Issue:** Duplicate class error
- Solution: Update `com.google.gms:google-services` version

**Issue:** Notifications not received
- Solution: Check if notification permission is granted in Android settings

### iOS Issues

**Issue:** APNs token not available
- Solution: Run on a physical device (simulator doesn't support push notifications)

**Issue:** Capabilities not showing in Xcode
- Solution: Ensure you're opening `.xcworkspace` not `.xcodeproj`

**Issue:** Certificate errors
- Solution: Re-create and re-upload APNs certificate in Firebase Console

### General Issues

**Issue:** FCM token is null
- Solution: Check Firebase initialization and network connection

**Issue:** Token not stored in database
- Solution: Ensure user is logged in and migration is applied

**Issue:** Background notifications not working
- Solution: Check that `firebaseMessagingBackgroundHandler` is properly registered

---

## Next Steps

After completing this setup, you're ready for:

1. **Day 23-24:** Implement real-time order tracking
2. **Day 25-26:** Add driver location tracking
3. **Day 27:** Implement order actions and edge cases

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)

---

## Security Notes

🔒 **Important:**
- Never commit `google-services.json` or `GoogleService-Info.plist` with production keys
- Store FCM Server Key securely in environment variables
- Use RLS policies to protect user device data
- Regularly rotate APNs certificates

---

**Setup Complete! 🎉**

Your NandyFood app now has Firebase Cloud Messaging configured and ready to send push notifications!
