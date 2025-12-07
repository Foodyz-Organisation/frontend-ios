import Foundation

struct UserProfileDTO: Codable {
    let id: String
    let username: String
    let email: String
    let phone: String?
    let address: String?
    let avatarUrl: String?
    let role: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case username
        case email
        case phone
        case address
        case avatarUrl
        case role
    }
}

struct UpdateUserProfileRequest: Codable {
    let username: String?
    let phone: String?
    let address: String?
    let avatarUrl: String?
}
