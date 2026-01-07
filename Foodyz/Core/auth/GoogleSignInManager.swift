import Foundation
import GoogleSignIn
import UIKit

/// Manager for Google Sign In operations
class GoogleSignInManager {
    static let shared = GoogleSignInManager()
    
    private init() {}
    
    // MARK: - Configuration
    /// Configure with your Google OAuth Client ID
    /// TODO: Replace with your actual iOS Client ID from Google Cloud Console
    /// OR use the Web Client ID for cross-platform compatibility
    private var clientID: String {
        // Option 1: Use iOS-specific client ID (requires GoogleService-Info.plist)
        // return GIDConfiguration.clientID ?? ""
        
        // Option 2: Use Web Client ID (simpler, cross-platform)
        // Replace with your actual Web Client ID
        return "152459113648-e01p479h7v2cjidjao7jnp4pph6iho2a.apps.googleusercontent.com"
    }
    
    // MARK: - Sign In
    /// Initiates Google Sign In flow and returns the ID token
    func signIn() async throws -> String {
        guard let presentingViewController = getRootViewController() else {
            throw GoogleSignInError.noViewController
        }
        
        // Use the Web Client ID as the serverClientID to ensure the ID token is valid for the backend
        // The clientID should ideally be the iOS Client ID from Info.plist/GoogleService-Info.plist
        // If GIDConfiguration is not used, it defaults to the one in Info.plist if available.
        // specific serverClientID is important for backend verification.
        
        let webClientID = "152459113648-e01p479h7v2cjidjao7jnp4pph6iho2a.apps.googleusercontent.com"
        
        // NOTE: We rely on the implicit configuration from Info.plist for the iOS client ID
        // But we explicitly set the serverClientID to get the right audience in the ID Token for the backend
        let config = GIDConfiguration(clientID: clientID, serverClientID: webClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController
            )
            
            // The ID token to send to the backend
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.noIDToken
            }
            
            print("✅ Google Sign In successful")
            print("📧 Email: \(result.user.profile?.email ?? "N/A")")
            print("👤 Name: \(result.user.profile?.name ?? "N/A")")
            
            return idToken
            
        } catch {
            print("❌ Google Sign In error: \(error.localizedDescription)")
            // Provide more user-friendly error mapping if possible, similar to Android
            if (error as NSError).code == GIDSignInError.canceled.rawValue {
                 throw GoogleSignInError.signInFailed("Sign-In canceled")
            }
            throw GoogleSignInError.signInFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Get User Profile Info
    /// Returns the currently signed-in user's profile information
    func getCurrentUserProfile() -> (name: String?, email: String?, photoUrl: String?)? {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            return nil
        }
        
        let profile = user.profile
        return (
            name: profile?.name,
            email: profile?.email,
            photoUrl: profile?.imageURL(withDimension: 200)?.absoluteString
        )
    }
    
    // MARK: - Sign Out
    /// Signs out from Google
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        print("✅ Signed out from Google")
    }
    
    // MARK: - Handle URL (for OAuth callback)
    /// Call this from your app delegate or scene delegate to handle OAuth callbacks
    func handleURL(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Helper Methods
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        
        // Get the topmost presented view controller
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}

// MARK: - Custom Errors
enum GoogleSignInError: LocalizedError {
    case noViewController
    case noIDToken
    case signInFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noViewController:
            return "Unable to find a view controller to present Google Sign In"
        case .noIDToken:
            return "Failed to retrieve ID token from Google"
        case .signInFailed(let message):
            return "Google Sign In failed: \(message)"
        }
    }
}
