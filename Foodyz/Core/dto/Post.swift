import Foundation

// MARK: - Media Type Enum
enum MediaType: String, Codable {
    case image = "image"
    case reel = "reel"
    case carousel = "carousel"
}

// MARK: - User Model (Populated in Post)
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let fullName: String?
    let profilePictureUrl: String?
    let followerCount: Int?
    let followingCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case fullName
        case profilePictureUrl
        case followerCount
        case followingCount
    }
}

// MARK: - Post Model
struct Post: Codable, Identifiable {
    let id: String
    let userId: User?  // Populated user object
    let caption: String
    let mediaUrls: [String]
    let mediaType: MediaType
    let likeCount: Int
    let commentCount: Int
    let saveCount: Int
    let thumbnailUrl: String?
    let viewsCount: Int
    let duration: Double?
    let aspectRatio: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case caption
        case mediaUrls
        case mediaType
        case likeCount
        case commentCount
        case saveCount
        case thumbnailUrl
        case viewsCount
        case duration
        case aspectRatio
        case createdAt
        case updatedAt
    }
    
    /// Get display URL for the post (thumbnail for videos, first media for images)
    var displayImageUrl: String? {
        if mediaType == .reel {
            return thumbnailUrl ?? mediaUrls.first
        }
        return mediaUrls.first
    }
    
    /// Check if this is a video post
    var isVideo: Bool {
        return mediaType == .reel
    }
    
    /// Get full absolute URL for display (handles relative paths and Android emulator IP)
    var fullDisplayImageUrl: String? {
        guard let url = displayImageUrl else { return nil }
        
        // Handle Android emulator IP (10.0.2.2) -> localhost for iOS
        let iosFriendlyUrl = url.replacingOccurrences(of: "10.0.2.2", with: "localhost")
        
        if iosFriendlyUrl.hasPrefix("http") {
            return iosFriendlyUrl
        }
        
        // Remove leading slash if present
        let cleanPath = iosFriendlyUrl.hasPrefix("/") ? String(iosFriendlyUrl.dropFirst()) : iosFriendlyUrl
        return "http://localhost:3000/\(cleanPath)"
    }
}


// MARK: - Comment Model
struct Comment: Codable, Identifiable {
    let id: String
    let post: String
    let text: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case post
        case text
        case createdAt
    }
}

// MARK: - Create Comment DTO
struct CreateCommentDto: Codable {
    let text: String
}

// MARK: - Create Post Request
struct CreatePostRequest: Codable {
    let caption: String
    let mediaUrls: [String]
    let mediaType: MediaType
}

// MARK: - Upload Response
struct UploadResponse: Codable {
    let urls: [String]
}
