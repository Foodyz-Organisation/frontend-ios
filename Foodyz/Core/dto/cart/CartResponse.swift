import Foundation

// MARK: - Cart Response
struct CartResponse: Codable {
    let id: String
    let userId: String
    let items: [CartItemResponse]
    let createdAt: String?
    let updatedAt: String?
    
    // Computed properties for convenience
    var totalAmount: Double {
        items.reduce(0.0) { $0 + ($1.calculatedPrice * Double($1.quantity)) }
    }
    
    var itemCount: Int {
        items.count
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case userId
        case items
        case createdAt
        case updatedAt
    }
}

// MARK: - Cart Item Response
struct CartItemResponse: Codable, Identifiable {
    let menuItemId: String
    let quantity: Int
    let name: String
    let image: String?
    let chosenIngredients: [CartIngredientDto]
    let chosenOptions: [CartOptionDto]
    let calculatedPrice: Double
    
    // Computed property for Identifiable - use menuItemId as id
    var id: String {
        return menuItemId
    }
    
    enum CodingKeys: String, CodingKey {
        case menuItemId
        case quantity
        case name
        case image
        case chosenIngredients
        case chosenOptions
        case calculatedPrice
    }
}
