import Foundation

// MARK: - Order Response
struct OrderResponse: Codable, Identifiable, Equatable {
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
    
    private enum UserObjectKeys: String, CodingKey {
        case _id
        case username
        case email
    }
    
    // User information when populated by backend
    var userUsername: String?
    var userEmail: String?
    
    // Custom decoder to handle userId as either String or Object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decode(String.self, forKey: ._id)
        
        // Try to decode userId as String first, if it fails, decode as object and extract _id, username, email
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            userId = userIdString
            userUsername = nil
            userEmail = nil
        } else if let userObject = try? container.nestedContainer(keyedBy: UserObjectKeys.self, forKey: .userId) {
            // Handle populated user object
            userId = (try? userObject.decode(String.self, forKey: ._id)) ?? ""
            userUsername = try? userObject.decode(String.self, forKey: .username)
            userEmail = try? userObject.decode(String.self, forKey: .email)
        } else {
            // Fallback to empty string if both fail
            userId = ""
            userUsername = nil
            userEmail = nil
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
    
    // Manual Equatable implementation to include userUsername and userEmail
    static func == (lhs: OrderResponse, rhs: OrderResponse) -> Bool {
        return lhs._id == rhs._id &&
               lhs.userId == rhs.userId &&
               lhs.professionalId == rhs.professionalId &&
               lhs.orderType == rhs.orderType &&
               lhs.status == rhs.status &&
               lhs.items == rhs.items &&
               lhs.totalPrice == rhs.totalPrice &&
               lhs.scheduledTime == rhs.scheduledTime &&
               lhs.deliveryAddress == rhs.deliveryAddress &&
               lhs.notes == rhs.notes &&
               lhs.createdAt == rhs.createdAt &&
               lhs.updatedAt == rhs.updatedAt &&
               lhs.userUsername == rhs.userUsername &&
               lhs.userEmail == rhs.userEmail
    }
    
    // Manual initializer for creating test/mock orders
    init(
        _id: String,
        userId: String,
        professionalId: String,
        orderType: OrderType,
        status: OrderStatus,
        items: [OrderItemResponse],
        totalPrice: Double,
        scheduledTime: String?,
        deliveryAddress: String?,
        notes: String?,
        createdAt: String,
        updatedAt: String,
        userUsername: String? = nil,
        userEmail: String? = nil
    ) {
        self._id = _id
        self.userId = userId
        self.professionalId = professionalId
        self.orderType = orderType
        self.status = status
        self.items = items
        self.totalPrice = totalPrice
        self.scheduledTime = scheduledTime
        self.deliveryAddress = deliveryAddress
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.userUsername = userUsername
        self.userEmail = userEmail
    }
}

// MARK: - Order Item Response
struct OrderItemResponse: Codable, Identifiable, Equatable {
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
    
    // Manual initializer for creating test/mock order items
    init(
        menuItemId: String,
        name: String,
        image: String?,
        quantity: Int,
        chosenIngredients: [ChosenIngredientResponse]?,
        chosenOptions: [ChosenOptionResponse]?,
        calculatedPrice: Double
    ) {
        self.menuItemId = menuItemId
        self.name = name
        self.image = image
        self.quantity = quantity
        self.chosenIngredients = chosenIngredients
        self.chosenOptions = chosenOptions
        self.calculatedPrice = calculatedPrice
    }
}

// MARK: - Chosen Ingredient Response
struct ChosenIngredientResponse: Codable, Equatable {
    let name: String
    let isDefault: Bool
    let intensityType: IntensityType?
    let intensityColor: String? // Hex color string
    let intensityValue: Double? // 0.0 to 1.0
    
    // Manual initializer
    init(name: String, isDefault: Bool, intensityType: IntensityType?, intensityColor: String?, intensityValue: Double?) {
        self.name = name
        self.isDefault = isDefault
        self.intensityType = intensityType
        self.intensityColor = intensityColor
        self.intensityValue = intensityValue
    }
}

// MARK: - Chosen Option Response
struct ChosenOptionResponse: Codable, Equatable {
    let name: String
    let price: Double
    
    // Manual initializer
    init(name: String, price: Double) {
        self.name = name
        self.price = price
    }
}
