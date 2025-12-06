import Foundation

// MARK: - Professional Document DTO
struct ProfessionalDocumentDto: Codable {
    let filename: String
    let path: String
    let verified: Bool?
    let ocrText: String?
}

// MARK: - Professional DTO
struct ProfessionalDto: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String?
    let licenseNumber: String?
    let documents: [ProfessionalDocumentDto]
    let role: String?
    let isActive: Bool
    let linkedUserId: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email
        case fullName
        case licenseNumber
        case documents
        case role
        case isActive
        case linkedUserId
    }
    
    // Custom initializer to handle defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        licenseNumber = try container.decodeIfPresent(String.self, forKey: .licenseNumber)
        documents = try container.decodeIfPresent([ProfessionalDocumentDto].self, forKey: .documents) ?? []
        role = try container.decodeIfPresent(String.self, forKey: .role)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
        linkedUserId = try container.decodeIfPresent(String.self, forKey: .linkedUserId)
    }
}

// MARK: - Search Result
struct ProfessionalSearchResult: Codable {
    let professionals: [ProfessionalDto]
    let total: Int
}
