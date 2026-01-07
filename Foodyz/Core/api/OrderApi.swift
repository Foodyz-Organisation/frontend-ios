import Foundation

// MARK: - Order API Service
class OrderApi {
    static let shared = OrderApi()
    private init() {}
    
    private let baseUrl = "http://127.0.0.1:3000/orders"
    
    // MARK: - Helper Method
    private func executeRequest<T: Codable>(
        url: URL,
        method: String,
        body: Encodable? = nil,
        token: String,
        responseType: T.Type,
        completion: @escaping (Result<T, APIError>) -> Void
    ) {
        Task {
            do {
                print("🌐 OrderApi Request:")
                print("   URL: \(url.absoluteString)")
                print("   Method: \(method)")
                
                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
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
                
                print("📥 OrderApi Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("   📬 Response Body:")
                    print(responseString)
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    print("✅ Successfully decoded response")
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
    
    // MARK: - POST Create Order
    // Backend returns different formats:
    // - CASH: returns OrderResponse directly
    // - CARD: returns { order: OrderResponse, clientSecret: string, paymentIntentId: string }
    func createOrder(
        body: CreateOrderRequest,
        token: String,
        completion: @escaping (Result<CreateOrderResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: baseUrl) else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "POST", body: body, token: token, responseType: CreateOrderResponse.self, completion: completion)
    }
    
    // MARK: - POST Confirm Payment
    func confirmPayment(
        body: ConfirmPaymentRequest,
        token: String,
        completion: @escaping (Result<ConfirmPaymentResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/payment/confirm") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "POST", body: body, token: token, responseType: ConfirmPaymentResponse.self, completion: completion)
    }
    
    // MARK: - GET Orders by User
    func getOrdersByUser(
        userId: String,
        token: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/user/\(userId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [OrderResponse].self, completion: completion)
    }
    
    // MARK: - GET Orders by Professional
    func getOrdersByProfessional(
        professionalId: String,
        token: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/professional/\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [OrderResponse].self, completion: completion)
    }
    
    // MARK: - GET Pending Orders
    func getPendingOrders(
        professionalId: String,
        token: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/professional/\(professionalId)/pending") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: [OrderResponse].self, completion: completion)
    }
    
    // MARK: - GET Single Order by ID
    func getOrderById(
        orderId: String,
        token: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/\(orderId)") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "GET", token: token, responseType: OrderResponse.self, completion: completion)
    }
    
    // MARK: - PATCH Update Order Status
    func updateOrderStatus(
        orderId: String,
        body: UpdateOrderStatusRequest,
        token: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/\(orderId)/status") else {
            return completion(.failure(.invalidURL))
        }
        
        executeRequest(url: url, method: "PATCH", body: body, token: token, responseType: OrderResponse.self, completion: completion)
    }
    
    // MARK: - DELETE Order
    func deleteOrder(
        orderId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/\(orderId)") else {
            return completion(.failure(.invalidURL))
        }
        
        Task {
            do {
                print("🌐 OrderApi Request:")
                print("   URL: \(url.absoluteString)")
                print("   Method: DELETE")
                
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Not an HTTP response")
                    return completion(.failure(.networkError(URLError(.unknown))))
                }
                
                print("📥 OrderApi Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ Order deleted successfully")
                    completion(.success(()))
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
    
    // MARK: - DELETE All Orders by Professional
    func deleteAllOrdersByProfessional(
        professionalId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let url = URL(string: "\(baseUrl)/professional/\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        
        Task {
            do {
                print("🌐 OrderApi Request:")
                print("   URL: \(url.absoluteString)")
                print("   Method: DELETE")
                
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Not an HTTP response")
                    return completion(.failure(.networkError(URLError(.unknown))))
                }
                
                print("📥 OrderApi Response:")
                print("   Status Code: \(httpResponse.statusCode)")
                
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ All completed orders deleted successfully")
                    completion(.success(()))
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
}
