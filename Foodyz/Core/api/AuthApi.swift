import Foundation

struct APIConstants {
    static var baseURL: String {
        return "\(APIConfig.baseURLString)/auth"
    }
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
    
    private let defaultSession: URLSession
    private let extendedTimeoutSession: URLSession
    
    private init() {
        // Default session configuration
        let defaultConfig = URLSessionConfiguration.default
        self.defaultSession = URLSession(configuration: defaultConfig)
        
        // Extended timeout session for OCR processing (30 seconds)
        let extendedConfig = URLSessionConfiguration.default
        extendedConfig.timeoutIntervalForRequest = 30.0 // 30 seconds for OCR processing
        extendedConfig.timeoutIntervalForResource = 60.0
        self.extendedTimeoutSession = URLSession(configuration: extendedConfig)
    }
    
    func post<T: Codable, U: Codable>(
        endpoint: String,
        body: T,
        responseType: U.Type,
        useExtendedTimeout: Bool = false
    ) async throws -> U {
        guard let url = URL(string: "\(APIConstants.baseURL)/\(endpoint)") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        // Use extended timeout session for professional signup (OCR processing)
        let session = useExtendedTimeout ? extendedTimeoutSession : defaultSession
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.serverError("No server response")
        }
        
        print("📡 Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API Error: \(message)")
            
            // Try to parse error response for better error messages
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                let errorMsg = errorResponse.reason ?? errorResponse.message ?? errorResponse.error ?? message
                throw AuthError.serverError(errorMsg)
            }
            
            throw AuthError.serverError(message)
        }
        
        do {
            return try JSONDecoder().decode(U.self, from: data)
        } catch {
            print("❌ Decoding error: \(error)")
            throw AuthError.decodingError
        }
    }
    
    // MARK: - Google Login
    func googleLogin(idToken: String) async throws -> LoginResponse {
        let request = GoogleLoginRequest(idToken: idToken)
        return try await post(
            endpoint: "google-login",
            body: request,
            responseType: LoginResponse.self
        )
    }

    // MARK: - Professional Signup (with extended timeout for OCR)
    func professionalSignup(request: ProfessionalSignupRequest) async throws -> SignupProResponse {
        return try await post(
            endpoint: "signup/professional",
            body: request,
            responseType: SignupProResponse.self,
            useExtendedTimeout: true
        )
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
        
        if httpResponse.statusCode == 404 {
            await MainActor.run { SessionManager.shared.clear() }
            return
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.serverError("Logout failed")
        }

        await MainActor.run { SessionManager.shared.clear() }
    }
}

// MARK: - Error Response Model
struct ErrorResponse: Codable {
    let statusCode: Int?
    let message: String?
    let reason: String?
    let error: String?
}
