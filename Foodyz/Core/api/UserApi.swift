import Foundation

final class UserAPI {
    static let shared = UserAPI()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let baseURL: URL? = {
        return URL(string: "\(APIConfig.baseURLString)/users/")
    }()

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func fetchProfile(userId: String) async throws -> UserProfileDTO {
        let request = try await authorizedRequest(path: userId)
        return try await perform(request, decode: UserProfileDTO.self)
    }

    func updateProfile(userId: String, payload: UpdateUserProfileRequest) async throws -> UserProfileDTO {
        let body = try encoder.encode(payload)
        let request = try await authorizedRequest(path: userId, method: "PATCH", body: body)
        return try await perform(request, decode: UserProfileDTO.self)
    }

    // MARK: - Helpers
    private func authorizedRequest(path: String, method: String = "GET", body: Data? = nil) async throws -> URLRequest {
        guard let baseURL else { throw ChatApiError.invalidURL }
        guard let url = URL(string: path, relativeTo: baseURL) else { throw ChatApiError.invalidURL }
        let token = try await fetchAccessToken()

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = body
        return request
    }

    private func fetchAccessToken() async throws -> String {
        let token = await MainActor.run { SessionManager.shared.accessToken }
        guard let token else { throw ChatApiError.unauthenticated }
        return token
    }

    private func perform<T: Decodable>(_ request: URLRequest, decode type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ChatApiError.server("No server response")
        }

        guard (200...299).contains(http.statusCode) else {
            if let serverMessage = decodeServerMessage(from: data) {
                throw ChatApiError.server(serverMessage)
            }
            throw ChatApiError.server("Server error: \(http.statusCode)")
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ChatApiError.decoding
        }
    }

    private func decodeServerMessage(from data: Data) -> String? {
        struct ErrorResponse: Decodable { let message: String? }
        return (try? decoder.decode(ErrorResponse.self, from: data))?.message
    }
}
