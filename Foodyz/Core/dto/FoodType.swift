import Foundation

enum FoodType: String, Codable, CaseIterable {
    case spicy = "Spicy"
    case healthy = "Healthy"
    case mashwi = "Mashwi"
    case couscous = "Couscous"
    case streetFood = "Street food"
    case fastFood = "Fast food"
    case seafood = "Seafood"
    case fried = "Fried"
    case desserts = "Desserts"
    case vegetarianFriendly = "Vegetarian-Friendly"
    case meat = "Meat"
    
    static func getAllValues() -> [String] {
        return FoodType.allCases.map { $0.rawValue }
    }
    
    static func fromValue(_ value: String?) -> FoodType? {
        guard let value = value else { return nil }
        return FoodType.allCases.first { $0.rawValue == value }
    }
}