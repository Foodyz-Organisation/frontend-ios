import Foundation

// MARK: - Notification API Service
class NotificationAPI {
    static let shared = NotificationAPI()
    private init() {}
    
    private let baseUrl = "http://127.0.0.1:3000/notifications"
    
    // MARK: - Helper Method
    private func executeRequest<T: Codable>(
        url: URL,
        method: String,
        body: Encodable? = nil,
        token: String? = nil,
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        Task {
            do {
                print("🔔 NotificationAPI Request:")
                print("   URL: \(url.absoluteString)")
                print("   Method: \(method)")
                
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let token = token {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                if let body = body {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    request.httpBody = try encoder.encode(body)
                    if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                        print("   📤 Request Body:")
                        print(bodyString)
                    }
                }
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Not an HTTP response")
                    return completion(.failure(.networkError(URLError(.unknown))))
                }
                
                print("📥 NotificationAPI Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   📬 Response Body:")
                    print(responseString)
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    print("✅ Successfully decoded \(T.self)")
                    completion(.success(decoded))
                case 401:
                    print("❌ Unauthorized (401)")
                    completion(.failure(.unauthorized))
                case 400:
                    print("❌ Bad Request (400)")
                    completion(.failure(.badRequest))
                default:
                    print("❌ Bad server response: \(httpResponse.statusCode)")
                    completion(.failure(.badServerResponse(statusCode: httpResponse.statusCode)))
                }
            } catch let urlError as URLError {
                print("❌ Network error: \(urlError.localizedDescription)")
                completion(.failure(.networkError(urlError)))
            } catch {
                print("❌ Unknown error: \(error)")
                completion(.failure(.decodingError(error)))
            }
        }
    }
    
    // MARK: - GET User Notifications
    func getUserNotifications(
        userId: String,
        token: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/user/\(userId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [NotificationDTO].self, completion: completion)
    }
    
    // MARK: - GET Professional Notifications
    func getProfessionalNotifications(
        professionalId: String,
        token: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/professional/\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [NotificationDTO].self, completion: completion)
    }
    
    // MARK: - GET Unread Notifications (User)
    func getUnreadUserNotifications(
        userId: String,
        token: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/unread?userId=\(userId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [NotificationDTO].self, completion: completion)
    }
    
    // MARK: - GET Unread Notifications (Professional)
    func getUnreadProfessionalNotifications(
        professionalId: String,
        token: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/unread?professionalId=\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [NotificationDTO].self, completion: completion)
    }
    
    // MARK: - PATCH Mark Notification as Read
    func markAsRead(
        notificationId: String,
        token: String,
        completion: @escaping (Result<MarkAsReadResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/\(notificationId)/read") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "PATCH", token: token, responseType: MarkAsReadResponse.self, completion: completion)
    }
    
    // MARK: - PATCH Mark All as Read (User)
    func markAllAsReadUser(
        userId: String,
        token: String,
        completion: @escaping (Result<MarkAsReadResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/read-all?userId=\(userId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "PATCH", token: token, responseType: MarkAsReadResponse.self, completion: completion)
    }
    
    // MARK: - PATCH Mark All as Read (Professional)
    func markAllAsReadProfessional(
        professionalId: String,
        token: String,
        completion: @escaping (Result<MarkAsReadResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/read-all?professionalId=\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "PATCH", token: token, responseType: MarkAsReadResponse.self, completion: completion)
    }
    
    // MARK: - DELETE Single Notification
    func deleteNotification(
        notificationId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/\(notificationId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "DELETE", token: token, responseType: EmptyResponse.self) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - DELETE All Notifications (User)
    func deleteAllUserNotifications(
        userId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)?userId=\(userId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "DELETE", token: token, responseType: EmptyResponse.self) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - DELETE All Notifications (Professional)
    func deleteAllProfessionalNotifications(
        professionalId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)?professionalId=\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "DELETE", token: token, responseType: EmptyResponse.self) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Empty Response for DELETE operations
private struct EmptyResponse: Codable {}

