import Foundation
import SocketIO
import Combine
import CoreLocation

// MARK: - LocationSocketManager
class LocationSocketManager: ObservableObject {
    static let shared = LocationSocketManager()
    
    // Independent Socket Manager
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    @Published var isConnected = false
    
    // Observables
    let restaurantLocationSubject = PassthroughSubject<[String: Any], Never>()
    let locationUpdateSubject = PassthroughSubject<[String: Any], Never>()
    let sharingStartedSubject = PassthroughSubject<Void, Never>()
    let sharingStoppedSubject = PassthroughSubject<Void, Never>()
    let etaUpdateSubject = PassthroughSubject<[String: Any], Never>()
    let errorSubject = PassthroughSubject<String, Never>()
    let userJoinedSubject = PassthroughSubject<[String: Any], Never>()
    
    private init() {}
    
    // Connect to the specific namespace/endpoint for order tracking
    func connect() {
        disconnect()
        
        let baseURLString = APIConfig.baseURLString + "/order-tracking" 
        // Note: Socket.IO client usually connects to base URL. 
        // If the backend uses namespaces, we connect to base then use .socket(forNamespace: "/order-tracking")
        // Based on the React Code provided: io('http://YOUR_BACKEND_URL/order-tracking')
        // This implies a namespace or separate path. Swift SocketIO usually configures path in config if needed.
        // Assuming standard namespace usage:
        
        guard let url = URL(string: APIConfig.baseURLString) else { return }
        
        let config: SocketIOClientConfiguration = [
            .log(true),
            .compress,
            .reconnects(true),
            .reconnectAttempts(-1),
            .reconnectWait(1),
            .path("/socket.io"), // Standard Socket.IO path
             // If React uses io('.../order-tracking'), it might mean the NAMESPACE is /order-tracking
             // Using .nsp("/order-tracking") in config doesn't exist, we select socket for nsp.
        ]
        
        manager = SocketManager(socketURL: url, config: config)
        
        // Connect to the specific namespace
        socket = manager?.socket(forNamespace: "/order-tracking") 
        
        setupHandlers()
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
        socket?.removeAllHandlers()
        socket = nil
        manager = nil
        isConnected = false
    }
    
    private func setupHandlers() {
        guard let socket = socket else { return }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            print("📍 Location Socket Connected")
            DispatchQueue.main.async { self?.isConnected = true }
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            print("📍 Location Socket Disconnected")
            DispatchQueue.main.async { self?.isConnected = false }
        }
        
        // Listeners
        socket.on("restaurant-location") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                print("📍 Received restaurant-location: \(dict)")
                self?.restaurantLocationSubject.send(dict)
            }
        }
        
        socket.on("location-update") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                print("📍 Received location-update: userId=\(dict["userId"] ?? "unknown"), distance=\(dict["distanceFormatted"] ?? "N/A")")
                self?.locationUpdateSubject.send(dict)
            }
        }
        
        socket.on("sharing-started") { [weak self] _, _ in
            self?.sharingStartedSubject.send()
        }
        
        socket.on("sharing-stopped") { [weak self] _, _ in
            self?.sharingStoppedSubject.send()
        }
        
        socket.on("eta-update") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                self?.etaUpdateSubject.send(dict)
            }
        }
        
        // Error handler
        socket.on("error") { [weak self] data, _ in
            if let dict = data.first as? [String: Any],
               let message = dict["message"] as? String {
                print("❌ Socket Error: \(message)")
                self?.errorSubject.send(message)
            }
        }
        
        // User joined handler (for logging/debugging)
        socket.on("user-joined") { [weak self] data, _ in
            if let dict = data.first as? [String: Any] {
                print("👤 User joined: \(dict)")
                self?.userJoinedSubject.send(dict)
            }
        }
    }
    
    // MARK: - Emitters
    
    func joinOrder(orderId: String, userType: String) {
        // Ensure userType is "user" or "pro" as expected by backend
        let normalizedUserType = (userType.lowercased() == "professional" || userType.lowercased() == "pro") ? "pro" : "user"
        
        let payload: [String: Any] = [
            "orderId": orderId,
            "userType": normalizedUserType
        ]
        print("📍 Joining order \(orderId) as \(normalizedUserType)")
        socket?.emit("join-order", payload)
    }
    
    func startSharing(orderId: String, userId: String) {
        let payload: [String: Any] = [
            "orderId": orderId,
            "userId": userId
        ]
        socket?.emit("start-sharing", payload)
    }
    
    func stopSharing(orderId: String, userId: String) {
        let payload: [String: Any] = [
            "orderId": orderId,
            "userId": userId
        ]
        socket?.emit("stop-sharing", payload)
    }
    
    func sendLocationUpdate(orderId: String, userId: String, coordinate: CLLocationCoordinate2D, accuracy: Double) {
        let payload: [String: Any] = [
            "orderId": orderId,
            "userId": userId,
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "accuracy": accuracy
        ]
        socket?.emit("location-update", payload)
    }
    
    func setETA(orderId: String, userId: String, minutes: Int) {
        let payload: [String: Any] = [
            "orderId": orderId,
            "userId": userId,
            "estimatedMinutes": minutes
        ]
        socket?.emit("set-eta", payload)
    }
}
