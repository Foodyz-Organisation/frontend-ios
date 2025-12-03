import Foundation
import UIKit

struct PostsAPIConstants {
    // Use localhost for iOS simulator, change to your machine's IP for physical device
    static let baseURL = "http://localhost:3000/posts"
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
    /// - Parameter mediaData: Array of Data objects representing images or videos
    /// - Returns: UploadResponse containing URLs of uploaded files
    func uploadMedia(mediaData: [Data]) async throws -> UploadResponse {
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
            // Determine file extension based on data header
            let fileExtension = getFileExtension(from: data)
            let fileName = "file\(index).\(fileExtension)"
            let mimeType = getMimeType(for: fileExtension)
            
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
    ///   - caption: Post caption
    ///   - mediaUrls: URLs of uploaded media
    ///   - mediaType: Type of media (image, reel, carousel)
    /// - Returns: Created Post object
    func createPost(userId: String, caption: String, mediaUrls: [String], mediaType: MediaType) async throws -> Post {
        guard let url = URL(string: PostsAPIConstants.baseURL) else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let createPostRequest = CreatePostRequest(
            caption: caption,
            mediaUrls: mediaUrls,
            mediaType: mediaType
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
    /// Fetches all posts from the server
    /// - Returns: Array of Post objects
    func getAllPosts() async throws -> [Post] {
        guard let url = URL(string: PostsAPIConstants.baseURL) else {
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
            return try JSONDecoder().decode([Post].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Get Posts by User ID
    /// Fetches all posts by a specific user
    /// - Parameter userId: ID of the user
    /// - Returns: Array of Post objects
    func getPostsByUserId(userId: String) async throws -> [Post] {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/user/\(userId)") else {
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
            return try JSONDecoder().decode([Post].self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    // MARK: - Get Trending Posts
    /// Fetches trending posts from the server
    /// - Returns: Array of Post objects
    func getTrendingPosts() async throws -> [Post] {
        // Fallback to client-side sorting since backend /trending endpoint is conflicting with /:id
        let allPosts = try await getAllPosts()
        
        // Sort by engagement (likes + comments + saves)
        let sortedPosts = allPosts.sorted { post1, post2 in
            let engagement1 = post1.likeCount + post1.commentCount + post1.saveCount
            let engagement2 = post2.likeCount + post2.commentCount + post2.saveCount
            return engagement1 > engagement2
        }
        
        // Return top 5 most interactive posts
        return Array(sortedPosts.prefix(5))
    }
    
    // MARK: - Get Single Post
    /// Fetches a single post by ID
    func getPost(id: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(id)") else {
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
            return try JSONDecoder().decode(Post.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
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
        
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        let dto = CreateCommentDto(text: text)
        request.httpBody = try JSONEncoder().encode(dto)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PostsError.serverError("Failed to create comment")
        }
        
        do {
            return try JSONDecoder().decode(Comment.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw PostsError.decodingError
        }
    }
    
    /// Delete a comment
    func deleteComment(commentId: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/comments/\(commentId)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PostsError.serverError("Failed to delete comment")
        }
    }
    
    // MARK: - Interactions
    
    /// Likes a post
    func likePost(postId: String) async throws {
        print("📍 Attempting to like post: \(postId)")
        
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/likes") else {
            print("❌ Invalid URL for like")
            throw PostsError.invalidURL
        }
        
        print("📍 Like URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add user ID header
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
            print("📍 User ID: \(userId)")
        } else {
            print("⚠️ No user ID found")
        }
        
        // Send empty JSON body to ensure server treats it as a valid request
        request.httpBody = "{}".data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📍 Like response status: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📍 Like response body: \(responseString)")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Like failed: \(message)")
                    throw PostsError.serverError("Failed to like post: \(message)")
                }
            }
            
            print("✅ Like successful")
        } catch {
            print("❌ Like error: \(error)")
            throw error
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
    
    /// Saves a post
    func savePost(postId: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/bookmarks") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let userId = UserSession.shared.userId {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }
        
        // Send empty JSON body
        request.httpBody = "{}".data(using: .utf8)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw PostsError.serverError("Failed to save post")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines file extension based on data header
    private func getFileExtension(from data: Data) -> String {
        let bytes = [UInt8](data.prefix(12))
        
        // Check for video formats
        if bytes.starts(with: [0x00, 0x00, 0x00]) && bytes.count >= 12 {
            let brandBytes = Array(bytes[8..<12])
            let brand = String(bytes: brandBytes, encoding: .ascii) ?? ""
            if brand.contains("mp4") || brand.contains("isom") {
                return "mp4"
            }
        }
        
        // Check for MOV
        if bytes.starts(with: [0x00, 0x00, 0x00]) {
            return "mov"
        }
        
        // Check for image formats
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) {
            return "jpg"
        }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47]) {
            return "png"
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
