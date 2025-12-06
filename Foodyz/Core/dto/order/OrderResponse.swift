import Foundation

// MARK: - Order Response
struct OrderResponse: Codable, Identifiable {
    let _id: String
    let userId: String // Will be decoded from either String or Object
    let professionalId: String
    let orderType: OrderType
    let status: OrderStatus
    let items: [OrderItemResponse]
    let totalPrice: Double
    let scheduledTime: String?
    let deliveryAddress: String?
    let notes: String?
    let createdAt: String
    let updatedAt: String
    
    var id: String {
        return _id
    }
    
    enum CodingKeys: String, CodingKey {
        case _id
        case userId
        case professionalId
        case orderType
        case status
        case items
        case totalPrice
        case scheduledTime
        case deliveryAddress
        case notes
        case createdAt
        case updatedAt
    }
    
    // Custom decoder to handle userId as either String or Object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decode(String.self, forKey: ._id)
        
        // Try to decode userId as String first, if it fails, decode as object and extract _id
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = userIdString
        } else if let userObject = try? container.decode([String: String].self, forKey: .userId),
                  let id = userObject["_id"] {
            userId = id
        } else {
            // Fallback to empty string if both fail
            userId = ""
        }
        
        professionalId = try container.decode(String.self, forKey: .professionalId)
        orderType = try container.decode(OrderType.self, forKey: .orderType)
        status = try container.decode(OrderStatus.self, forKey: .status)
        items = try container.decode([OrderItemResponse].self, forKey: .items)
        totalPrice = try container.decode(Double.self, forKey: .totalPrice)
        scheduledTime = try? container.decode(String.self, forKey: .scheduledTime)
        deliveryAddress = try? container.decode(String.self, forKey: .deliveryAddress)
        notes = try? container.decode(String.self, forKey: .notes)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
    }
}

// MARK: - Order Item Response
struct OrderItemResponse: Codable, Identifiable {
    let menuItemId: String
    let name: String
    let image: String?
    let quantity: Int
    let chosenIngredients: [ChosenIngredientResponse]?
    let chosenOptions: [ChosenOptionResponse]?
    let calculatedPrice: Double
    
    // Computed ID for Identifiable
    var id: String {
        return menuItemId
    }
    
    enum CodingKeys: String, CodingKey {
        case menuItemId
        case name
        case image
        case quantity
        case chosenIngredients
        case chosenOptions
        case calculatedPrice
    }
}

// MARK: - Chosen Ingredient Response
struct ChosenIngredientResponse: Codable {
    let name: String
    let isDefault: Bool
}

// MARK: - Chosen Option Response
struct ChosenOptionResponse: Codable {
    let name: String
    let price: Double
}
