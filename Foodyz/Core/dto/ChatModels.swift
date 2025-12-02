import Foundation

enum ConversationKind: String, Codable {
    case privateChat = "private"
    case group
}

enum MessageType: String, Codable {
    case text
    case image
    case file
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

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case conversation
        case sender
        case content
        case type
        case createdAt
        case updatedAt
    }
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
