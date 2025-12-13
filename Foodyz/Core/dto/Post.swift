import Foundation

// MARK: - Media Type Enum
enum MediaType: String, Codable {
    case image = "image"
    case reel = "reel"
    case carousel = "carousel"
}

// MARK: - Owner Type Enum
enum OwnerModelType: String, Codable {
    case user = "UserAccount"
    case professional = "ProfessionalAccount"
}

// MARK: - Owner Model (Can be User or Professional)
struct Owner: Codable, Identifiable {
    let id: String
    let email: String?
    let username: String?
    let fullName: String?
    let profilePictureUrl: String?
    let followerCount: Int?
    let followingCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case username
        case fullName
        case profilePictureUrl
        case followerCount
        case followingCount
    }
    
    /// Display name - uses fullName if available, otherwise username or email
    var displayName: String {
        return fullName ?? username ?? email ?? "Unknown"
    }
}

// MARK: - Post Model
struct Post: Identifiable {
    let id: String
    let ownerId: String           // Always store the owner's ID as string
    let owner: Owner?             // Populated owner object (if available)
    let ownerModel: OwnerModelType?  // Type of owner (UserAccount or ProfessionalAccount)
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
    // NEW FIELDS
    let foodType: String?  // Optional: One of FoodType enum values
    let price: Double?     // Optional: Price in TND
    let preparationTime: Int? // Optional: Preparation time in minutes
    
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
        
        // Handle Android emulator IP (10.0.2.2) -> machine IP for real device
        let iosFriendlyUrl = url.replacingOccurrences(of: "10.0.2.2", with: "192.168.100.28")
        
        if iosFriendlyUrl.hasPrefix("http") {
            return iosFriendlyUrl
        }
        
        // Remove leading slash if present
        let cleanPath = iosFriendlyUrl.hasPrefix("/") ? String(iosFriendlyUrl.dropFirst()) : iosFriendlyUrl
        return "http://192.168.100.28:3000/\(cleanPath)"
    }
}

// MARK: - Post Codable Extension (Handles both old and new formats)
extension Post: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case ownerId        // New format: populated object
        case userId         // Old format: string ID
        case ownerModel
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
        case foodType
        case price
        case preparationTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        caption = try container.decode(String.self, forKey: .caption)
        mediaUrls = try container.decode([String].self, forKey: .mediaUrls)
        mediaType = try container.decode(MediaType.self, forKey: .mediaType)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        saveCount = try container.decodeIfPresent(Int.self, forKey: .saveCount) ?? 0
        thumbnailUrl = try container.decodeIfPresent(String.self, forKey: .thumbnailUrl)
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount) ?? 0
        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        aspectRatio = try container.decodeIfPresent(String.self, forKey: .aspectRatio)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        ownerModel = try container.decodeIfPresent(OwnerModelType.self, forKey: .ownerModel)
        foodType = try container.decodeIfPresent(String.self, forKey: .foodType)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        preparationTime = try container.decodeIfPresent(Int.self, forKey: .preparationTime)
        
        // Try to decode ownerId as populated object (new format)
        if let ownerObject = try? container.decode(Owner.self, forKey: .ownerId) {
            owner = ownerObject
            ownerId = ownerObject.id
        }
        // Try userId as string (old format - legacy posts)
        else if let userIdString = try? container.decode(String.self, forKey: .userId) {
            owner = nil
            ownerId = userIdString
        }
        // Fallback
        else {
            owner = nil
            ownerId = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(caption, forKey: .caption)
        try container.encode(mediaUrls, forKey: .mediaUrls)
        try container.encode(mediaType, forKey: .mediaType)
        try container.encode(likeCount, forKey: .likeCount)
        try container.encode(commentCount, forKey: .commentCount)
        try container.encode(saveCount, forKey: .saveCount)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encode(viewsCount, forKey: .viewsCount)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(aspectRatio, forKey: .aspectRatio)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(ownerModel, forKey: .ownerModel)
        try container.encodeIfPresent(owner, forKey: .ownerId)
        try container.encodeIfPresent(foodType, forKey: .foodType)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(preparationTime, forKey: .preparationTime)
    }
}


// MARK: - Comment Model
struct Comment: Codable, Identifiable {
    let id: String
    let post: String
    let userId: Owner?  // Populated user object
    let text: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case post
        case userId
        case text
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        post = try container.decode(String.self, forKey: .post)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        
        // Decode userId as populated object
        userId = try? container.decode(Owner.self, forKey: .userId)
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
    let foodType: String  // REQUIRED: One of FoodType enum values
    let price: Double?    // Optional: Price in TND, must be >= 0 if provided
    let preparationTime: Int? // Optional: Preparation time in minutes, must be >= 0 if provided
}

// MARK: - Upload Response
struct UploadResponse: Codable {
    let urls: [String]
}
