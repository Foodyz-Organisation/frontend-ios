import Foundation

/// Menu item response matching backend schema 100%
struct MenuItemResponse: Codable, Identifiable {
    let id: String
    let professionalId: String
    let name: String
    let description: String?
    let price: Double
    let category: Category
    let ingredients: [IngredientDto] // Required, with intensity support
    let options: [OptionDto] // Required
    let image: String? // Optional, matching backend
    var preparationTimeMinutes: Int? = 15 // Default to 15 if missing

    
    // Timestamps (optional, may not always be present)
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case professionalId
        case name
        case description
        case price
        case category
        case ingredients
        case options
        case image
        case preparationTimeMinutes

        case createdAt
        case updatedAt
    }
}
