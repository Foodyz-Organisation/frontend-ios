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
    
    /// Check if a post is saved by current user
    func isSaved(postId: String) -> Bool {
        return getSavedPosts().contains(postId)
    }
    
    /// Mark a post as saved
    func addSave(postId: String) {
        var savedPosts = getSavedPosts()
        savedPosts.insert(postId)
        saveSavedPosts(savedPosts)
    }
    
    /// Remove save from a post
    func removeSave(postId: String) {
        var savedPosts = getSavedPosts()
        savedPosts.remove(postId)
        saveSavedPosts(savedPosts)
    }
    
    /// Clear all saves (useful on logout)
    func clearSaves() {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(savedPostsKey)_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

