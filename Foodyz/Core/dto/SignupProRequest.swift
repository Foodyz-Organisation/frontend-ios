import Foundation

struct ProfessionalSignupRequest: Codable {
    let email: String
    let password: String
    let fullName: String
    let licenseNumber: String? // Optional
    let licenseImage: String? // Base64 encoded image (matches backend API field name)
    let licenseImageUrl: String? // Keep for backward compatibility
    let linkedUserId: String?
    let locations: [LocationDto]? // Restaurant location
    
    enum CodingKeys: String, CodingKey {
        case email
        case password
        case fullName
        case licenseNumber
        case licenseImage
        case licenseImageUrl
        case linkedUserId
        case locations
    }
    
    // Custom encoding to use licenseImage if available, otherwise licenseImageUrl
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(email, forKey: .email)
        try container.encode(password, forKey: .password)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(licenseNumber, forKey: .licenseNumber)
        
        // Prefer licenseImage over licenseImageUrl
        if let licenseImage = licenseImage {
            try container.encode(licenseImage, forKey: .licenseImage)
        } else if let licenseImageUrl = licenseImageUrl {
            try container.encode(licenseImageUrl, forKey: .licenseImage)
        }
        
        try container.encodeIfPresent(linkedUserId, forKey: .linkedUserId)
        try container.encodeIfPresent(locations, forKey: .locations)
    }
}

struct SignupProResponse: Codable {
    let message: String?
    let professionalId: String?
    let permitNumber: String? // Extracted license number from OCR
    let confidence: String? // OCR confidence level (high/medium/low)
    let id: String?
    let role: String?
    let token: String?
}
