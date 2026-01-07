import Foundation

/// Manages user's saved posts across sessions
class SavesManager {
    static let shared = SavesManager()
    
    private let savedPostsKey = "savedPosts"
    private var savedPostIds: Set<String> = []
    
    private init() {
        loadSavedPosts()
    }
    
    /// Get all saved post IDs for current user
    private func getSavedPosts() -> Set<String> {
        guard let userId = UserSession.shared.userId else { return [] }
        let key = "\(savedPostsKey)_\(userId)"
        if let array = UserDefaults.standard.array(forKey: key) as? [String] {
            return Set(array)
        }
        return []
    }
    
    /// Load saved posts from UserDefaults
    private func loadSavedPosts() {
        savedPostIds = getSavedPosts()
    }
    
    /// Save saved posts for current user
    private func saveSavedPosts(_ posts: Set<String>) {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(savedPostsKey)_\(userId)"
        UserDefaults.standard.set(Array(posts), forKey: key)
        savedPostIds = posts
    }
    
    /// Check if a post is saved
    func isSaved(postId: String) -> Bool {
        return savedPostIds.contains(postId)
    }
    
    /// Add a saved post
    func addSave(postId: String) {
        savedPostIds.insert(postId)
        saveSavedPosts(savedPostIds)
    }
    
    /// Remove a saved post
    func removeSave(postId: String) {
        savedPostIds.remove(postId)
        saveSavedPosts(savedPostIds)
    }
    
    /// Clear all saves (useful on logout)
    func clearSaves() {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(savedPostsKey)_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
        savedPostIds.removeAll()
    }
}

