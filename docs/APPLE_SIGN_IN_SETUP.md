# Apple Sign-In Configuration Guide

This guide will walk you through setting up Apple Sign-In (Sign in with Apple) for the NandyFood iOS app.

## Prerequisites

- Apple Developer Account (required, $99/year)
- Xcode installed on macOS
- Physical iOS device (iOS 13 or later)
- Your app's Bundle Identifier

## Important Notes

- Apple Sign-In is **only available on iOS 13+**
- Apple Sign-In is **required** by Apple if your app offers other third-party sign-in options (like Google)
- Apple Sign-In **does not work on iOS Simulator** reliably - always test on a physical device
- Users may choose to hide their email address

## Step 1: Configure App ID in Apple Developer Portal

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Sign in with your Apple Developer account
3. Navigate to **Certificates, Identifiers & Profiles**
4. Click **Identifiers** in the sidebar
5. Find your app's **App ID** (or create a new one)
   - Click the **+** button to create a new App ID if needed
   - Select **App IDs** → **Continue**
   - Select **App** → **Continue**
   - Enter:
     - **Description**: NandyFood
     - **Bundle ID**: `com.nandyfood.app` (Explicit, must match your Xcode project)
6. Scroll down to **Capabilities**
7. Check **Sign in with Apple**
8. Click **Continue** → **Register**

## Step 2: Create a Services ID

1. Still in **Certificates, Identifiers & Profiles**
2. Click **Identifiers** → **+** button
3. Select **Services IDs** → **Continue**
4. Enter:
   - **Description**: NandyFood Sign In
   - **Identifier**: `com.nandyfood.app.signin` (must be unique and different from Bundle ID)
5. Check **Sign in with Apple**
6. Click **Continue** → **Register**

## Step 3: Configure Services ID

1. Click on the Services ID you just created
2. Click **Sign in with Apple** → **Configure**
3. In the configuration screen:
   - **Primary App ID**: Select your app's Bundle ID
   - **Website URLs**:
     - **Domains and Subdomains**: Your Supabase project URL (e.g., `yourproject.supabase.co`)
     - **Return URLs**: Your Supabase callback URL (e.g., `https://yourproject.supabase.co/auth/v1/callback`)
4. Click **Save** → **Continue** → **Save**

## Step 4: Create a Key for Apple Sign-In

1. In **Certificates, Identifiers & Profiles**
2. Click **Keys** → **+** button
3. Enter:
   - **Key Name**: NandyFood Sign In Key
4. Check **Sign in with Apple**
5. Click **Configure** next to Sign in with Apple
6. Select your **Primary App ID**
7. Click **Save** → **Continue** → **Register**
8. **Important**: Download the `.p8` key file
   - You can only download this **once**!
   - Save it securely (you'll need it for Supabase)
9. Note the **Key ID** (you'll need this for Supabase)

## Step 5: Get Your Team ID

1. In Apple Developer Portal, go to **Membership**
2. Find and copy your **Team ID** (10 characters)
   - Format: `ABCDE12345`
3. You'll need this for Supabase configuration

## Step 6: Configure Supabase

1. Go to your [Supabase Dashboard](https://app.supabase.com/)
2. Select your project
3. Go to **Authentication** → **Providers**
4. Find **Apple** and enable it
5. Enter the following:
   - **Services ID**: Your Services ID from Step 2 (e.g., `com.nandyfood.app.signin`)
   - **Key ID**: The Key ID from Step 4
   - **Team ID**: Your Team ID from Step 5
   - **Private Key**: Open the `.p8` file from Step 4 and paste its contents
6. Click **Save**

## Step 7: Configure Your iOS App in Xcode

1. Open your project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Select **Runner** in the project navigator

3. Go to **Signing & Capabilities** tab

4. Click **+ Capability**

5. Add **Sign in with Apple**

6. Verify the following:
   - Your **Team** is selected
   - Your **Bundle Identifier** matches what you configured (e.g., `com.nandyfood.app`)
   - **Sign in with Apple** capability shows no errors

## Step 8: Update Info.plist (if needed)

The `sign_in_with_apple` package should handle this automatically, but verify:

1. Open `ios/Runner/Info.plist`
2. Ensure it doesn't block Apple Sign-In (it should be fine by default)

## Step 9: Test the Integration

### Important: Test on a Physical Device

Apple Sign-In **does not work reliably on iOS Simulator**. Always test on a real device.

1. Connect your iOS device (iOS 13+)
2. Make sure you're signed in to iCloud on the device
3. Run the app:
   ```bash
   flutter run -d <your-device-id>
   ```
4. Tap "Continue with Apple"
5. You should see the Apple Sign-In sheet
6. Choose to share or hide your email
7. Complete Face ID/Touch ID authentication
8. You should be signed in!

### First-Time Sign-In

When a user signs in with Apple for the first time:
- They can choose their email visibility (share or hide)
- They can edit their name
- Apple provides these details **only on first sign-in**
- Subsequent sign-ins won't include name/email data

## Common Issues & Solutions

### Issue 1: "Sign in with Apple not available"

**Cause**: Device is iOS 12 or lower, or not signed in to iCloud

**Solution**:
1. Verify device is iOS 13+
2. Go to Settings → Sign in to your iPhone (at top)
3. Sign in with your Apple ID

### Issue 2: "Sign in with Apple capability is not enabled"

**Cause**: Capability not added in Xcode or Bundle ID not configured

**Solution**:
1. Open Xcode → Runner → Signing & Capabilities
2. Add "Sign in with Apple" capability
3. Verify your Bundle ID is correct
4. Clean and rebuild: `Product` → `Clean Build Folder`

### Issue 3: "Invalid client"

**Cause**: Services ID not configured correctly or mismatch

**Solution**:
1. Double-check Services ID in Supabase matches Apple Developer Portal
2. Verify Return URLs are correct in Services ID configuration
3. Wait 10-15 minutes for Apple to propagate changes

### Issue 4: "The operation couldn't be completed"

**Cause**: Network issue or Apple services down

**Solution**:
1. Check [Apple System Status](https://www.apple.com/support/systemstatus/)
2. Verify device has internet connection
3. Try again later

### Issue 5: Email is null/hidden

**Cause**: User chose to hide their email

**Solution**: This is expected behavior! Apple allows users to hide their email.
- Apple provides a relay email (format: `xxxxx@privaterelay.appleid.com`)
- Your code should handle this gracefully
- The AuthService already handles this with a fallback: `'Apple User'`

### Issue 6: Name not provided on subsequent sign-ins

**Cause**: Apple only provides name/email on **first sign-in**

**Solution**: 
- Cache user name on first sign-in in your database
- Subsequent sign-ins won't include this data
- This is Apple's intended behavior

## Security Notes

1. **Protect Your .p8 Key File**:
   - Never commit it to version control
   - Store it securely (password manager, secrets vault)
   - You can only download it once from Apple

2. **Environment Variables**:
   ```dart
   // Store sensitive data in .env file
   APPLE_SERVICES_ID=com.nandyfood.app.signin
   APPLE_TEAM_ID=ABCDE12345
   ```

3. **Production Checklist**:
   - [ ] Services ID configured with production Return URLs
   - [ ] Key file securely stored
   - [ ] Supabase production project configured
   - [ ] Release build tested on physical device
   - [ ] Privacy policy mentions Apple Sign-In

## Handle Privacy: Email Relay

When users choose to hide their email, Apple provides a private relay email:
- Format: `xxxxx@privaterelay.appleid.com`
- Emails sent to this address are forwarded to user's real email
- Users can disable the relay at any time in Settings

Your AuthService already handles this:
```dart
final fullName = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
await _ensureUserProfileExists(
  response.user!,
  fullName.isNotEmpty ? fullName : response.user!.email ?? 'Apple User',
);
```

## Testing Checklist

- [ ] Sign in works on physical iOS device (iOS 13+)
- [ ] Sign in fails gracefully on iOS 12 and below
- [ ] User can choose to hide email
- [ ] User profile created in Supabase
- [ ] Sign out works correctly
- [ ] Sign in again works (subsequent sign-in)
- [ ] Error messages are clear and helpful
- [ ] Loading states work properly

## Production Requirements

Before submitting to App Store:

1. **App Store Review**:
   - Apple requires Sign in with Apple if you offer other social sign-in options
   - Must be prominently displayed (not hidden)
   - Should be the first or most prominent sign-in option

2. **Privacy Policy**:
   - Must mention Sign in with Apple
   - Explain how user data is handled
   - Mention private email relay feature

3. **Testing**:
   - Test with multiple Apple IDs
   - Test first-time vs returning users
   - Test email hiding feature
   - Test on various iOS versions (13, 14, 15, 16, 17)

## Next Steps

Once Apple Sign-In is working:

1. Test both Google and Apple Sign-In flows
2. Verify user profiles are created correctly
3. Test sign out and switch accounts
4. Implement any additional profile data collection
5. Move on to onboarding flow (Day 18-19)

## Resources

- [Sign in with Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Flutter Package: sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple)
- [Supabase Apple Auth Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple/overview/)
- [Apple System Status](https://www.apple.com/support/systemstatus/)
