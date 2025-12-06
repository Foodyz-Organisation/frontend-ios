import Foundation

// MARK: - Add to Cart Request
struct AddToCartRequest: Codable {
    let menuItemId: String
    let quantity: Int
    let name: String
    let chosenIngredients: [CartIngredientDto]
    let chosenOptions: [CartOptionDto]
    let calculatedPrice: Double
}

// MARK: - Cart Ingredient DTO
struct CartIngredientDto: Codable {
    let name: String
    let isDefault: Bool
}

// MARK: - Cart Option DTO
struct CartOptionDto: Codable {
    let name: String
    let price: Double
}

// MARK: - Update Quantity Request
struct UpdateQuantityRequest: Codable {
    let quantity: Int
}
