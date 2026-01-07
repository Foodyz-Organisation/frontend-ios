import Foundation
import UIKit

struct PostsAPIConstants {
    // Use BaseUrlProvider for automatic device detection
    static var baseURL: String {
        return "\(BaseUrlProvider.shared.baseURL)/posts"
    }
}

// MARK: - Share Post DTOs
struct SharePostRequest: Codable {
    let recipientId: String
    let message: String
}

struct SharePostResponse: Codable {
    let success: Bool
    let message: String  // Can be a string like "Post shared successfully"
    let data: SharePostData?
}

struct SharePostData: Codable {
    let conversation: SharePostConversation?
    let sharedMessage: SharePostSharedMessage?
    let post: SharePostPostData?
}

struct SharePostConversation: Codable {
    let id: String
    let participants: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case participants
    }
}

struct SharePostSharedMessage: Codable {
    let id: String
    let type: String
    let content: String
    let meta: SharedPostMeta?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case type, content, meta
        case createdAt
    }
}

struct SharePostPostData: Codable {
    let id: String
    let caption: String
    let mediaUrls: [String]
    let primaryImageUrl: String?
    let mediaType: String
    let foodType: String?
    let owner: SharePostOwner?
    let price: Double?
    let preparationTime: Int?
    let stats: SharePostStats?
}

struct SharePostOwner: Codable {
    let id: String
    let name: String
    let avatarUrl: String?
}

struct SharePostStats: Codable {
    let likes: Int
    let comments: Int
    let saves: Int
    let views: Int
}

struct SharedPostMeta: Codable {
    let sharedPostId: String?
    let sharedPostCaption: String?
    let sharedPostImage: String?
    let isSharedPost: Bool?
    let sharedBy: SharedBy?
    let postId: String?
    let postPrimaryImageUrl: String?
    let postCaption: String?
    let postMediaUrls: [String]?
    let postMediaType: String?
    let postFoodType: String?
    let postOwner: PostOwner?
    let price: Double?
    let preparationTime: Int?
    let likeCount: Int?
    let commentCount: Int?
    let saveCount: Int?
    let viewsCount: Int?
    let postCreatedAt: String?
    let sharedAt: String?
}

struct SharedBy: Codable {
    let id: String
    let name: String
    let model: String
}

struct PostOwner: Codable {
    let id: String
    let name: String
    let avatarUrl: String?
}

enum PostsError: Error, LocalizedError {
    case invalidURL
    case decodingError
    case encodingError
    case serverError(String)
    case fileConversionError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API address is invalid."
        case .decodingError:
            return "Failed to parse server response."
        case .encodingError:
            return "Failed to prepare request data."
        case .serverError(let message):
            return "Server Error: \(message)"
        case .fileConversionError:
            return "Failed to process media file."
        case .unknownError:
            return "An unexpected error occurred."
        }
    }
}

class PostsAPI {
    static let shared = PostsAPI()
    
    private init() {}
    
    // MARK: - Upload Media Files
    /// Uploads media files (images/videos) to the server
    /// - Parameters:
    ///   - mediaData: Array of Data objects representing images or videos
    ///   - isVideoArray: Array of booleans indicating if each media item is a video (optional, will auto-detect if not provided)
    /// - Returns: UploadResponse containing URLs of uploaded files
    func uploadMedia(mediaData: [Data], isVideoArray: [Bool]? = nil) async throws -> UploadResponse {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/uploads") else {
            throw PostsError.invalidURL
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add each file to the multipart form data
        for (index, data) in mediaData.enumerated() {
            // Determine if this is a video (use provided flag or auto-detect)
            let isVideo = isVideoArray?[index] ?? false
            
            // Determine file extension and MIME type
            let fileExtension: String
            let mimeType: String
            
            if isVideo {
                // For videos, check the actual file format from data
                fileExtension = getVideoFileExtension(from: data)
                mimeType = getMimeType(for: fileExtension)
            } else {
                // For images, detect from data header
                fileExtension = getImageFileExtension(from: data)
                mimeType = getMimeType(for: fileExtension)
            }
            
            let fileName = "file\(index).\(fileExtension)"
            
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError(message)
        }
        
        do {
            return try JSONDecoder().decode(UploadResponse.self, from: responseData)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Create Post
    /// Creates a new post
    /// - Parameters:
    ///   - userId: ID of the user creating the post
    ///   - ownerType: Type of owner ("UserAccount" or "ProfessionalAccount")
    ///   - caption: Post caption
    ///   - mediaUrls: URLs of uploaded media
    ///   - mediaType: Type of media (image, reel, carousel)
    ///   - foodType: Food type (required)
    ///   - price: Price in TND (optional)
    ///   - preparationTime: Preparation time in minutes (optional)
    /// - Returns: Created Post object
    func createPost(userId: String, ownerType: String, caption: String, mediaUrls: [String], mediaType: MediaType, foodType: String, price: Double? = nil, preparationTime: Int? = nil) async throws -> Post {
        guard let url = URL(string: PostsAPIConstants.baseURL) else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let createPostRequest = CreatePostRequest(
            caption: caption,
            mediaUrls: mediaUrls,
            mediaType: mediaType,
            foodType: foodType,
            price: price,
            preparationTime: preparationTime
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(createPostRequest)
        } catch {
            throw PostsError.encodingError
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError(message)
        }
        
        do {
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Get All Posts
    /// Fetches all posts from the server (personalized feed based on user interactions)
    /// - Returns: Array of Post objects ordered by user preferences (Cosign Formulary)
    func getAllPosts() async throws -> [Post] {
        guard let url = URL(string: PostsAPIConstants.baseURL) else {
            print("❌ [PostsAPI] Invalid URL: \(PostsAPIConstants.baseURL)")
            throw PostsError.invalidURL
        }
        
        print("📡 [PostsAPI] Fetching personalized posts from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add x-user-id header for personalization (Cosign Formulary)
        // Backend uses this to return posts ordered by user preferences
        let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId()
        if let userId = userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
            print("✅ [PostsAPI] Added x-user-id header for personalization: \(userId)")
        } else {
            print("⚠️ [PostsAPI] No user ID available - feed will not be personalized")
        }
        
        // Add authentication token if available
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("✅ [PostsAPI] Added authentication token")
        } else {
            print("⚠️ [PostsAPI] No authentication token available")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [PostsAPI] No HTTP response")
            throw PostsError.serverError("No server response")
        }
        
        print("📥 [PostsAPI] Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [PostsAPI] Server error: \(message)")
            throw PostsError.serverError(message)
        }
        
        print("✅ [PostsAPI] Received \(data.count) bytes")
        
        do {
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("✅ [PostsAPI] Successfully decoded \(posts.count) posts")
            return posts
        } catch {
            print("❌ [PostsAPI] Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [PostsAPI] Response data: \(responseString.prefix(500))")
            }
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Get Trending Posts
    /// Fetches trending posts from the server based on interactivity score
    /// Backend logic: Aggregates posts, calculates interactivityScore (likeCount + commentCount + saveCount),
    /// sorts by interactivityScore descending, then createdAt descending, limits to specified count,
    /// and populates ownerId using ownerModel (supports both UserAccount and ProfessionalAccount)
    /// - Parameter limit: Maximum number of trending posts to return (default: 10)
    /// - Returns: Array of Post objects sorted by interactivity score (likes + comments + saves)
    func getTrendingPosts(limit: Int = 10) async throws -> [Post] {
        guard var urlComponents = URLComponents(string: "\(PostsAPIConstants.baseURL)/trends") else {
            print("❌ [PostsAPI] Invalid URL for trending posts")
            throw PostsError.invalidURL
        }
        
        // Add limit query parameter (matches backend limit parameter)
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents.url else {
            print("❌ [PostsAPI] Failed to create URL from components")
            throw PostsError.invalidURL
        }
        
        print("📡 [PostsAPI] Fetching trending posts from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available (required for some endpoints)
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            print("✅ [PostsAPI] Added authentication token for trending posts")
        } else {
            print("⚠️ [PostsAPI] No authentication token available for trending posts")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [PostsAPI] No HTTP response for trending posts")
            throw PostsError.serverError("No server response")
        }
        
        print("📥 [PostsAPI] Trending posts response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ [PostsAPI] Server error for trending posts: \(message)")
            throw PostsError.serverError(message)
        }
        
        print("✅ [PostsAPI] Received \(data.count) bytes for trending posts")
        
        do {
            // Decode array of Post objects
            // Backend returns posts with populated ownerId (as Owner object) and ownerModel
            // The Post decoder handles both populated ownerId (new format) and userId string (old format)
            let posts = try JSONDecoder().decode([Post].self, from: data)
            print("✅ [PostsAPI] Successfully decoded \(posts.count) trending posts")
            
            // Log owner information for debugging
            for (index, post) in posts.enumerated() {
                if let owner = post.owner {
                    print("📊 [PostsAPI] Trending post \(index + 1): Owner=\(owner.displayName), Score=(likes:\(post.likeCount) + comments:\(post.commentCount) + saves:\(post.saveCount) = \(post.likeCount + post.commentCount + post.saveCount))")
                } else {
                    print("⚠️ [PostsAPI] Trending post \(index + 1): Owner not populated (ownerId: \(post.ownerId))")
                }
            }
            
            return posts
        } catch {
            print("❌ [PostsAPI] Decoding error for trending posts: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 [PostsAPI] Response data: \(responseString.prefix(500))")
            }
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Get Single Post
    /// Fetches a single post by ID
    /// Get a single post by ID (automatically tracks view for personalization)
    /// - Parameter id: Post ID
    /// - Returns: Post object
    /// - Note: Backend automatically tracks view when x-user-id header is present
    func getPost(id: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(id)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add x-user-id header for view tracking (Cosign Formulary)
        // Backend automatically tracks this view and updates user preferences
        let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId()
        if let userId = userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
            print("✅ [PostsAPI] Added x-user-id header for view tracking: \(userId)")
        }
        
        // Add authentication token if available
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError(message)
        }
        
        do {
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Update Post
    /// Updates a post's caption
    /// - Parameters:
    ///   - postId: ID of the post to update
    ///   - caption: New caption text
    func updatePost(postId: String, caption: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Add owner type header based on user role
        let userRole = UserSession.shared.userRole ?? "user"
        let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let body = ["caption": caption]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError(message)
        }
        
        print("✅ Post updated successfully")
    }
    
    // MARK: - Delete Post
    /// Deletes a post
    /// - Parameter postId: ID of the post to delete
    func deletePost(postId: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Add owner type header based on user role
        let userRole = UserSession.shared.userRole ?? "user"
        let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError(message)
        }
        
        print("✅ Post deleted successfully")
    }
    
    // MARK: - Comments
    
    /// Get all comments for a post
    func getComments(postId: String) async throws -> [Comment] {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/comments") else {
            throw PostsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError(message)
        }
        
        do {
            return try JSONDecoder().decode([Comment].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    /// Create a new comment on a post
    func createComment(postId: String, text: String) async throws -> Comment {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/comments") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let dto = CreateCommentDto(text: text)
        request.httpBody = try JSONEncoder().encode(dto)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to create comment: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(Comment.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw PostsError.decodingError
        }
    }
    
    /// Update a comment (only by the user who created it)
    func updateComment(commentId: String, text: String) async throws -> Comment {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/comments/\(commentId)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let dto = CreateCommentDto(text: text)
        request.httpBody = try JSONEncoder().encode(dto)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to update comment: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(Comment.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw PostsError.decodingError
        }
    }
    
    /// Delete a comment (only by the user who created it)
    func deleteComment(commentId: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/comments/\(commentId)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to delete comment: \(message)")
        }
    }
    
    // MARK: - Interactions
    
    /// Likes a post (adds a like)
    func likePost(postId: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/like") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"  // Backend uses PATCH, not POST
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        request.httpBody = "{}".data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to like post: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    /// Unlikes a post (removes a like)
    func unlikePost(postId: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/like") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to unlike post: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    /// Comments on a post
    func commentPost(postId: String, text: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/comments") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        let body = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PostsError.serverError("Failed to comment on post")
        }
    }
    
    /// Gets all saved posts for the current user
    func getSavedPosts() async throws -> [Post] {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/saved") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        // Add owner type header
        let userRole = UserSession.shared.userRole ?? "user"
        let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        // Add authentication token
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to get saved posts: \(message)")
        }
        
        do {
            return try JSONDecoder().decode([Post].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Save Post
    
    /// Saves a post (bookmarks it)
    func savePost(postId: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/save") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        // Add owner type header
        let userRole = UserSession.shared.userRole ?? "user"
        let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        // Add authentication token
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to save post: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    /// Unsaves a post (removes bookmark)
    func unsavePost(postId: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/save") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        // Add owner type header
        let userRole = UserSession.shared.userRole ?? "user"
        let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        // Add authentication token
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to unsave post: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Share Post
    
    /// Shares a post with a recipient
    func sharePost(postId: String, recipientId: String, message: String = "Shared a post with you") async throws -> SharePostResponse {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/share") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Try UserSession first, fallback to TokenManager
        guard let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId() else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        // Add owner type header
        let userRole = UserSession.shared.userRole ?? "user"
        let ownerType = userRole == "professional" ? "ProfessionalAccount" : "UserAccount"
        request.setValue(ownerType, forHTTPHeaderField: "x-owner-type")
        
        // Add authentication token
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Create request body
        let shareRequest = SharePostRequest(recipientId: recipientId, message: message)
        request.httpBody = try JSONEncoder().encode(shareRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to share post: \(message)")
        }
        
        do {
            return try JSONDecoder().decode(SharePostResponse.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Food Types & Filtering
    
    /// Get all available food types
    func getFoodTypes() async throws -> [String] {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/food-types") else {
            throw PostsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to get food types: \(message)")
        }
        
        do {
            return try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    /// Get posts filtered by food type
    func getPostsByFoodType(_ foodType: String) async throws -> [Post] {
        // URL encode food type to handle spaces
        guard let encodedFoodType = foodType.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw PostsError.invalidURL
        }
        
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/by-food-type/\(encodedFoodType)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add x-user-id header for personalization
        let userId = UserSession.shared.userId ?? TokenManager.shared.getUserId()
        if let userId = userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Add authentication token if available
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PostsError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw PostsError.serverError("Failed to get posts by food type: \(message)")
        }
        
        do {
            return try JSONDecoder().decode([Post].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines video file extension based on data header
    private func getVideoFileExtension(from data: Data) -> String {
        let bytes = [UInt8](data.prefix(20))
        
        // Check for MP4 format (ISO Base Media / MPEG-4)
        // MP4 files typically start with ftyp box at offset 4
        if bytes.count >= 12 {
            // Check for ftyp box (ftyp is at bytes 4-8)
            if bytes.count >= 8 {
                let boxType = String(bytes: Array(bytes[4..<8]), encoding: .ascii) ?? ""
                if boxType == "ftyp" {
                    // Check brand at bytes 8-12
                    let brandBytes = Array(bytes[8..<min(12, bytes.count)])
                    if brandBytes.count >= 4 {
                        let brand = String(bytes: brandBytes, encoding: .ascii) ?? ""
                        if brand.contains("mp4") || brand.contains("isom") || brand.contains("avc1") || brand.contains("M4V") {
                            return "mp4"
                        }
                    }
                }
            }
        }
        
        // Check for MOV format (QuickTime)
        // MOV files also use ftyp but with different brands
        if bytes.count >= 12 {
            if bytes.count >= 8 {
                let boxType = String(bytes: Array(bytes[4..<8]), encoding: .ascii) ?? ""
                if boxType == "ftyp" {
                    let brandBytes = Array(bytes[8..<min(12, bytes.count)])
                    if brandBytes.count >= 4 {
                        let brand = String(bytes: brandBytes, encoding: .ascii) ?? ""
                        if brand.contains("qt") || brand.contains("moov") {
                            return "mov"
                        }
                    }
                }
            }
        }
        
        // Check for MOV by looking at mdat/moov atoms directly
        if bytes.count >= 8 {
            let atomType = String(bytes: Array(bytes[4..<8]), encoding: .ascii) ?? ""
            if atomType == "mdat" || atomType == "moov" {
                return "mov"
            }
        }
        
        // Default to mp4 for videos (most common)
        return "mp4"
    }
    
    /// Determines image file extension based on data header
    private func getImageFileExtension(from data: Data) -> String {
        let bytes = [UInt8](data.prefix(8))
        
        // Check for JPEG
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "jpg"
        }
        
        // Check for PNG
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return "png"
        }
        
        // Check for GIF
        if bytes.starts(with: [0x47, 0x49, 0x46, 0x38]) {
            return "gif"
        }
        
        // Default to jpg for images
        return "jpg"
    }
    
    /// Returns MIME type for file extension
    private func getMimeType(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        default:
            return "application/octet-stream"
        }
    }
}
