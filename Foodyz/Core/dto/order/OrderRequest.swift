import Foundation

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
