# Deep Linking & Share Feature Setup

This document explains the share feature implementation and deep linking configuration for the Literature app.

## Overview

Users can share posts to other apps (WhatsApp, Instagram, Twitter, etc.). When someone clicks a shared link:
- **If app is installed**: Opens directly in the Literature app
- **If app is NOT installed**: Redirects to App Store (iOS) or Play Store (Android)

## Share Link Format

When a user shares a post, the link looks like:
```
"Title of Post" by @username

Read on Literature
https://thekaiverse.com/post/{postId}
```

## Deep Link Configuration

### Custom Scheme (App-to-App)
- **Scheme**: `literature://`
- **Example**: `literature://post/abc123`

### Universal Links (Web URLs)
- **Domain**: `https://thekaiverse.com`
- **Example**: `https://thekaiverse.com/post/abc123`

## Platform Configuration

### ✅ Android Configuration (DONE)
File: `android/app/src/main/AndroidManifest.xml`

Already configured with:
- Custom scheme handler (`literature://`)
- Universal link handler (`https://thekaiverse.com/post/*`)
- Auto-verify enabled for seamless linking

### ✅ iOS Configuration (DONE)
File: `ios/Runner/Info.plist`

Already configured with:
- Custom URL scheme (`literature://`)
- Flutter deep linking enabled

### Additional iOS Setup Required

#### 1. Associated Domains
Add to your app's Xcode project:
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select the Runner target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability" and add "Associated Domains"
5. Add this domain:
   ```
   applinks:thekaiverse.com
   ```

#### 2. Apple App Site Association (AASA) File
Host this file at: `https://thekaiverse.com/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TEAM_ID.com.thekaiverse.literature",
        "paths": ["/post/*"]
      }
    ]
  }
}
```

**Important**:
- Replace `TEAM_ID` with your Apple Developer Team ID
- File must be served with `Content-Type: application/json`
- File must be accessible without redirects
- No `.json` extension needed

## Web Configuration Required

### Android App Links (Digital Asset Links)
Host this file at: `https://thekaiverse.com/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.thekaiverse.literature",
    "sha256_cert_fingerprints": [
      "YOUR_APP_SHA256_FINGERPRINT"
    ]
  }
}]
```

**Get your SHA256 fingerprint**:
```bash
# For debug build
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# For release build
keytool -list -v -keystore /path/to/your-release-key.keystore -alias your-key-alias
```

### Web Redirect Page
Create a redirect page at: `https://thekaiverse.com/post/{postId}`

The page should:
1. Attempt to open the app using custom scheme
2. If app doesn't open after 2 seconds, redirect to store
3. Detect platform (iOS vs Android) and redirect accordingly

A sample HTML redirect is available in `lib/core/services/deep_link_service.dart` → `generateRedirectHtml()` method.

## Configuration Updates Needed

### 1. Update Deep Link Service
File: `lib/core/services/deep_link_service.dart`

Replace these placeholders:
```dart
static const String appStoreId = 'YOUR_APP_STORE_ID'; // Get from App Store Connect
static const String playStoreId = 'com.thekaiverse.literature'; // Confirm package name
```

### 2. Update Package Name (if different)
If your actual package name differs from `com.thekaiverse.literature`:

**Android**: `android/app/build.gradle`
```gradle
defaultConfig {
    applicationId "com.thekaiverse.literature"
    // ...
}
```

**iOS**: In Xcode, update Bundle Identifier

## Testing Deep Links

### Android Testing
```bash
# Test custom scheme
adb shell am start -W -a android.intent.action.VIEW -d "literature://post/test123" com.thekaiverse.literature

# Test universal link
adb shell am start -W -a android.intent.action.VIEW -d "https://thekaiverse.com/post/test123" com.thekaiverse.literature
```

### iOS Testing
```bash
# Test custom scheme
xcrun simctl openurl booted "literature://post/test123"

# Test universal link
xcrun simctl openurl booted "https://thekaiverse.com/post/test123"
```

### Manual Testing
1. Share a post from the app
2. Send the link to yourself via Messages/Email
3. Click the link
4. Verify it opens the app (or redirects to store if app not installed)

## Store Listing Setup

### App Store (iOS)
1. Upload your app to App Store Connect
2. Note your App Store ID (found in App Store Connect URL)
3. Update `appStoreId` in `deep_link_service.dart`

### Play Store (Android)
1. Upload your app to Google Play Console
2. Confirm your package name matches `playStoreId` in code
3. In Play Console, go to "App content" → "Deep links"
4. Add your website URL: `https://thekaiverse.com`

## Verification

### Verify Android App Links
```bash
adb shell pm get-app-links com.thekaiverse.literature
```

Expected output should show `verified` status for thekaiverse.com

### Verify iOS Universal Links
- Open Safari on iOS device
- Go to: `https://thekaiverse.com/post/test123`
- Should see option to open in Literature app
- OR automatically opens app if configured correctly

## Troubleshooting

### Links don't open the app
1. Verify AASA file is accessible: `curl https://thekaiverse.com/.well-known/apple-app-site-association`
2. Verify assetlinks.json: `curl https://thekaiverse.com/.well-known/assetlinks.json`
3. Check SHA256 fingerprint matches
4. Reinstall the app (deep link configuration is cached)

### Share button doesn't work
1. Check that `share_plus` package is in pubspec.yaml
2. Verify permissions in AndroidManifest.xml
3. Check console for errors

### Deep links open browser instead of app
- Android: Re-verify Digital Asset Links
- iOS: Check Associated Domains configuration
- Clear app data and reinstall

## Implementation Summary

### Files Created/Modified:
- ✅ `lib/core/services/deep_link_service.dart` - Deep link generation
- ✅ `lib/core/services/share_service.dart` - Share functionality
- ✅ `lib/features/feed/widgets/feed_post_card.dart` - Share implementation
- ✅ `lib/features/post/screens/post_detail_screen.dart` - Share implementation
- ✅ `android/app/src/main/AndroidManifest.xml` - Android deep link config
- ✅ `ios/Runner/Info.plist` - iOS deep link config
- ✅ `lib/features/auth/screens/signup_screen.dart` - Website links updated

### To-Do for Production:
- [ ] Get App Store ID and update `deep_link_service.dart`
- [ ] Generate SHA256 fingerprint for release build
- [ ] Host AASA file at `https://thekaiverse.com/.well-known/apple-app-site-association`
- [ ] Host assetlinks.json at `https://thekaiverse.com/.well-known/assetlinks.json`
- [ ] Create redirect page at `https://thekaiverse.com/post/{postId}`
- [ ] Add Associated Domains in Xcode
- [ ] Test on real devices before production release
- [ ] Add deep link handling logic in app router

## Next Steps

To handle incoming deep links in your app, you'll need to:
1. Set up a deep link handler in your app's main router
2. Parse the incoming URL to extract the post ID
3. Navigate to the appropriate screen (PostDetailScreen)

This can be implemented using go_router's deep linking features or by listening to platform channel events.
