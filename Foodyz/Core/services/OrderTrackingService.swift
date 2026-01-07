import Foundation
import CoreLocation
import Combine

class OrderTrackingService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = OrderTrackingService()
    
    private let locationManager = CLLocationManager()
    private let socket = LocationSocketManager.shared
    
    @Published var currentLocation: CLLocation?
    @Published var isSharing = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // Tracking State
    private var currentOrderId: String?
    private var currentUserId: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    override private init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 10 // Update every 10 meters
        // Note: Background location updates removed - requires Background Modes capability
        // For foreground-only tracking (when app is open), this is sufficient
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // Get current location once (without starting continuous updates)
    func getCurrentLocationOnce() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else {
            // Request permission first
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // Request location once
        locationManager.requestLocation()
        
        // For simulator: If location is still nil after a delay, set a test location
        #if targetEnvironment(simulator)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.currentLocation == nil {
                // Set a test location in Tunis, Tunisia (near the restaurant area)
                let testLocation = CLLocation(
                    latitude: 36.8065,
                    longitude: 10.1815
                )
                self?.currentLocation = testLocation
                print("📍 [Simulator] Using test location: Tunis, Tunisia (36.8065, 10.1815)")
            }
        }
        #endif
    }
    
    // Set a test location (useful for simulator testing)
    func setTestLocation(latitude: Double, longitude: Double) {
        let testLocation = CLLocation(latitude: latitude, longitude: longitude)
        self.currentLocation = testLocation
        print("📍 [Test] Location set to: \(latitude), \(longitude)")
    }
    
    // MARK: - Connect & Join
    func connectAndJoin(orderId: String, userType: String? = nil) {
        socket.connect()
        
        // Auto-detect user type if not provided
        let detectedUserType: String
        if let providedType = userType {
            detectedUserType = providedType
        } else {
            // Detect from TokenManager
            let role = TokenManager.shared.getUserRole() ?? ""
            detectedUserType = (role.lowercased() == "professional") ? "pro" : "user"
        }
        
        // Wait for connection potentially, or just emit (SocketIO client often buffers)
        // But better to listen to connect event.
        socket.$isConnected
            .filter { $0 }
            .first()
            .sink { [weak self] _ in
                print("✅ Connected to Location Socket")
                self?.socket.joinOrder(orderId: orderId, userType: detectedUserType)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sharing Logic
    func startSharing(orderId: String, userId: String) {
        self.currentOrderId = orderId
        self.currentUserId = userId
        
        // request permission if needed
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.startUpdatingLocation()
        socket.startSharing(orderId: orderId, userId: userId)
        isSharing = true
    }
    
    func stopSharing() {
        guard let orderId = currentOrderId, let userId = currentUserId else { return }
        
        locationManager.stopUpdatingLocation()
        socket.stopSharing(orderId: orderId, userId: userId)
        
        isSharing = false
        currentOrderId = nil
        currentUserId = nil
    }
    
    func setETA(minutes: Int) {
        guard let orderId = currentOrderId, let userId = currentUserId else { return }
        socket.setETA(orderId: orderId, userId: userId, minutes: minutes)
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentLocation = location
        
        // If sharing, emit to socket
        if isSharing, let orderId = currentOrderId, let userId = currentUserId {
            socket.sendLocationUpdate(
                orderId: orderId,
                userId: userId,
                coordinate: location.coordinate,
                accuracy: location.horizontalAccuracy
            )
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        
        // If permission granted, get location once to show on map
        if manager.authorizationStatus == .authorizedWhenInUse || 
           manager.authorizationStatus == .authorizedAlways {
            // Request location once to show on map (even if not sharing)
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location Manager Error: \(error.localizedDescription)")
    }
}
