import Foundation

// MARK: - Professional Document DTO
struct ProfessionalDocumentDto: Codable {
    let filename: String
    let path: String
    let verified: Bool?
    let ocrText: String?
}

// MARK: - License Validation DTO
struct LicenseValidationDto: Codable {
    let isValidated: Bool
    let validatedAt: String? // Dates are often strings in DTOs, can be parsed later
    let confidence: String? // 'high' | 'medium' | 'low'
    let extractedText: String?
    let tunisianKeywordsFound: [String]?
    let rejectionReason: String?
    let documentType: String?
}

// MARK: - Services DTO
struct ServicesDto: Codable {
    let delivery: Bool
    let takeaway: Bool
    let dineIn: Bool
}

// MARK: - Professional Data DTO
struct ProfessionalDataDto: Codable {
    let fullName: String?
    let licenseNumber: String?
    let ocrVerified: Bool?
    let documents: [String]?
    let avatarUrl: String?
}

// MARK: - Professional DTO
struct ProfessionalDto: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String? // Business name
    let licenseNumber: String?
    let licenseImageUrl: String?
    let licenseValidation: LicenseValidationDto?
    let description: String?
    let address: String?
    let phone: String?
    let hours: String?
    let services: ServicesDto?
    let imageUrl: String? // Cover image
    let documents: [String]
    let role: String?
    let isActive: Bool
    let profilePictureUrl: String? // Avatar
    let professionalData: ProfessionalDataDto?
    let resetToken: String?
    let resetTokenExpiry: String? // Date as string
    let linkedUserId: String?
    let followerCount: Int?
    let followingCount: Int?
    let locations: [LocationDto]?
    let fcmToken: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case fullName
        case licenseNumber
        case licenseImageUrl
        case licenseValidation
        case description
        case address
        case phone
        case hours
        case services
        case imageUrl
        case documents
        case role
        case isActive
        case profilePictureUrl
        case professionalData
        case resetToken
        case resetTokenExpiry
        case linkedUserId
        case followerCount
        case followingCount
        case locations
        case fcmToken
    }
    
    // Custom initializer to handle defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        licenseNumber = try container.decodeIfPresent(String.self, forKey: .licenseNumber)
        licenseImageUrl = try container.decodeIfPresent(String.self, forKey: .licenseImageUrl)
        licenseValidation = try container.decodeIfPresent(LicenseValidationDto.self, forKey: .licenseValidation)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        hours = try container.decodeIfPresent(String.self, forKey: .hours)
        services = try container.decodeIfPresent(ServicesDto.self, forKey: .services)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        documents = try container.decodeIfPresent([String].self, forKey: .documents) ?? []
        role = try container.decodeIfPresent(String.self, forKey: .role)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        profilePictureUrl = try container.decodeIfPresent(String.self, forKey: .profilePictureUrl)
        professionalData = try container.decodeIfPresent(ProfessionalDataDto.self, forKey: .professionalData)
        resetToken = try container.decodeIfPresent(String.self, forKey: .resetToken)
        resetTokenExpiry = try container.decodeIfPresent(String.self, forKey: .resetTokenExpiry)
        linkedUserId = try container.decodeIfPresent(String.self, forKey: .linkedUserId)
        followerCount = try container.decodeIfPresent(Int.self, forKey: .followerCount)
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount)
        locations = try container.decodeIfPresent([LocationDto].self, forKey: .locations)
        fcmToken = try container.decodeIfPresent(String.self, forKey: .fcmToken)
    }
    
    // Helper to get avatar URL (prioritize professionalData, then root property)
    var computedAvatarUrl: String? {
        return profilePictureUrl ?? professionalData?.avatarUrl
    }
    
    // Backward compatibility
    var avatarUrl: String? {
        return computedAvatarUrl
    }
    
    var coverUrl: String? {
        return imageUrl
    }
}

struct LocationDto: Codable {
    let id: String? // _id is auto-generated by mongo, might be missing if created fresh
    let name: String?
    let address: String?
    let lat: Double? // Made optional for safety, though schema allows require
    let lon: Double?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case address
        case lat
        case lon
    }
}

// MARK: - Search Result
struct ProfessionalSearchResult: Codable {
    let professionals: [ProfessionalDto]
    let total: Int
}
