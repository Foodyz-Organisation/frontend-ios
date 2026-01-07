import Foundation

// MARK: - Payment Method Enum
enum PaymentMethod: String, Codable {
    case cash = "CASH"
    case card = "CARD"
}

// MARK: - Create Order Request
struct CreateOrderRequest: Codable {
    let userId: String
    let professionalId: String
    let orderType: OrderType
    let scheduledTime: String?
    let items: [OrderItemRequest]
    let totalPrice: Double
    let deliveryAddress: String?
    let notes: String?
    let paymentMethod: PaymentMethod // Required: CASH or CARD
}

// MARK: - Order Item Request
struct OrderItemRequest: Codable {
    let menuItemId: String
    let name: String
    let quantity: Int
    let chosenIngredients: [ChosenIngredientRequest]?
    let chosenOptions: [ChosenOptionRequest]?
    let calculatedPrice: Double
}

// MARK: - Chosen Ingredient Request
struct ChosenIngredientRequest: Codable {
    let name: String
    let isDefault: Bool
    let intensityType: IntensityType?
    let intensityColor: String? // Hex color string
    let intensityValue: Double? // 0.0 to 1.0
}

// MARK: - Chosen Option Request
struct ChosenOptionRequest: Codable {
    let name: String
    let price: Double
}

// MARK: - Update Order Status Request
struct UpdateOrderStatusRequest: Codable {
    let status: OrderStatus
}
