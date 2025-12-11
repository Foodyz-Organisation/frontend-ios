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
    ///   - ownerType: Type of owner ("UserAccount" or "ProfessionalAccount")
    ///   - caption: Post caption
    ///   - mediaUrls: URLs of uploaded media
    ///   - mediaType: Type of media (image, reel, carousel)
    /// - Returns: Created Post object
    func createPost(userId: String, ownerType: String, caption: String, mediaUrls: [String], mediaType: MediaType) async throws -> Post {
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
    
    /// Saves a post (bookmark)
    func savePost(postId: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/save") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let userId = UserSession.shared.userId else {
            print("❌ Save Post Error: User not logged in")
            throw PostsError.serverError("User not logged in")
        }
        
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        print("📌 Saving post - URL: \(url.absoluteString)")
        print("📌 User ID: \(userId)")
        print("📌 Post ID: \(postId)")
        print("📌 HTTP Method: PATCH")
        print("📌 Headers: x-user-id = \(userId), Content-Type = application/json")
        
        // Send empty JSON body (some servers require this for PATCH)
        request.httpBody = "{}".data(using: .utf8)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
        
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Save Post Error: No server response")
                throw PostsError.serverError("No server response")
            }
            
            print("📌 Save Post Response Status: \(httpResponse.statusCode)")
            print("📌 Response Headers: \(httpResponse.allHeaderFields)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Save Post Error: Status \(httpResponse.statusCode) - \(message)")
                
                // Check for specific error codes
                if httpResponse.statusCode == 404 {
                    throw PostsError.serverError("Post not found")
                } else if httpResponse.statusCode == 409 {
                    throw PostsError.serverError("User has already saved this post")
                }
                
                throw PostsError.serverError("Failed to save post: \(message)")
            }
            
            do {
                let savedPost = try JSONDecoder().decode(Post.self, from: data)
                print("✅ Post saved successfully")
                print("✅ Updated saveCount: \(savedPost.saveCount)")
                return savedPost
            } catch {
                print("❌ Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("❌ Response data: \(responseString)")
                }
                throw PostsError.decodingError
            }
        } catch let urlError as URLError {
            print("❌ URL Error: \(urlError.localizedDescription)")
            print("❌ URL Error Code: \(urlError.code.rawValue)")
            print("❌ URL Error Domain: \(urlError.localizedDescription)")
            if urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
                throw PostsError.serverError("Cannot connect to server. Please check if the backend is running on \(PostsAPIConstants.baseURL)")
            }
            throw PostsError.serverError("Network error: \(urlError.localizedDescription)")
        } catch {
            print("❌ Unexpected error: \(error)")
            print("❌ Error type: \(type(of: error))")
            throw error
        }
    }
    
    /// Unsaves a post (removes bookmark)
    func unsavePost(postId: String) async throws -> Post {
        guard let url = URL(string: "\(PostsAPIConstants.baseURL)/\(postId)/save") else {
            throw PostsError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        guard let userId = UserSession.shared.userId else {
            print("❌ Unsave Post Error: User not logged in")
            throw PostsError.serverError("User not logged in")
        }
        
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        print("📌 Unsaving post - URL: \(url.absoluteString)")
        print("📌 User ID: \(userId)")
        print("📌 Post ID: \(postId)")
        print("📌 HTTP Method: DELETE")
        print("📌 Headers: x-user-id = \(userId)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
        
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Unsave Post Error: No server response")
                throw PostsError.serverError("No server response")
            }
            
            print("📌 Unsave Post Response Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Unsave Post Error: Status \(httpResponse.statusCode) - \(message)")
                throw PostsError.serverError("Failed to unsave post: \(message)")
            }
            
            do {
                let unsavedPost = try JSONDecoder().decode(Post.self, from: data)
                print("✅ Post unsaved successfully")
                return unsavedPost
            } catch {
                print("❌ Decoding error: \(error)")
                print("Response data: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw PostsError.decodingError
            }
        } catch let urlError as URLError {
            print("❌ URL Error: \(urlError.localizedDescription)")
            print("❌ URL Error Code: \(urlError.code.rawValue)")
            if urlError.code == .cannotConnectToHost || urlError.code == .networkConnectionLost {
                throw PostsError.serverError("Cannot connect to server. Please check if the backend is running on \(PostsAPIConstants.baseURL)")
            }
            throw PostsError.serverError("Network error: \(urlError.localizedDescription)")
        } catch {
            print("❌ Unexpected error: \(error)")
            print("❌ Error type: \(type(of: error))")
            throw error
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
