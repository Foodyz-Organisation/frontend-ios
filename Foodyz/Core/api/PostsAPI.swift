import Foundation
import UIKit

struct PostsAPIConstants {
    // Use machine's IP for physical device (same as AuthApi)
    static let baseURL = "http://192.168.100.28:3000/posts"
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
    
    // MARK: - Get Trending Posts
    /// Fetches trending posts from the server based on interactivity score
    /// - Parameter limit: Maximum number of trending posts to return (default: 10)
    /// - Returns: Array of Post objects sorted by interactivity score (likes + comments + saves)
    func getTrendingPosts(limit: Int = 10) async throws -> [Post] {
        guard var urlComponents = URLComponents(string: "\(PostsAPIConstants.baseURL)/trends") else {
            throw PostsError.invalidURL
        }
        
        // Add limit query parameter
        urlComponents.queryItems = [
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = urlComponents.url else {
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
        
        guard let userId = UserSession.shared.userId else {
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
    
    /// Delete a comment (only by the user who created it)
    func deleteComment(commentId: String) async throws {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/comments/\(commentId)") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        guard let userId = UserSession.shared.userId else {
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
        
        guard let userId = UserSession.shared.userId else {
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
        
        guard let userId = UserSession.shared.userId else {
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
        
        guard let userId = UserSession.shared.userId else {
            throw PostsError.serverError("User not logged in")
        }
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
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
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
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
