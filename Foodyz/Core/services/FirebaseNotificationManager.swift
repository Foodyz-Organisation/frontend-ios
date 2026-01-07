import Foundation

// MARK: - Firebase Imports
// TODO: Install Firebase SDK first via Swift Package Manager
// Add package: https://github.com/firebase/firebase-ios-sdk
// Select: FirebaseMessaging, FirebaseCore, FirebaseAnalytics
#if canImport(FirebaseMessaging) && canImport(FirebaseCore)
import FirebaseMessaging
import FirebaseCore
#endif

/// Firebase Notification Manager - Handles FCM token management and syncing with backend
class FirebaseNotificationManager {
    static let shared = FirebaseNotificationManager()
    
    private let tokenManager: TokenManager
    private var currentToken: String?
    
    private init(tokenManager: TokenManager = TokenManager.shared) {
        self.tokenManager = tokenManager
    }
    
    // MARK: - Initialize Firebase
    func initialize() {
        // Firebase should be initialized in AppDelegate
        // This method is for any additional setup
        print("🔥 [FirebaseNotificationManager] Firebase initialized")
    }
    
    // MARK: - Get FCM Token
    func getFCMToken(completion: @escaping (String?) -> Void) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().token { token, error in
            if let error = error {
                print("❌ [FirebaseNotificationManager] Error fetching FCM token: \(error.localizedDescription)")
                completion(nil)
            } else if let token = token {
                print("🔥 [FirebaseNotificationManager] FCM Token: \(token)")
                self.currentToken = token
                completion(token)
            } else {
                print("⚠️ [FirebaseNotificationManager] FCM Token is nil")
                completion(nil)
            }
        }
        #else
        print("⚠️ [FirebaseNotificationManager] Firebase SDK not installed. Please install Firebase via Swift Package Manager.")
        completion(nil)
        #endif
    }
    
    // MARK: - Sync Token with Backend
    func syncTokenWithBackend(token: String) {
        // Check if user is logged in
        guard let accessToken = tokenManager.getAccessToken(),
              let userId = tokenManager.getUserId() else {
            print("⚠️ [FirebaseNotificationManager] User not logged in, skipping FCM token sync")
            return
        }
        
        let role = tokenManager.getUserRole() ?? "user"
        
        print("📤 [FirebaseNotificationManager] Syncing FCM token for \(role) (\(userId))")
        
        Task {
            do {
                if role == "professional" {
                    // Update Professional profile
                    try await syncProfessionalToken(professionalId: userId, token: token, accessToken: accessToken)
                    print("✅ [FirebaseNotificationManager] FCM Token updated for Professional")
                } else {
                    // Update User profile
                    try await syncUserToken(userId: userId, token: token, accessToken: accessToken)
                    print("✅ [FirebaseNotificationManager] FCM Token updated for User")
                }
            } catch {
                print("❌ [FirebaseNotificationManager] Failed to sync FCM token: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sync User Token
    private func syncUserToken(userId: String, token: String, accessToken: String) async throws {
        // Use direct PATCH request to update fcmToken
        let baseURLString = BaseUrlProvider.shared.baseURL
        guard let baseURL = URL(string: "\(baseURLString)/users/\(userId)") else {
            throw NSError(domain: "FirebaseNotificationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["fcmToken": token]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "FirebaseNotificationManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update FCM token"])
        }
        
        print("✅ [FirebaseNotificationManager] User FCM token synced successfully")
    }
    
    // MARK: - Sync Professional Token
    private func syncProfessionalToken(professionalId: String, token: String, accessToken: String) async throws {
        let dto: [String: Any] = ["fcmToken": token]
        
        return try await withCheckedThrowingContinuation { continuation in
            ProfessionalApi.shared.updateProfile(id: professionalId, dto: dto) { result in
                switch result {
                case .success:
                    print("✅ [FirebaseNotificationManager] Professional FCM token synced successfully")
                    continuation.resume()
                case .failure(let error):
                    print("❌ [FirebaseNotificationManager] Failed to sync professional FCM token: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Handle Token Refresh
    func handleTokenRefresh(token: String?) {
        guard let token = token else { return }
        print("🔄 [FirebaseNotificationManager] FCM Token refreshed: \(token)")
        currentToken = token
        syncTokenWithBackend(token: token)
    }
}


