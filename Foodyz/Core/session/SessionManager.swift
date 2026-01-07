import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var userId: String?
    @Published private(set) var role: AppUserRole?
    @Published private(set) var displayName: String?
    @Published private(set) var avatarURL: String?
    @Published private(set) var email: String?

    private init() {
        restoreSession()
    }

    @MainActor
    func restoreSession() {
        let tm = TokenManager.shared
        if let token = tm.getAccessToken() {
            self.accessToken = token
            self.refreshToken = tm.getRefreshToken()
            self.userId = tm.getUserId()
            
            if let roleString = tm.getUserRole() {
                self.role = AppUserRole(rawValue: roleString) ?? .user
            }
            
            self.displayName = tm.getUserName()
            self.email = tm.getUserEmail()
            
            // Restore and sanitize avatar URL
            let rawUrl = tm.getUserProfilePhoto()
            self.avatarURL = SessionManager.sanitizeURL(rawUrl)
        }
    }

    @MainActor
    func update(with response: LoginResponse) {
        accessToken = response.access_token
        refreshToken = response.refresh_token
        userId = response.id
        role = AppUserRole(rawValue: response.role) ?? .user
        displayName = response.username
        email = response.email
        
        // Handle profile image: check avatarUrl first, then profilePictureUrl
        let rawUrl = response.avatarUrl ?? response.profilePictureUrl
        avatarURL = SessionManager.sanitizeURL(rawUrl)
    }

    @MainActor
    func clear() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        role = nil
        displayName = nil
        avatarURL = nil
        email = nil
    }

    @MainActor
    func updateProfileMetadata(name: String?, avatarURL: String?) {
        if let name, !name.isEmpty {
            displayName = name
        }
        // Sanitize any new URL coming in
        if let avatarURL = avatarURL {
            self.avatarURL = SessionManager.sanitizeURL(avatarURL)
        }
    }
    
    // MARK: - Helper: Sanitize URL for iOS
    /// Converts localhost/relative URLs to iOS simulator friendly URLs (127.0.0.1)
    static func sanitizeURL(_ urlString: String?) -> String? {
        guard let urlString = urlString, !urlString.isEmpty else { return nil }
        
        // Pass through data URIs (Base64 images) untouched
        if urlString.hasPrefix("data:") {
            return urlString
        }
        
        // If it's already a full web URL (http/https)
        if urlString.hasPrefix("http") {
            // Fix Android Emulator localhost (10.0.2.2) -> iOS localhost (127.0.0.1)
            return urlString.replacingOccurrences(of: "10.0.2.2", with: "127.0.0.1")
        }
        
        // If it's a relative path, prepend the base URL
        // Assuming your backend is at http://127.0.0.1:3000 based on PostsAPI
        let cleanPath = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
        return "http://127.0.0.1:3000/\(cleanPath)"
    }
}
