import Foundation

struct APIConstants {
    static let baseURL = "http://192.168.100.28:3000/auth"
}

enum AuthError: Error, LocalizedError {
    case invalidURL
    case decodingError
    case serverError(String)
    case unknownError // Added for safety

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The API address is invalid. Check the base URL."
        case .decodingError:
            return "The server response format was unexpected. Please contact support."
        case .serverError(let message):
            return "Server Error: \(message)"
        case .unknownError:
            return "An unexpected error occurred during the request."
        }
    }
}

class AuthAPI {
    static let shared = AuthAPI()
    
    private init() {}
    
    func post<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        responseType: U.Type
    ) async throws -> U {
        guard let url = URL(string: "\(APIConstants.baseURL)/\(endpoint)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError.serverError(message)
        }
        
        do {
            return try JSONDecoder().decode(U.self, from: data)
        } catch {
            throw AuthError.decodingError
        }
    }

    // MARK: - Logout
    func logout() async throws {
        guard let url = URL(string: "\(APIConstants.baseURL)/logout") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.serverError("No server response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.serverError("Logout failed")
        }
    }
}
