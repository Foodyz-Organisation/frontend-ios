import Foundation

struct ProfessionalSignupRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let licenseNumber: String? // Optional
}

struct SignupProResponse: Codable {
    let message: String
}
