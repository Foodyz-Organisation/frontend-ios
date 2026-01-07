# Firebase SDK Installation Instructions

## ⚠️ Important: Install Firebase SDK First

The Firebase notification code is ready, but you need to install the Firebase SDK first.

## Option 1: Swift Package Manager (Recommended)

### Step 1: Add Firebase Package in Xcode

1. Open your project in Xcode
2. Go to **File → Add Packages...**
3. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
4. Click **Add Package**
5. Select these products:
   - ✅ **FirebaseMessaging**
   - ✅ **FirebaseCore**
   - ✅ **FirebaseAnalytics** (optional but recommended)
6. Click **Add Package**
7. Make sure they're added to your **Foodyz** target

### Step 2: Download GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click the iOS icon to add an iOS app
4. Enter your bundle identifier (found in Xcode project settings)
5. Download `GoogleService-Info.plist`
6. Drag and drop it into your Xcode project
7. **Important:** Make sure it's added to the **Foodyz** target

### Step 3: Enable Capabilities

1. In Xcode, select your project
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Push Notifications**
5. Add **Background Modes**
   - Check **Remote notifications**

### Step 4: Configure APNs in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Project Settings → Cloud Messaging
3. Upload your APNs certificate or Auth Key
   - Get it from [Apple Developer Portal](https://developer.apple.com/)
   - Certificates → Keys → Create new key (APNs Auth Key) or Certificate

## Option 2: CocoaPods (Alternative)

If you prefer CocoaPods:

### Step 1: Create Podfile

In your project root directory, create a `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!

target 'Foodyz' do
  pod 'Firebase/Messaging'
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
end
```

### Step 2: Install Pods

```bash
cd /Users/mouscoumohamedkhalil/Documents/Dam\ Final\ Version/iosview/Foodyz
pod install
```

### Step 3: Open Workspace

After installation, always open `Foodyz.xcworkspace` (not `.xcodeproj`)

## Verification

After installation, the build errors should disappear. You can verify by:

1. Building the project (⌘+B)
2. Check that `FirebaseMessaging` and `FirebaseCore` are available
3. Run the app - you should see Firebase initialization logs in console

## Troubleshooting

### Error: "No such module 'FirebaseMessaging'"
- Make sure you added the package to the correct target
- Clean build folder (⌘+Shift+K) and rebuild
- Restart Xcode

### Error: "GoogleService-Info.plist not found"
- Make sure the file is in the project root
- Check it's added to the target in "Target Membership"

### Notifications not working
- Verify APNs certificate is uploaded to Firebase Console
- Check notification permissions are granted
- Verify capabilities are enabled

## Next Steps

Once Firebase is installed:
1. The code will automatically initialize on app launch
2. FCM token will be generated and synced with backend
3. Push notifications will start working

