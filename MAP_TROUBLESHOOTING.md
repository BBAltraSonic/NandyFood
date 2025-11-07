# Google Maps Troubleshooting Guide

## If Map Still Doesn't Display

### 1. Verify Google Maps API Key in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to **APIs & Services → Credentials**
4. Find your API key: `AIzaSyBYiFP4Y-Hi9d-JboqXCcDDP5Kc94iL1ZY`
5. Verify the following APIs are enabled:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Geocoding API** (for address lookups)
   - **Places API** (optional, for restaurant search)

### 2. Check API Key Restrictions

In Google Cloud Console, click on your API key and verify:

**Application restrictions:**
- **Android apps:** Add package name `com.example.food_delivery_app` and SHA-1 fingerprint
- **iOS apps:** Add bundle identifier `com.example.foodDeliveryApp`

**API restrictions:**
- Should allow: Maps SDK for Android, Maps SDK for iOS, Geocoding API

### 3. Get SHA-1 Fingerprint for Android

```bash
# Debug keystore (for development)
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore (for production)
keytool -list -v -keystore android\app\upload-keystore.jks
```

Copy the SHA-1 fingerprint and add it to your API key restrictions in Google Cloud Console.

### 4. Check Runtime Permissions

The app requests location permissions, but if denied, the map might not display user location. To test:

1. Open the app
2. When prompted for location permission, tap **Allow**
3. If you missed it, go to **Settings → Apps → Food Delivery App → Permissions** and enable Location

### 5. Check Logcat for Errors

Run the app and check logcat:

```bash
flutter run -d emulator-5554 --verbose
```

Look for errors like:
- `API_KEY_INVALID`
- `API_KEY_EXPIRED`
- `BILLING_NOT_ENABLED`
- `MAPS_SDK_NOT_ENABLED`

### 6. Test with a Simple Map Screen

Use the test map screen:

```bash
flutter run -d emulator-5554 lib/test_map_screen.dart
```

### 7. Verify Internet Connection

Maps require internet connectivity. Check:
- Emulator has internet access
- Real device is connected to Wi-Fi or mobile data
- No firewall blocking Google Maps API requests

### 8. Check for Console Errors

Run:
```bash
flutter logs
```

Look for map-related errors in the output.

### 9. Update Google Play Services (Android Emulator)

If using an emulator, ensure it has Google Play Services:
1. Create emulator with **Google Play** (not Google APIs)
2. In AVD Manager, ensure Play Store icon is visible

### 10. Verify Info.plist (iOS Only)

Check `ios/Runner/Info.plist` has location permission descriptions:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby restaurants</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location for delivery tracking</string>
```

### 11. Rebuild the App Completely

```bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### 12. Check API Billing

Google Maps Platform requires a billing account:
1. Go to [Google Cloud Console → Billing](https://console.cloud.google.com/billing)
2. Ensure billing is enabled for your project
3. You get $200 free credit monthly

## Common Error Messages

### "Authorization failure"
- API key not configured correctly
- API key restrictions too strict
- Wrong API key for the platform

### "Map is blank/gray"
- No internet connection
- API key billing not enabled
- Maps SDK not enabled in Cloud Console

### "Unauthorized use of Google Maps Platform resources"
- API key restrictions blocking the app
- Need to add SHA-1 fingerprint (Android)
- Need to add bundle ID (iOS)

### "The Google Maps Platform server rejected your API key"
- API key is invalid or expired
- Check if API key is correctly set in .env and build files

## Quick Verification Checklist

- [ ] Google Maps API key is valid
- [ ] Maps SDK for Android is enabled
- [ ] Maps SDK for iOS is enabled
- [ ] API key has no restrictions OR app is added to restrictions
- [ ] Billing is enabled in Google Cloud Console
- [ ] SHA-1 fingerprint is added (Android)
- [ ] Bundle ID is added (iOS)
- [ ] Location permissions are granted in the app
- [ ] Internet connection is available
- [ ] App was completely rebuilt with `flutter clean`

## Contact Information

If issues persist:
1. Check Flutter logs: `flutter logs`
2. Check Android logcat: `adb logcat | grep -i "maps"`
3. Check Google Cloud Console quota usage
4. Verify API key at: https://console.cloud.google.com/apis/credentials
