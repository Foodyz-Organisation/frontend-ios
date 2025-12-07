import Foundation

struct SignupRequest: Codable {
    let username: String
    let email: String
    let password: String
    let phone: String?
    let address: String?
    let avatarUrl: String?
}


struct SignupResponse: Codable {
    let message: String
}
