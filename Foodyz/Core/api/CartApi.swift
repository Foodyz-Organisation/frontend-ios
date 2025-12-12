import Foundation

// MARK: - Cart API Service
class CartApi {
    static let shared = CartApi()
    private init() {}
    
    private let baseUrl = "http://127.0.0.1:3000/cart"
    
    // MARK: - Helper Method
    private func executeRequest<T: Codable>(
        url: URL,
        method: String,
        body: Encodable? = nil,
        token: String,
        userId: String,
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        Task {
            do {
                print("🌐 CartApi Request:")
                print("   URL: \(url.absoluteString)")
                print("   Method: \(method)")
                print("   UserId: \(userId)")
                
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let body = body {
                    request.httpBody = try JSONEncoder().encode(body)
                    if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
                        print("   Body: \(bodyString)")
                    }
                }
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Not an HTTP response")
                    return completion(.failure(.networkError(URLError(.unknown))))
                }
                
                print("📥 CartApi Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   Raw Response: \(responseString)")
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decoded = try JSONDecoder().decode(T.self, from: data)
                        print("✅ Successfully decoded response")
                        completion(.success(decoded))
                    } catch {
                        print("❌ Decoding error: \(error)")
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                print("   Missing key: \(key.stringValue) - \(context.debugDescription)")
                            case .typeMismatch(let type, let context):
                                print("   Type mismatch: expected \(type) - \(context.debugDescription)")
                            case .valueNotFound(let type, let context):
                                print("   Value not found: \(type) - \(context.debugDescription)")
                            case .dataCorrupted(let context):
                                print("   Data corrupted: \(context.debugDescription)")
                            @unknown default:
                                print("   Unknown decoding error")
                            }
                        }
                        completion(.failure(.decodingError(error)))
                    }
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
    
    // MARK: - GET User Cart
    func getUserCart(
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: baseUrl) else {
            return completion(.failure(.invalidURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
        
        guard let url = urlComponents.url else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, userId: userId, responseType: CartResponse.self, completion: completion)
    }
    
    // MARK: - POST Add Item to Cart
    func addItemToCart(
        request: AddToCartRequest,
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: "\(baseUrl)/add") else {
            return completion(.failure(.invalidURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
        
        guard let url = urlComponents.url else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "POST", body: request, token: token, userId: userId, responseType: CartResponse.self, completion: completion)
    }
    
    // MARK: - PATCH Update Item Quantity
    func updateItemQuantity(
        itemIndex: Int,
        request: UpdateQuantityRequest,
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: "\(baseUrl)/update/\(itemIndex)") else {
            return completion(.failure(.invalidURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
        
        guard let url = urlComponents.url else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "PATCH", body: request, token: token, userId: userId, responseType: CartResponse.self, completion: completion)
    }
    
    // MARK: - DELETE Remove Item
    func removeItem(
        itemIndex: Int,
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: "\(baseUrl)/remove/\(itemIndex)") else {
            return completion(.failure(.invalidURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
        
        guard let url = urlComponents.url else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "DELETE", token: token, userId: userId, responseType: CartResponse.self, completion: completion)
    }
    
    // MARK: - DELETE Clear Cart
    func clearCart(
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: "\(baseUrl)/clear") else {
            return completion(.failure(.invalidURL))
        }
        urlComponents.queryItems = [URLQueryItem(name: "userId", value: userId)]
        
        guard let url = urlComponents.url else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "DELETE", token: token, userId: userId, responseType: CartResponse.self, completion: completion)
    }
}
