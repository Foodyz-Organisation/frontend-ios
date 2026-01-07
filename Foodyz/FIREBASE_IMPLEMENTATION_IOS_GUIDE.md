# Firebase Cloud Messaging (FCM) - iOS Implementation Guide

## 📋 Overview

This guide explains how Firebase Cloud Messaging (FCM) was implemented in the Android app for push notifications, so you can replicate it in iOS. FCM is used to send push notifications for:
- Order updates
- Chat messages
- Incoming calls
- General notifications

---

## 🔧 Android Implementation Summary

### What Was Done in Android:

1. **Firebase SDK Integration**
   - Added Firebase BOM and messaging dependencies
   - Added Google Services plugin
   - Configured `google-services.json`

2. **FCM Token Management**
   - Get FCM token on app launch
   - Sync token with backend when user logs in
   - Update token when it refreshes

3. **Notification Handling**
   - Custom `FirebaseMessagingService` to handle incoming messages
   - Notification channels for different types
   - Display notifications when app is in background/foreground

4. **Backend Sync**
   - Send FCM token to backend after login
   - Update user/professional profile with FCM token
   - Backend uses token to send push notifications

---

## 📱 iOS Implementation Guide

### Step 1: Firebase SDK Setup

#### 1.1 Install Firebase SDK

**Using CocoaPods:**
```ruby
# Podfile
pod 'Firebase/Messaging'
pod 'Firebase/Analytics'  # Optional but recommended
```

**Using Swift Package Manager:**
1. In Xcode: File → Add Packages
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select: `FirebaseMessaging` and `FirebaseAnalytics`

#### 1.2 Download Configuration File

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click iOS app or add iOS app
4. Download `GoogleService-Info.plist`
5. Add to Xcode project (drag into project navigator)
6. **Important:** Ensure it's added to the target

#### 1.3 Initialize Firebase in AppDelegate

```swift
// AppDelegate.swift
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Request notification permissions
        requestNotificationPermissions(application: application)
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
        
        // Get FCM token
        getFCMToken()
        
        return true
    }
    
    // Request notification permissions (iOS 10+)
    func requestNotificationPermissions(application: UIApplication) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { granted, error in
                    if let error = error {
                        print("❌ Notification permission error: \(error.localizedDescription)")
                    } else if granted {
                        print("✅ Notification permission granted")
                        DispatchQueue.main.async {
                            application.registerForRemoteNotifications()
                        }
                    }
                }
            )
        } else {
            // iOS 9 and below
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
    }
    
    // Get FCM token
    func getFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("🔥 FCM Token: \(token)")
                // Sync with backend (see Step 3)
                self.syncTokenWithBackend(token: token)
            }
        }
    }
    
    // Handle APNs token registration
    func application(_ application: UIApplication, 
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ APNs token registered")
        // Pass APNs token to FCM
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, 
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    // Called when FCM token is refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔄 FCM Token refreshed: \(fcmToken ?? "nil")")
        
        if let token = fcmToken {
            // Sync new token with backend
            syncTokenWithBackend(token: token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in FOREGROUND
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📬 Notification received in foreground: \(userInfo)")
        
        // Show notification even when app is open
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    // Handle notification tap when app is in BACKGROUND
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 Notification tapped: \(userInfo)")
        
        // Handle notification tap (navigate to specific screen, etc.)
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
}
```

---

### Step 2: Backend Token Sync

#### 2.1 Create Notification Manager

```swift
// NotificationManager.swift
import Foundation
import FirebaseMessaging

class NotificationManager {
    static let shared = NotificationManager()
    
    private let tokenManager: TokenManager
    private let apiService: APIService
    
    init(tokenManager: TokenManager = TokenManager.shared,
         apiService: APIService = APIService.shared) {
        self.tokenManager = tokenManager
        self.apiService = apiService
    }
    
    // Sync FCM token with backend
    func syncTokenWithBackend(token: String) {
        // Check if user is logged in
        guard let accessToken = tokenManager.getAccessToken(),
              let userId = tokenManager.getUserId() else {
            print("⚠️ User not logged in, skipping FCM token sync")
            return
        }
        
        let role = tokenManager.getUserRole()
        
        print("📤 Syncing FCM token for \(role) (\(userId))")
        
        Task {
            do {
                if role == "professional" {
                    // Update Professional profile
                    try await apiService.updateProfessional(
                        id: userId,
                        fcmToken: token,
                        token: accessToken
                    )
                    print("✅ FCM Token updated for Professional")
                } else {
                    // Update User profile
                    try await apiService.updateUser(
                        userId: userId,
                        fcmToken: token,
                        token: accessToken
                    )
                    print("✅ FCM Token updated for User")
                }
            } catch {
                print("❌ Failed to sync FCM token: \(error.localizedDescription)")
            }
        }
    }
}
```

#### 2.2 API Service Methods

```swift
// APIService.swift (example)
extension APIService {
    // Update User Profile with FCM Token
    func updateUser(userId: String, fcmToken: String, token: String) async throws {
        let url = URL(string: "\(baseURL)/users/\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["fcmToken": fcmToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }
    
    // Update Professional Profile with FCM Token
    func updateProfessional(id: String, fcmToken: String, token: String) async throws {
        let url = URL(string: "\(baseURL)/professionalaccount/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["fcmToken": fcmToken]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }
}
```

#### 2.3 Sync Token After Login

```swift
// LoginViewModel.swift (example)
func login(email: String, password: String) async {
    // ... perform login ...
    
    // After successful login
    Messaging.messaging().token { token, error in
        if let token = token {
            NotificationManager.shared.syncTokenWithBackend(token: token)
        }
    }
}
```

---

### Step 3: Handle Incoming Notifications

#### 3.1 Notification Payload Structure

**Standard Notification:**
```json
{
  "notification": {
    "title": "New Order",
    "body": "You have a new order from John"
  },
  "data": {
    "type": "order",
    "orderId": "12345"
  }
}
```

**Call Notification:**
```json
{
  "data": {
    "type": "call",
    "conversationId": "conv123",
    "callerName": "John Doe",
    "isVideo": "true"
  }
}
```

#### 3.2 Handle Notification Tap

```swift
// AppDelegate.swift extension
extension AppDelegate {
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "order":
            if let orderId = userInfo["orderId"] as? String {
                // Navigate to order details
                navigateToOrderDetails(orderId: orderId)
            }
            
        case "call":
            if let conversationId = userInfo["conversationId"] as? String,
               let callerName = userInfo["callerName"] as? String,
               let isVideoString = userInfo["isVideo"] as? String {
                let isVideo = isVideoString == "true"
                // Show incoming call screen
                showIncomingCall(conversationId: conversationId, 
                                callerName: callerName, 
                                isVideo: isVideo)
            }
            
        case "message":
            if let conversationId = userInfo["conversationId"] as? String {
                // Navigate to chat
                navigateToChat(conversationId: conversationId)
            }
            
        default:
            break
        }
    }
    
    func navigateToOrderDetails(orderId: String) {
        // Use your navigation system (e.g., SwiftUI NavigationStack)
        // Example: NotificationCenter.post(name: .navigateToOrder, object: orderId)
    }
    
    func showIncomingCall(conversationId: String, callerName: String, isVideo: Bool) {
        // Show incoming call UI
        // Example: NotificationCenter.post(name: .incomingCall, object: [
        //     "conversationId": conversationId,
        //     "callerName": callerName,
        //     "isVideo": isVideo
        // ])
    }
    
    func navigateToChat(conversationId: String) {
        // Navigate to chat screen
        // Example: NotificationCenter.post(name: .navigateToChat, object: conversationId)
    }
}
```

---

### Step 4: Capabilities Setup

#### 4.1 Enable Push Notifications

1. In Xcode: Select your project
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Push Notifications**
5. Add **Background Modes**
   - Check **Remote notifications**

#### 4.2 App ID Configuration

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Select your App ID
3. Enable **Push Notifications**
4. Create/Download **APNs Certificate** or **APNs Auth Key**
5. Upload to Firebase Console:
   - Firebase Console → Project Settings → Cloud Messaging
   - Upload APNs certificate/key

---

## 🔄 Complete Flow

```
App Launch
    ↓
Firebase.configure()
    ↓
Request Notification Permissions
    ↓
Register for Remote Notifications
    ↓
Get APNs Token → Set to Messaging.messaging().apnsToken
    ↓
Get FCM Token → Messaging.messaging().token
    ↓
User Logs In
    ↓
Sync FCM Token with Backend (PATCH /users/:id or /professionalaccount/:id)
    ↓
Backend stores token
    ↓
Backend sends push notification
    ↓
iOS receives notification
    ↓
Handle notification (foreground/background/tap)
```

---

## 📝 Implementation Checklist

### Setup
- [ ] Install Firebase SDK (CocoaPods or SPM)
- [ ] Download `GoogleService-Info.plist` from Firebase Console
- [ ] Add `GoogleService-Info.plist` to Xcode project
- [ ] Initialize Firebase in `AppDelegate`
- [ ] Enable Push Notifications capability
- [ ] Enable Background Modes → Remote notifications
- [ ] Configure APNs in Apple Developer Portal
- [ ] Upload APNs certificate/key to Firebase Console

### Code Implementation
- [ ] Request notification permissions
- [ ] Register for remote notifications
- [ ] Implement `MessagingDelegate` for token refresh
- [ ] Implement `UNUserNotificationCenterDelegate` for notification handling
- [ ] Create `NotificationManager` for token sync
- [ ] Add API methods to update user/professional with FCM token
- [ ] Sync token after login
- [ ] Handle notification taps (navigation)
- [ ] Handle special notification types (calls, orders, etc.)

### Testing
- [ ] Test FCM token generation
- [ ] Test token sync with backend
- [ ] Test notification reception in foreground
- [ ] Test notification reception in background
- [ ] Test notification tap navigation
- [ ] Test token refresh handling

---

## 🎯 Key Differences: Android vs iOS

| Feature | Android | iOS |
|---------|---------|-----|
| **Config File** | `google-services.json` | `GoogleService-Info.plist` |
| **Service Class** | `FirebaseMessagingService` | `UNUserNotificationCenterDelegate` |
| **Token Method** | `FirebaseMessaging.getInstance().token` | `Messaging.messaging().token` |
| **APNs Token** | Not needed | Required (`Messaging.messaging().apnsToken`) |
| **Permissions** | Manifest | Runtime request |
| **Notification Channels** | Required (Android O+) | Not needed |

---

## 🔗 Related Files (Android Reference)

- **Build Config:** `app/build.gradle.kts` - Line 8, 239-241
- **Notification Manager:** `core/utils/NotificationManager.kt`
- **Messaging Service:** `core/service/MyFirebaseMessagingService.kt`
- **Main Activity:** `MainActivity.kt` - Line 42-43
- **Login Integration:** `feature_auth/viewmodels/LoginViewModel.kt` - Line 89-97
- **Manifest:** `AndroidManifest.xml` - Line 110-121

---

## 💡 iOS-Specific Tips

1. **APNs Certificate:** You need to upload APNs certificate/key to Firebase Console for iOS push notifications to work
2. **Background Mode:** Enable "Remote notifications" in Background Modes capability
3. **Token Refresh:** FCM token refreshes automatically; handle in `MessagingDelegate`
4. **Foreground Notifications:** iOS doesn't show notifications by default when app is open; implement `UNUserNotificationCenterDelegate` to show them
5. **Notification Categories:** Use UNNotificationCategory for action buttons (Answer/Decline for calls)
6. **Badge Management:** Update app badge count when notifications are received/read

---

## 🚨 Common Issues

1. **Token not generated:**
   - Check `GoogleService-Info.plist` is added to target
   - Verify APNs certificate is uploaded to Firebase
   - Check notification permissions are granted

2. **Notifications not received:**
   - Verify APNs certificate/key in Firebase Console
   - Check device is registered for remote notifications
   - Ensure app has notification permissions

3. **Token sync fails:**
   - Verify user is logged in
   - Check API endpoint and authentication
   - Verify network connectivity

---

This implementation allows your iOS app to receive push notifications just like the Android version!

