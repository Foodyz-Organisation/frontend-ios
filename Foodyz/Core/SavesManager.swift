import Foundation

/// Manages user's saved posts across sessions
class SavesManager {
    static let shared = SavesManager()
    
    private let savedPostsKey = "savedPosts"
    
    private init() {}
    
    /// Get all saved post IDs for current user
    private func getSavedPosts() -> Set<String> {
        guard let userId = UserSession.shared.userId else { return [] }
        let key = "\(savedPostsKey)_\(userId)"
        if let array = UserDefaults.standard.array(forKey: key) as? [String] {
            return Set(array)
        }
        return []
    }
    
    /// Save saved posts for current user
    private func saveSavedPosts(_ posts: Set<String>) {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(savedPostsKey)_\(userId)"
        UserDefaults.standard.set(Array(posts), forKey: key)
    }
    
    
    /// Clear all saves (useful on logout)
    func clearSaves() {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(savedPostsKey)_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

