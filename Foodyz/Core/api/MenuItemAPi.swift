// MenuItemApi.swift

import Foundation
import UIKit // For UIImage handling


// Assume APIError is a defined enum matching the Repository's signature
enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case unauthorized // 401
    case badRequest // 400
    case badServerResponse(statusCode: Int)
    case decodingError(Error)
    case noData
}
// APIError.swift (Corrected extension)

extension APIError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The server URL is configured incorrectly."
        case .networkError(let error):
            return "Connection Failed: \(error.localizedDescription)"
        case .unauthorized:
            return "Access Denied. Please log in again."
        
        // ⭐️ ADD THE MISSING CASE HERE ⭐️
        case .badRequest:
            return "The request sent to the server was invalid (Error 400)."
            
        case .badServerResponse(let statusCode):
            return "Server Error: Status code \(statusCode)."
        case .decodingError:
            return "Failed to read data from the server."
        case .noData:
            return "The server returned no data."
        }
    }
}

// Global shared instance is common for API clients
class MenuItemApi {
    static let shared = MenuItemApi()
    private init() {}
    
    // Change to your IP if running on device
    private let baseUrl = "http://127.0.0.1:3000"
    
    // Helper function to handle response and bridge async/await to callback
    private func handleAsyncCall<T: Decodable>(url: URL, request: URLRequest? = nil, completion: @escaping (Result<T, APIError>) -> Void) {
        Task {
            do {
                var finalRequest = request ?? URLRequest(url: url)
                if finalRequest.url == nil { finalRequest.url = url }

                let (data, response) = try await URLSession.shared.data(for: finalRequest)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return completion(.failure(.networkError(URLError(.unknown))))
                }
                
                // Handle non-success status codes
                switch httpResponse.statusCode {
                case 200...299:
                    // Proceed to decoding
                    break
                case 401:
                    return completion(.failure(.unauthorized))
                case 400:
                    return completion(.failure(.badRequest))
                default:
                    return completion(.failure(.badServerResponse(statusCode: httpResponse.statusCode)))
                }
                
                guard !data.isEmpty else {
                    // For DELETE/POST that returns no body, but still success, we might return a default success object
                    // For now, treat no data as an error if T is expected.
                    if T.self == MenuItemResponse.self {
                        return completion(.success(data as! T)) // WARNING: This is a hack for generic success, real fix needed.
                    }
                    return completion(.failure(.noData))
                }
                
                // Decode successful response
                let decoded = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decoded))
            } catch let urlError as URLError {
                completion(.failure(.networkError(urlError)))
            } catch let apiError as APIError {
                completion(.failure(apiError))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }
    }
    
    // --- Public methods using the original callback signature ---
    
    // MARK: - GET All (Grouped)
    func getGroupedMenu(professionalId: String, token: String, completion: @escaping (Result<[String: [MenuItemResponse]], APIError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/menu-items/by-professional/\(professionalId)") else {
            return completion(.failure(.invalidURL))
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        handleAsyncCall(url: url, request: request, completion: completion)
    }

    // MARK: - GET Details
    func getMenuItemDetails(id: String, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/menu-items/\(id)") else {
            return completion(.failure(.invalidURL))
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        handleAsyncCall(url: url, request: request, completion: completion)
    }

    // MARK: - POST (Create)
    func createMenuItem(payload: CreateMenuItemDto, image: UIImage?, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/menu-items") else {
            return completion(.failure(.invalidURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // --- Multipart Form Data Body Construction ---
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 1. Add JSON Payload
        // Note: Payload type needs to be CreateMenuItemDto or compatible with the CreateItem DTO used internally.
        if let jsonData = try? JSONEncoder().encode(payload),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            // Match the backend field name (e.g., 'createMenuItemDto')
            body.append("Content-Disposition: form-data; name=\"createMenuItemDto\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(jsonString)\r\n".data(using: .utf8)!)
        }
        
        // 2. Add Image File
        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        // --- End of Multipart Body ---
        
        handleAsyncCall(url: url, request: request, completion: completion)
    }

    // MARK: - PUT (Update)
    func updateMenuItem(id: String, payload: UpdateMenuItemDto, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/menu-items/\(id)") else {
            return completion(.failure(.invalidURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Assuming update payload is simple JSON
        request.httpBody = try? JSONEncoder().encode(payload)
        
        handleAsyncCall(url: url, request: request, completion: completion)
    }

    // MARK: - DELETE
    func deleteMenuItem(id: String, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        guard let url = URL(string: "\(baseUrl)/menu-items/\(id)") else {
            return completion(.failure(.invalidURL))
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        handleAsyncCall(url: url, request: request, completion: completion)
    }
}
