import Foundation

// MARK: - Professional API Service
class ProfessionalApi {
    static let shared = ProfessionalApi()
    private init() {}
    
    private let baseUrl = "http://127.0.0.1:3000/professionals"
    
    // MARK: - Helper Method
    private func executeRequest<T: Codable>(
        url: URL,
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion(.failure(.networkError(URLError(.unknown))))
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                case 401:
                    completion(.failure(.unauthorized))
                case 400:
                    completion(.failure(.badRequest))
                default:
                    completion(.failure(.badServerResponse(statusCode: httpResponse.statusCode)))
                }
            } catch let urlError as URLError {
                completion(.failure(.networkError(urlError)))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
    }
    
    // MARK: - GET by ID
    func getById(
        id: String,
        completion: @escaping (Result<ProfessionalDto, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/\(id)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, responseType: ProfessionalDto.self, completion: completion)
    }
    
    // MARK: - GET by Email
    func getByEmail(
        email: String,
        completion: @escaping (Result<ProfessionalDto, APIError>) -> Void
    ) {
        guard let encodedEmail = email.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseUrl)/email/\(encodedEmail)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, responseType: ProfessionalDto.self, completion: completion)
    }
    
    // MARK: - Search by Name
    func searchByName(
        name: String,
        completion: @escaping (Result<[ProfessionalDto], APIError>) -> Void
    ) {
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseUrl)/name/\(encodedName)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, responseType: [ProfessionalDto].self, completion: completion)
    }
}
