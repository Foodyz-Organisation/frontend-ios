import Foundation

enum ChatApiError: Error, LocalizedError {
    case invalidURL
    case unauthenticated
    case decoding
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to form chat service URL."
        case .unauthenticated:
            return "Please login to continue."
        case .decoding:
            return "Unable to decode server response."
        case .server(let message):
            return message
        }
    }
}

final class ChatAPI {
    static let shared = ChatAPI()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let baseURL = URL(string: "http://localhost:3000/chat/")

    private init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
    }

    func fetchConversations() async throws -> [ConversationDTO] {
        let request = try await authorizedRequest(path: "conversations")
        return try await perform(request, decode: [ConversationDTO].self)
    }

    func createConversation(_ requestBody: CreateConversationRequest) async throws -> ConversationDTO {
        let body = try encoder.encode(requestBody)
        let request = try await authorizedRequest(path: "conversations", method: "POST", body: body)
        return try await perform(request, decode: ConversationDTO.self)
    }

    func fetchPeers() async throws -> [ChatPeer] {
        let request = try await authorizedRequest(path: "peers")
        return try await perform(request, decode: [ChatPeer].self)
    }

    func fetchMessages(conversationId: String, limit: Int = 50, before: Date? = nil) async throws -> [MessageDTO] {
        guard var url = URL(string: "conversations/\(conversationId)/messages", relativeTo: baseURL) else {
            throw ChatApiError.invalidURL
        }

        if limit > 0 || before != nil {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            var queryItems: [URLQueryItem] = []
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            if let before = before {
                queryItems.append(URLQueryItem(name: "before", value: ISO8601DateFormatter().string(from: before)))
            }
            components?.queryItems = queryItems
            if let finalURL = components?.url {
                url = finalURL
            }
        }

        var request = try await authorizedRequest(path: "conversations/\(conversationId)/messages")
        request.url = url
        return try await perform(request, decode: [MessageDTO].self)
    }

    func sendMessage(conversationId: String, body: SendMessageRequest) async throws -> MessageDTO {
        let payload = try encoder.encode(body)
        let request = try await authorizedRequest(
            path: "conversations/\(conversationId)/messages",
            method: "POST",
            body: payload
        )
        return try await perform(request, decode: MessageDTO.self)
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
