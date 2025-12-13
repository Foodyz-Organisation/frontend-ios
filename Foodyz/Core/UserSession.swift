import Foundation
import Combine

/// Manages user session state across the app
class UserSession: ObservableObject {
    static let shared = UserSession()
    
    @Published var userId: String?
    @Published var userEmail: String?
    @Published var userRole: String?
    
    private let userIdKey = "currentUserId"
    private let userEmailKey = "currentUserEmail"
    private let userRoleKey = "currentUserRole"
    
    private init() {
        // Load saved session on init
        loadSession()
    }
    
    /// Save user session after login
    func saveSession(userId: String, email: String, role: String) {
        self.userId = userId
        self.userEmail = email
        self.userRole = role
        
        UserDefaults.standard.set(userId, forKey: userIdKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
        UserDefaults.standard.set(role, forKey: userRoleKey)
    }
    
    /// Load saved session from UserDefaults
    private func loadSession() {
        userId = UserDefaults.standard.string(forKey: userIdKey)
        userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        userRole = UserDefaults.standard.string(forKey: userRoleKey)
    }
    
    /// Clear session on logout
    func clearSession() {
        userId = nil
        userEmail = nil
        userRole = nil
        
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        UserDefaults.standard.removeObject(forKey: userRoleKey)
        
        // Clear liked posts
        LikesManager.shared.clearLikes()
        // Clear saved posts
        SavesManager.shared.clearSaves()
    }
    
    /// Check if user is logged in
    var isLoggedIn: Bool {
        return userId != nil
    }
}
