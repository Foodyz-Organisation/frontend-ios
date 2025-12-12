import Foundation

struct CreateMenuItemDto: Codable {
    let professionalId: String
    let name: String
    let description: String? // Optional
    let price: Double
    let category: Category
    let ingredients: [IngredientDto]
    let options: [OptionDto]
}
