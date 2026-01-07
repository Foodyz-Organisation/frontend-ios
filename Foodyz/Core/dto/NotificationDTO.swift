import Foundation

// MARK: - Notification Type Enum
enum NotificationType: String, Codable {
    // Order notifications
    case orderCreated = "ORDER_CREATED"
    case orderConfirmed = "ORDER_CONFIRMED"
    case orderCompleted = "ORDER_COMPLETED"
    case orderCancelled = "ORDER_CANCELLED"
    case orderRefused = "ORDER_REFUSED"
    case paymentSuccess = "PAYMENT_SUCCESS"
    case paymentFailed = "PAYMENT_FAILED"
    
    // Event notifications
    case eventCreated = "EVENT_CREATED"
    
    // Post notifications
    case postCreated = "POST_CREATED"
    case postLiked = "POST_LIKED"
    case postCommented = "POST_COMMENTED"
    
    // Deal notifications
    case dealCreated = "DEAL_CREATED"
    
    // Reclamation notifications
    case reclamationCreated = "RECLAMATION_CREATED"
    case reclamationUpdated = "RECLAMATION_UPDATED"
    case reclamationResponded = "RECLAMATION_RESPONDED"
    
    // Chat notifications
    case messageReceived = "MESSAGE_RECEIVED"
    case conversationStarted = "CONVERSATION_STARTED"
    
    // Custom decoder to handle both uppercase and lowercase formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Normalize: convert to uppercase to match enum cases
        let normalizedValue = rawValue.uppercased()
        
        // Try to initialize with normalized value
        if let value = NotificationType(rawValue: normalizedValue) {
            self = value
        } else {
            // Fallback: try to map common variations
            let mapping: [String: NotificationType] = [
                // Order types
                "ORDER_CREATED": .orderCreated,
                "order_created": .orderCreated,
                "ORDER_CONFIRMED": .orderConfirmed,
                "order_confirmed": .orderConfirmed,
                "ORDER_COMPLETED": .orderCompleted,
                "order_completed": .orderCompleted,
                "ORDER_CANCELLED": .orderCancelled,
                "order_cancelled": .orderCancelled,
                "ORDER_REFUSED": .orderRefused,
                "order_refused": .orderRefused,
                "PAYMENT_SUCCESS": .paymentSuccess,
                "payment_success": .paymentSuccess,
                "PAYMENT_FAILED": .paymentFailed,
                "payment_failed": .paymentFailed,
                // Event types
                "EVENT_CREATED": .eventCreated,
                "event_created": .eventCreated,
                // Post types
                "POST_CREATED": .postCreated,
                "post_created": .postCreated,
                "POST_LIKED": .postLiked,
                "post_liked": .postLiked,
                "POST_COMMENTED": .postCommented,
                "post_commented": .postCommented,
                // Deal types
                "DEAL_CREATED": .dealCreated,
                "deal_created": .dealCreated,
                // Reclamation types
                "RECLAMATION_CREATED": .reclamationCreated,
                "reclamation_created": .reclamationCreated,
                "RECLAMATION_UPDATED": .reclamationUpdated,
                "reclamation_updated": .reclamationUpdated,
                "RECLAMATION_RESPONDED": .reclamationResponded,
                "reclamation_responded": .reclamationResponded,
                // Chat types
                "MESSAGE_RECEIVED": .messageReceived,
                "message_received": .messageReceived,
                "CONVERSATION_STARTED": .conversationStarted,
                "conversation_started": .conversationStarted
            ]
            
            if let mapped = mapping[rawValue] {
                self = mapped
            } else {
                // Default fallback
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot initialize NotificationType from invalid String value '\(rawValue)'"
                )
            }
        }
    }
    
    var displayTitle: String {
        switch self {
        case .orderCreated: return "New Order Received"
        case .orderConfirmed: return "Order Confirmed"
        case .orderCompleted: return "Order Completed"
        case .orderCancelled: return "Order Cancelled"
        case .orderRefused: return "Order Refused"
        case .paymentSuccess: return "Payment Successful"
        case .paymentFailed: return "Payment Failed"
        case .eventCreated: return "New Event Available"
        case .postCreated: return "New Post"
        case .postLiked: return "Someone Liked Your Post"
        case .postCommented: return "New Comment on Your Post"
        case .dealCreated: return "New Deal Available"
        case .reclamationCreated: return "New Complaint Received"
        case .reclamationUpdated: return "Complaint Updated"
        case .reclamationResponded: return "Response to Your Complaint"
        case .messageReceived: return "New Message"
        case .conversationStarted: return "New Conversation"
        }
    }
    
    var icon: String {
        switch self {
        case .orderCreated: return "cart.badge.plus"
        case .orderConfirmed: return "checkmark.circle.fill"
        case .orderCompleted: return "checkmark.circle.fill"
        case .orderCancelled: return "xmark.circle.fill"
        case .orderRefused: return "hand.raised.fill"
        case .paymentSuccess: return "creditcard.fill"
        case .paymentFailed: return "exclamationmark.triangle.fill"
        case .eventCreated: return "calendar.badge.plus"
        case .postCreated: return "photo.on.rectangle.angled"
        case .postLiked: return "heart.fill"
        case .postCommented: return "bubble.left.fill"
        case .dealCreated: return "tag.fill"
        case .reclamationCreated: return "exclamationmark.bubble.fill"
        case .reclamationUpdated: return "arrow.triangle.2.circlepath"
        case .reclamationResponded: return "checkmark.bubble.fill"
        case .messageReceived: return "message.fill"
        case .conversationStarted: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var color: String {
        switch self {
        case .orderCreated: return "#3B82F6" // Blue
        case .orderConfirmed: return "#10B981" // Green
        case .orderCompleted: return "#10B981" // Green
        case .orderCancelled: return "#EF4444" // Red
        case .orderRefused: return "#F59E0B" // Orange
        case .paymentSuccess: return "#10B981" // Green
        case .paymentFailed: return "#EF4444" // Red
        case .eventCreated: return "#8B5CF6" // Purple
        case .postCreated: return "#3B82F6" // Blue
        case .postLiked: return "#EC4899" // Pink
        case .postCommented: return "#06B6D4" // Cyan
        case .dealCreated: return "#F59E0B" // Orange
        case .reclamationCreated: return "#EF4444" // Red
        case .reclamationUpdated: return "#F59E0B" // Orange
        case .reclamationResponded: return "#10B981" // Green
        case .messageReceived: return "#3B82F6" // Blue
        case .conversationStarted: return "#8B5CF6" // Purple
        }
    }
}

// MARK: - Notification Metadata
struct NotificationMetadata: Codable {
    // Order fields
    let orderStatus: String?
    let totalPrice: Double?
    let itemCount: Int?
    let orderType: String?
    
    // Event fields
    let eventName: String?
    let eventDate: String?
    let eventLocation: String?
    
    // Post fields
    let postCaption: String?
    let postOwnerId: String?
    let postOwnerName: String?
    
    // Deal fields
    let dealName: String?
    let restaurantName: String?
    let dealDiscount: String?
    
    // Reclamation fields
    let reclamationStatus: String?
    let reclamationType: String?
    
    // Chat fields
    let senderName: String?
    let messagePreview: String?
    let senderId: String?
    
    enum CodingKeys: String, CodingKey {
        case orderStatus, totalPrice, itemCount, orderType
        case eventName, eventDate, eventLocation
        case postCaption, postOwnerId, postOwnerName
        case dealName, restaurantName, dealDiscount
        case reclamationStatus, reclamationType
        case senderName, messagePreview, senderId
    }
}

// MARK: - Entity Info Structures

// Order Info
struct NotificationOrderInfo: Codable {
    let _id: String
    let totalPrice: Double?
    let status: String?
    let orderType: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, totalPrice, status, orderType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        totalPrice = try? container.decode(Double.self, forKey: .totalPrice)
        status = try? container.decode(String.self, forKey: .status)
        orderType = try? container.decode(String.self, forKey: .orderType)
    }
    
    init(_id: String, totalPrice: Double? = nil, status: String? = nil, orderType: String? = nil) {
        self._id = _id
        self.totalPrice = totalPrice
        self.status = status
        self.orderType = orderType
    }
}

// Event Info
struct NotificationEventInfo: Codable {
    let _id: String
    let nom: String?
    let date_debut: String?
    let lieu: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, nom, date_debut, lieu
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        nom = try? container.decode(String.self, forKey: .nom)
        date_debut = try? container.decode(String.self, forKey: .date_debut)
        lieu = try? container.decode(String.self, forKey: .lieu)
    }
    
    init(_id: String, nom: String? = nil, date_debut: String? = nil, lieu: String? = nil) {
        self._id = _id
        self.nom = nom
        self.date_debut = date_debut
        self.lieu = lieu
    }
}

// Post Info
struct NotificationPostInfo: Codable {
    let _id: String
    let caption: String?
    let ownerId: String?
    let ownerModel: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, caption, ownerId, ownerModel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        caption = try? container.decode(String.self, forKey: .caption)
        ownerId = try? container.decode(String.self, forKey: .ownerId)
        ownerModel = try? container.decode(String.self, forKey: .ownerModel)
    }
    
    init(_id: String, caption: String? = nil, ownerId: String? = nil, ownerModel: String? = nil) {
        self._id = _id
        self.caption = caption
        self.ownerId = ownerId
        self.ownerModel = ownerModel
    }
}

// Deal Info
struct NotificationDealInfo: Codable {
    let _id: String
    let nom: String?
    let description: String?
    let pourcentage_reduction: Double?
    
    enum CodingKeys: String, CodingKey {
        case _id, nom, description, pourcentage_reduction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        nom = try? container.decode(String.self, forKey: .nom)
        description = try? container.decode(String.self, forKey: .description)
        pourcentage_reduction = try? container.decode(Double.self, forKey: .pourcentage_reduction)
    }
    
    init(_id: String, nom: String? = nil, description: String? = nil, pourcentage_reduction: Double? = nil) {
        self._id = _id
        self.nom = nom
        self.description = description
        self.pourcentage_reduction = pourcentage_reduction
    }
}

// Reclamation Info
struct NotificationReclamationInfo: Codable {
    let _id: String
    let type: String?
    let status: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, type, status, description
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        type = try? container.decode(String.self, forKey: .type)
        status = try? container.decode(String.self, forKey: .status)
        description = try? container.decode(String.self, forKey: .description)
    }
    
    init(_id: String, type: String? = nil, status: String? = nil, description: String? = nil) {
        self._id = _id
        self.type = type
        self.status = status
        self.description = description
    }
}

// Message Info
struct NotificationMessageInfo: Codable {
    let _id: String
    let content: String?
    let senderId: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, content, senderId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        content = try? container.decode(String.self, forKey: .content)
        senderId = try? container.decode(String.self, forKey: .senderId)
    }
    
    init(_id: String, content: String? = nil, senderId: String? = nil) {
        self._id = _id
        self.content = content
        self.senderId = senderId
    }
}

// Conversation Info
struct NotificationConversationInfo: Codable {
    let _id: String
    let participants: [String]?
    
    enum CodingKeys: String, CodingKey {
        case _id, participants
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        participants = try? container.decode([String].self, forKey: .participants)
    }
    
    init(_id: String, participants: [String]? = nil) {
        self._id = _id
        self.participants = participants
    }
}

// MARK: - Notification Response
struct NotificationDTO: Codable, Identifiable {
    let _id: String
    let userId: String?
    let professionalId: String?
    let type: NotificationType
    let title: String
    let message: String
    
    // Entity references
    let orderId: NotificationOrderInfo?
    let eventId: NotificationEventInfo?
    let postId: NotificationPostInfo?
    let dealId: NotificationDealInfo?
    let reclamationId: NotificationReclamationInfo?
    let messageId: NotificationMessageInfo?
    let conversationId: NotificationConversationInfo?
    
    let isRead: Bool
    let metadata: NotificationMetadata?
    let createdAt: String
    let updatedAt: String
    
    var id: String {
        return _id
    }
    
    enum CodingKeys: String, CodingKey {
        case _id, userId, professionalId, type, title, message
        case orderId, eventId, postId, dealId, reclamationId, messageId, conversationId
        case isRead, metadata, createdAt, updatedAt
    }
    
    // Custom decoder to handle entity IDs as either String or Object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        userId = try? container.decode(String.self, forKey: .userId)
        professionalId = try? container.decode(String.self, forKey: .professionalId)
        type = try container.decode(NotificationType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        isRead = try container.decode(Bool.self, forKey: .isRead)
        metadata = try? container.decode(NotificationMetadata.self, forKey: .metadata)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle orderId as either String or Object
        if let orderIdString = try? container.decode(String.self, forKey: .orderId) {
            orderId = NotificationOrderInfo(_id: orderIdString)
        } else if let orderIdObject = try? container.decode(NotificationOrderInfo.self, forKey: .orderId) {
            orderId = orderIdObject
        } else {
            orderId = nil
        }
        
        // Handle eventId as either String or Object
        if let eventIdString = try? container.decode(String.self, forKey: .eventId) {
            eventId = NotificationEventInfo(_id: eventIdString)
        } else if let eventIdObject = try? container.decode(NotificationEventInfo.self, forKey: .eventId) {
            eventId = eventIdObject
        } else {
            eventId = nil
        }
        
        // Handle postId as either String or Object
        if let postIdString = try? container.decode(String.self, forKey: .postId) {
            postId = NotificationPostInfo(_id: postIdString)
        } else if let postIdObject = try? container.decode(NotificationPostInfo.self, forKey: .postId) {
            postId = postIdObject
        } else {
            postId = nil
        }
        
        // Handle dealId as either String or Object
        if let dealIdString = try? container.decode(String.self, forKey: .dealId) {
            dealId = NotificationDealInfo(_id: dealIdString)
        } else if let dealIdObject = try? container.decode(NotificationDealInfo.self, forKey: .dealId) {
            dealId = dealIdObject
        } else {
            dealId = nil
        }
        
        // Handle reclamationId as either String or Object
        if let reclamationIdString = try? container.decode(String.self, forKey: .reclamationId) {
            reclamationId = NotificationReclamationInfo(_id: reclamationIdString)
        } else if let reclamationIdObject = try? container.decode(NotificationReclamationInfo.self, forKey: .reclamationId) {
            reclamationId = reclamationIdObject
        } else {
            reclamationId = nil
        }
        
        // Handle messageId as either String or Object
        if let messageIdString = try? container.decode(String.self, forKey: .messageId) {
            messageId = NotificationMessageInfo(_id: messageIdString)
        } else if let messageIdObject = try? container.decode(NotificationMessageInfo.self, forKey: .messageId) {
            messageId = messageIdObject
        } else {
            messageId = nil
        }
        
        // Handle conversationId as either String or Object
        if let conversationIdString = try? container.decode(String.self, forKey: .conversationId) {
            conversationId = NotificationConversationInfo(_id: conversationIdString)
        } else if let conversationIdObject = try? container.decode(NotificationConversationInfo.self, forKey: .conversationId) {
            conversationId = conversationIdObject
        } else {
            conversationId = nil
        }
    }
}

// MARK: - Mark as Read Response
struct MarkAsReadResponse: Codable {
    let success: Bool
    let message: String?
}

