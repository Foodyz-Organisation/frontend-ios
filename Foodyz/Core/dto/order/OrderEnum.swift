import Foundation

// MARK: - Order Status Enum
enum OrderStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case completed = "completed"
    case cancelled = "cancelled"
    case refused = "refused"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .refused: return "Refused"
        }
    }
    
    var color: Int {
        switch self {
        case .completed: return 0x10B981 // Green
        case .cancelled, .refused: return 0xEF4444 // Red
        case .pending: return 0xF59E0B // Orange
        case .confirmed: return 0x3B82F6 // Blue
        }
    }
}

// MARK: - Order Type Enum
enum OrderType: String, Codable {
    case eatIn = "eat-in"
    case takeaway = "takeaway"
    case delivery = "delivery"
    
    var displayName: String {
        switch self {
        case .eatIn: return "Dine-in"
        case .takeaway: return "Takeaway"
        case .delivery: return "Delivery"
        }
    }
    
    var emoji: String {
        switch self {
        case .eatIn: return "🍽️"
        case .takeaway: return "🛍️"
        case .delivery: return "🚚"
        }
    }
    
    var color: Int {
        switch self {
        case .delivery: return 0x8B5CF6 // Purple
        case .takeaway: return 0x10B981 // Green
        case .eatIn: return 0x3B82F6 // Blue
        }
    }
}
