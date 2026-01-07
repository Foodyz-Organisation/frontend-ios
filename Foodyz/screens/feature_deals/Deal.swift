import Foundation

struct Deal: Codable, Identifiable {
    let _id: String
    let professionalId: String?
    let restaurantName: String
    let description: String
    let image: String
    let category: String
    let discountPercentage: Int
    let scope: String // "ALL", "CATEGORY", "ITEMS"
    let applicableItems: [String]?
    let applicableCategory: String?
    let location: LocationDto?
    let startDate: String
    let endDate: String
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
    
    var id: String { _id }
    
    enum CodingKeys: String, CodingKey {
        case _id, professionalId, restaurantName, description, image, category
        case discountPercentage, scope, location
        case startDate, endDate, isActive, createdAt, updatedAt
        // Backend field names
        case applicableMenuItems
        case applicableCategories
        // Our field names
        case applicableItems
        case applicableCategory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        _id = try container.decode(String.self, forKey: ._id)
        professionalId = try? container.decode(String.self, forKey: .professionalId)
        restaurantName = try container.decode(String.self, forKey: .restaurantName)
        description = try container.decode(String.self, forKey: .description)
        image = try container.decode(String.self, forKey: .image)
        category = try container.decode(String.self, forKey: .category)
        discountPercentage = try container.decode(Int.self, forKey: .discountPercentage)
        
        // Handle scope - compute from data if missing
        let menuItems = try? container.decode([String].self, forKey: .applicableMenuItems)
        let categories = try? container.decode([String].self, forKey: .applicableCategories)
        let legacyItems = try? container.decode([String].self, forKey: .applicableItems)
        let legacyCategory = try? container.decode(String.self, forKey: .applicableCategory)
        
        if let scopeValue = try? container.decode(String.self, forKey: .scope) {
            scope = scopeValue
        } else {
            // Infer scope from applicableMenuItems and applicableCategories
            if let items = menuItems, !items.isEmpty {
                scope = "ITEMS"
            } else if let items = legacyItems, !items.isEmpty {
                scope = "ITEMS"
            } else if let cats = categories, !cats.isEmpty {
                scope = "CATEGORY"
            } else if legacyCategory != nil && !legacyCategory!.isEmpty {
                scope = "CATEGORY"
            } else {
                scope = "ALL"
            }
        }
        
        // Map backend fields to our fields
        if let items = menuItems {
            applicableItems = items.isEmpty ? nil : items
        } else if let items = legacyItems {
            applicableItems = items.isEmpty ? nil : items
        } else {
            applicableItems = nil
        }
        
        if let cats = categories {
            applicableCategory = cats.isEmpty ? nil : cats.joined(separator: ",")
        } else if let cat = legacyCategory {
            applicableCategory = cat.isEmpty ? nil : cat
        } else {
            applicableCategory = nil
        }
        
        location = try? container.decode(LocationDto.self, forKey: .location)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decode(String.self, forKey: .endDate)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(_id, forKey: ._id)
        try container.encodeIfPresent(professionalId, forKey: .professionalId)
        try container.encode(restaurantName, forKey: .restaurantName)
        try container.encode(description, forKey: .description)
        try container.encode(image, forKey: .image)
        try container.encode(category, forKey: .category)
        try container.encode(discountPercentage, forKey: .discountPercentage)
        try container.encode(scope, forKey: .scope)
        try container.encodeIfPresent(applicableItems, forKey: .applicableItems)
        try container.encodeIfPresent(applicableCategory, forKey: .applicableCategory)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

struct CreateDealDto: Codable {
    let restaurantName: String
    let description: String
    let image: String
    let category: String
    let discountPercentage: Int
    let scope: String
    let applicableItems: [String]?
    let applicableCategory: String?
    let location: LocationDto?
    let startDate: String
    let endDate: String
}

struct UpdateDealDto: Codable {
    let restaurantName: String?
    let description: String?
    let image: String?
    let category: String?
    let discountPercentage: Int?
    let scope: String?
    let applicableItems: [String]?
    let applicableCategory: String?
    let location: LocationDto?
    let startDate: String?
    let endDate: String?
    let isActive: Bool?
}

struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}
