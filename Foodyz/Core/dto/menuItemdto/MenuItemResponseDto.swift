import Foundation

struct MenuItemResponse: Codable, Identifiable {
    let id: String
    let professionalId: String
    let name: String
    let description: String?
    let price: Double
    let category: Category
    let ingredients: [IngredientDto]
    let options: [OptionDto]
    let image: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case professionalId, name, description, price, category, ingredients, options, image, createdAt, updatedAt
    }
}
