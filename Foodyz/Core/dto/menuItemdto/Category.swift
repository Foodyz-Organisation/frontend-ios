import Foundation

/// Menu item categories matching backend enum
enum Category: String, Codable, CaseIterable {
    // Core Categories
    case burger = "BURGER"
    case pizza = "PIZZA"
    case pasta = "PASTA"
    case mexican = "MEXICAN"
    case sushi = "SUSHI"
    case asian = "ASIAN"
    case indian = "INDIAN"
    case mideast = "MIDEAST"
    case seafood = "SEAFOOD"
    case chicken = "CHICKEN"
    case sandwiches = "SANDWICHES"
    case soups = "SOUPS"
    
    // Dietary and Flavor
    case salad = "SALAD"
    case vegetarian = "VEGETARIAN"
    case vegan = "VEGAN"
    case healthy = "HEALTHY"
    case glutenFree = "GLUTEN_FREE"
    case spicy = "SPICY"
    
    // Item Type and Occasion
    case breakfast = "BREAKFAST"
    case dessert = "DESSERT"
    case drinks = "DRINKS"
    case kidsMenu = "KIDS_MENU"
    case familyMeal = "FAMILY_MEAL"
}
