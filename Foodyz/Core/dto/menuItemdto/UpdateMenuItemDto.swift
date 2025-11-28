import Foundation

struct UpdateMenuItemDto: Codable {  // Codable = Encodable + Decodable
    let name: String?
    let description: String?
    let price: Double?
    let category: Category?   // optional
    let ingredients: [IngredientDto]?
    let options: [OptionDto]?
}
