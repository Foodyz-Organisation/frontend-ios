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
struct CartIngredientDto: Codable, Equatable {
    let name: String
    let isDefault: Bool
    let intensityType: IntensityType?
    let intensityColor: String? // Hex color string
    let intensityValue: Double? // 0.0 to 1.0
}

// MARK: - Cart Option DTO
struct CartOptionDto: Codable, Equatable {
    let name: String
    let price: Double
}

// MARK: - Update Quantity Request
struct UpdateQuantityRequest: Codable {
    let quantity: Int
}
