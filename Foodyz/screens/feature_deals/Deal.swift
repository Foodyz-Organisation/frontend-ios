import Foundation

struct Deal: Codable, Identifiable {
    let _id: String
    let restaurantName: String
    let description: String
    let image: String
    let category: String
    let startDate: String
    let endDate: String
    let isActive: Bool
    let createdAt: String?
    let updatedAt: String?
    
    var id: String { _id }
    
    enum CodingKeys: String, CodingKey {
        case _id, restaurantName, description, image, category
        case startDate, endDate, isActive, createdAt, updatedAt
    }
}

struct CreateDealDto: Codable {
    let restaurantName: String
    let description: String
    let image: String
    let category: String
    let startDate: String
    let endDate: String
}

struct UpdateDealDto: Codable {
    let restaurantName: String?
    let description: String?
    let image: String?
    let category: String?
    let startDate: String?
    let endDate: String?
    let isActive: Bool?
}

struct ApiResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
}
