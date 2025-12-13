import Foundation

/// Manages user's liked posts across sessions
class LikesManager {
    static let shared = LikesManager()
    
    private let likedPostsKey = "likedPosts"
    
    private init() {}
    
    /// Get all liked post IDs for current user
    private func getLikedPosts() -> Set<String> {
        guard let userId = UserSession.shared.userId else { return [] }
        let key = "\(likedPostsKey)_\(userId)"
        if let array = UserDefaults.standard.array(forKey: key) as? [String] {
            return Set(array)
        }
        return []
    }
    
    /// Save liked posts for current user
    private func saveLikedPosts(_ posts: Set<String>) {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(likedPostsKey)_\(userId)"
        UserDefaults.standard.set(Array(posts), forKey: key)
    }
    
    /// Check if a post is liked by current user
    func isLiked(postId: String) -> Bool {
        return getLikedPosts().contains(postId)
    }
    
    /// Mark a post as liked
    func addLike(postId: String) {
        var likedPosts = getLikedPosts()
        likedPosts.insert(postId)
        saveLikedPosts(likedPosts)
    }
    
    /// Remove like from a post
    func removeLike(postId: String) {
        var likedPosts = getLikedPosts()
        likedPosts.remove(postId)
        saveLikedPosts(likedPosts)
    }
    
    /// Clear all likes (useful on logout)
    func clearLikes() {
        guard let userId = UserSession.shared.userId else { return }
        let key = "\(likedPostsKey)_\(userId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

