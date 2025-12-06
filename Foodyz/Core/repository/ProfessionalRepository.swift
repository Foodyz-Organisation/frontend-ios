import Foundation

// MARK: - Professional Repository
class ProfessionalRepository {
    static let shared = ProfessionalRepository()
    private let api = ProfessionalApi.shared
    
    private init() {}
    
    // MARK: - Get Professional by ID
    func getProfessionalById(
        id: String,
        completion: @escaping (Result<ProfessionalDto, APIError>) -> Void
    ) {
        api.getById(id: id, completion: completion)
    }
    
    // MARK: - Get Professional by Email
    func getProfessionalByEmail(
        email: String,
        completion: @escaping (Result<ProfessionalDto, APIError>) -> Void
    ) {
        api.getByEmail(email: email, completion: completion)
    }
    
    // MARK: - Search Professionals by Name
    func searchProfessionals(
        name: String,
        completion: @escaping (Result<[ProfessionalDto], APIError>) -> Void
    ) {
        api.searchByName(name: name, completion: completion)
    }
}
