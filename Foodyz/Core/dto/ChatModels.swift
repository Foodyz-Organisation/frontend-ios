import Foundation

enum ConversationKind: String, Codable {
    case privateChat = "private"
    case group
}

enum MessageType: String, Codable {
    case text
    case image
    case file
    case sharedPost = "shared_post"
    
    // Handle unknown types gracefully by defaulting to text
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        // If the raw value doesn't match any case, default to text
        if let type = MessageType(rawValue: rawValue) {
            self = type
        } else {
            print("⚠️ Unknown message type: \(rawValue), defaulting to text")
            self = .text
        }
    }
}

struct ConversationDTO: Codable, Identifiable, Hashable {
    let id: String
    let kind: ConversationKind
    let participants: [String]
    let title: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case kind
        case participants
        case title
        case createdAt
        case updatedAt
    }

    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        return kind == .group ? "Group conversation" : "Conversation"
    }
}

struct MessageDTO: Codable, Identifiable, Hashable {
    let id: String
    let conversation: String
    let sender: String
    let content: String
    let type: MessageType
    let createdAt: Date?
    let updatedAt: Date?
    let hasBadWords: Bool?
    let moderatedContent: String?
    let isSpam: Bool?
    let spamConfidence: Double?
    let meta: MessageMeta?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversation
        case sender
        case content
        case type
        case createdAt
        case updatedAt
        case hasBadWords
        case moderatedContent
        case isSpam
        case spamConfidence
        case meta
    }
    
    /// Returns the content that should be displayed to users
    var displayContent: String {
        return moderatedContent ?? content
    }
    
    /// Returns true if this is a shared post message
    var isSharedPost: Bool {
        return type == .sharedPost || meta?.isSharedPost == true
    }
}

// MARK: - Message Meta
struct MessageMeta: Codable, Hashable {
    let sharedPostId: String?
    let sharedPostCaption: String?
    let sharedPostImage: String?
    let isSharedPost: Bool?
    let sharedBy: SharedByInfo?
    let postId: String?
    let postPrimaryImageUrl: String?
    let postCaption: String?
    let postMediaUrls: [String]?
    let postMediaType: String?
    let postFoodType: String?
    let postOwner: PostOwnerInfo?
    let price: Double?
    let preparationTime: Int?
    let likeCount: Int?
    let commentCount: Int?
    let saveCount: Int?
    let viewsCount: Int?
    let postCreatedAt: String?
    let sharedAt: String?
    
    // Make it flexible to handle any additional fields
    private enum CodingKeys: String, CodingKey {
        case sharedPostId, sharedPostCaption, sharedPostImage, isSharedPost, sharedBy
        case postId, postPrimaryImageUrl, postCaption, postMediaUrls, postMediaType
        case postFoodType, postOwner, price, preparationTime, likeCount, commentCount
        case saveCount, viewsCount, postCreatedAt, sharedAt
    }
}

struct SharedByInfo: Codable, Hashable {
    let id: String
    let name: String
    let model: String
}

struct PostOwnerInfo: Codable, Hashable {
    let id: String
    let name: String
    let avatarUrl: String?
}

struct SendMessageRequest: Codable {
    let content: String
    let type: MessageType?
    let meta: [String: String]?

    init(content: String, type: MessageType? = nil, meta: [String: String]? = nil) {
        self.content = content
        self.type = type
        self.meta = meta
    }
}

struct CreateConversationRequest: Codable {
    let kind: ConversationKind
    let participants: [String]
    let title: String?

    init(kind: ConversationKind, participants: [String], title: String? = nil) {
        self.kind = kind
        self.participants = participants
        self.title = title
    }
}

struct ChatPeer: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let role: String
    let kind: String
    let avatarUrl: String?
}
