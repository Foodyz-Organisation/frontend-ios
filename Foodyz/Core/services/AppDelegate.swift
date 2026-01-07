import UIKit
import UserNotifications

// MARK: - Firebase Imports
// TODO: Install Firebase SDK first via Swift Package Manager
// Add package: https://github.com/firebase/firebase-ios-sdk
// Select: FirebaseMessaging, FirebaseCore, FirebaseAnalytics
#if canImport(FirebaseMessaging) && canImport(FirebaseCore)
import FirebaseCore
import FirebaseMessaging
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        #if canImport(FirebaseCore) && canImport(FirebaseMessaging)
        // Initialize Firebase
        FirebaseApp.configure()
        print("🔥 [AppDelegate] Firebase initialized")
        
        // Request notification permissions
        requestNotificationPermissions(application: application)
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
        
        // Get FCM token
        getFCMToken()
        #else
        print("⚠️ [AppDelegate] Firebase SDK not installed. Please install Firebase via Swift Package Manager.")
        // Still request notification permissions even without Firebase
        requestNotificationPermissions(application: application)
        #endif
        
        return true
    }
    
    // MARK: - Request Notification Permissions
    func requestNotificationPermissions(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("❌ [AppDelegate] Notification permission error: \(error.localizedDescription)")
                } else if granted {
                    print("✅ [AppDelegate] Notification permission granted")
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("⚠️ [AppDelegate] Notification permission denied")
                }
            }
        )
    }
    
    // MARK: - Get FCM Token
    func getFCMToken() {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ [AppDelegate] Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                print("🔥 [AppDelegate] FCM Token: \(token)")
                // Sync with backend if user is logged in
                FirebaseNotificationManager.shared.syncTokenWithBackend(token: token)
            }
        }
        #else
        print("⚠️ [AppDelegate] Firebase SDK not installed. Cannot get FCM token.")
        #endif
    }
    
    // MARK: - Handle APNs Token Registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ [AppDelegate] APNs token registered")
        #if canImport(FirebaseMessaging)
        // Pass APNs token to FCM
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - MessagingDelegate
#if canImport(FirebaseMessaging)
extension AppDelegate: MessagingDelegate {
    // Called when FCM token is refreshed
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🔄 [AppDelegate] FCM Token refreshed: \(fcmToken ?? "nil")")
        
        if let token = fcmToken {
            // Sync new token with backend
            FirebaseNotificationManager.shared.handleTokenRefresh(token: token)
        }
    }
}
#endif

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in FOREGROUND
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        print("📬 [AppDelegate] Notification received in foreground: \(userInfo)")
        
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
        print("👆 [AppDelegate] Notification tapped: \(userInfo)")
        
        // Handle notification tap (navigate to specific screen, etc.)
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    // MARK: - Handle Notification Tap
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let data = userInfo["data"] as? [String: Any],
              let type = data["type"] as? String else {
            // Try direct access if data is not nested
            guard let type = userInfo["type"] as? String else {
                print("⚠️ [AppDelegate] No notification type found")
                return
            }
            handleNotificationType(type: type, userInfo: userInfo)
            return
        }
        
        handleNotificationType(type: type, userInfo: data)
    }
    
    private func handleNotificationType(type: String, userInfo: [AnyHashable: Any]) {
        switch type {
        case "order", "ORDER_CREATED", "ORDER_CONFIRMED", "ORDER_COMPLETED":
            if let orderId = userInfo["orderId"] as? String {
                navigateToOrderDetails(orderId: orderId)
            }
            
        case "call":
            if let conversationId = userInfo["conversationId"] as? String,
               let callerName = userInfo["callerName"] as? String,
               let isVideoString = userInfo["isVideo"] as? String {
                let isVideo = isVideoString == "true"
                showIncomingCall(conversationId: conversationId, callerName: callerName, isVideo: isVideo)
            }
            
        case "message", "MESSAGE_RECEIVED":
            if let conversationId = userInfo["conversationId"] as? String {
                navigateToChat(conversationId: conversationId)
            }
            
        default:
            print("ℹ️ [AppDelegate] Unhandled notification type: \(type)")
        }
    }
    
    private func navigateToOrderDetails(orderId: String) {
        print("📍 [AppDelegate] Navigating to order details: \(orderId)")
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToOrderDetails"),
            object: nil,
            userInfo: ["orderId": orderId]
        )
    }
    
    private func showIncomingCall(conversationId: String, callerName: String, isVideo: Bool) {
        print("📞 [AppDelegate] Showing incoming call: \(conversationId)")
        NotificationCenter.default.post(
            name: NSNotification.Name("IncomingCall"),
            object: nil,
            userInfo: [
                "conversationId": conversationId,
                "callerName": callerName,
                "isVideo": isVideo
            ]
        )
    }
    
    private func navigateToChat(conversationId: String) {
        print("💬 [AppDelegate] Navigating to chat: \(conversationId)")
        NotificationCenter.default.post(
            name: NSNotification.Name("NavigateToChat"),
            object: nil,
            userInfo: ["conversationId": conversationId]
        )
    }
}

