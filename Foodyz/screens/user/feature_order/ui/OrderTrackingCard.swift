import SwiftUI
import MapKit
import Combine

struct OrderTrackingCard: View {
    let orderId: String
    let userId: String
    let restaurantName: String
    let restaurantLocation: CLLocationCoordinate2D?
    let professionalId: String // Add professional ID to fetch location
    let isProfessionalView: Bool // True if professional is viewing, false if user is viewing
    let frameHeight: CGFloat = 450 // Default height for the card
    
    @StateObject private var trackingService = OrderTrackingService.shared
    @StateObject private var socketManager = LocationSocketManager.shared
    @StateObject private var routeCalculator = RouteCalculator()
    
    @State private var region: MKCoordinateRegion
    @State private var distanceText: String? = nil
    @State private var distanceFormatted: String? = nil
    @State private var selectedETA: Int? = nil
    @State private var restaurantMarkerLocation: CLLocationCoordinate2D?
    @State private var userMarkerLocation: CLLocationCoordinate2D?
    @State private var restaurantAddress: String? = nil // Restaurant address from database
    @State private var professionalData: ProfessionalDto? = nil
    @State private var showFullScreenMap = false
    @State private var isConnected = false
    
    // Cancellation
    @State private var cancellables = Set<AnyCancellable>()
    
    init(orderId: String, userId: String, restaurantName: String, restaurantLocation: CLLocationCoordinate2D? = nil, professionalId: String, isProfessionalView: Bool = false) {
        self.orderId = orderId
        self.userId = userId
        self.restaurantName = restaurantName
        self.restaurantLocation = restaurantLocation
        self.professionalId = professionalId
        self.isProfessionalView = isProfessionalView
        
        let center = restaurantLocation ?? CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        _restaurantMarkerLocation = State(initialValue: restaurantLocation)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Live Location Tracking Header
            HStack {
                Text("Live Location Tracking")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Connection Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(isConnected ? "Connected" : "Disconnected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isConnected ? .green : .gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // MARK: - Map with Route
            ZStack(alignment: .top) {
                MapViewWithRoute(
                    region: $region,
                    restaurantLocation: restaurantMarkerLocation,
                    userLocation: userMarkerLocation ?? trackingService.currentLocation?.coordinate,
                    route: routeCalculator.route,
                    showsUserLocation: !isProfessionalView && userMarkerLocation == nil,
                    onMapTap: {
                        showFullScreenMap = true
                    }
                )
                .frame(height: frameHeight - 60)
                
                // Restaurant Address Card Overlay
                if let address = restaurantAddress, let distance = distanceFormatted {
                    VStack {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Restaurant")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                Text(address)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Distance")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                                Text(distance)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            
            // MARK: - Bottom Controls
            VStack(spacing: 12) {
                // Sharing Status
                if !isProfessionalView {
                    HStack {
                        if trackingService.isSharing {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Sharing your location")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                trackingService.stopSharing()
                            }) {
                                Text("Stop")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(20)
                            }
                        } else {
                            Button(action: {
                                trackingService.startSharing(orderId: orderId, userId: userId)
                            }) {
                                HStack {
                                    Image(systemName: "location.fill")
                                    Text("Share Location")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#F59E0B"))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        if let loc = restaurantMarkerLocation {
                            openMaps(lat: loc.latitude, lng: loc.longitude, name: restaurantName)
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Share Location")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#F59E0B"))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        if let loc = restaurantMarkerLocation {
                            openMaps(lat: loc.latitude, lng: loc.longitude, name: restaurantName)
                        }
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Open in Maps")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .sheet(isPresented: $showFullScreenMap) {
            if let restLoc = restaurantMarkerLocation {
                OrderNavigationScreen(
                    orderId: orderId,
                    restaurantName: restaurantName,
                    restaurantLocation: restLoc,
                    userLocation: userMarkerLocation ?? trackingService.currentLocation?.coordinate
                )
            }
        }
        .onAppear {
            // Pass correct userType based on view
            let userType = isProfessionalView ? "pro" : "user"
            trackingService.connectAndJoin(orderId: orderId, userType: userType)
            setupSubscriptions()
            fetchProfessionalData()
            
            // Request location permission and get current location
            if !isProfessionalView {
                trackingService.requestPermissions()
                
                // Get current user location if available (even if not sharing)
                // This allows showing the user's position on the map
                if let currentLocation = trackingService.currentLocation {
                    userMarkerLocation = currentLocation.coordinate
                    calculateRouteIfNeeded()
                } else {
                    // Try to get location once
                    trackingService.getCurrentLocationOnce()
                    
                    // For simulator: Set a test location near the restaurant if available
                    #if targetEnvironment(simulator)
                    if let restaurantLoc = restaurantMarkerLocation {
                        // Set user location slightly away from restaurant for testing
                        let testUserLocation = CLLocationCoordinate2D(
                            latitude: restaurantLoc.latitude + 0.01, // ~1km away
                            longitude: restaurantLoc.longitude + 0.01
                        )
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.userMarkerLocation = testUserLocation
                            self.trackingService.setTestLocation(
                                latitude: testUserLocation.latitude,
                                longitude: testUserLocation.longitude
                            )
                            self.calculateRouteIfNeeded()
                            print("📍 [Simulator] Set test user location near restaurant")
                        }
                    }
                    #endif
                }
            }
        }
    }
    
    private func fetchProfessionalData() {
        ProfessionalRepository.shared.getProfessionalById(id: professionalId) { result in
            switch result {
            case .success(let professional):
                DispatchQueue.main.async {
                    self.professionalData = professional
                    
                    // Extract first location if available
                    if let firstLocation = professional.locations?.first {
                        if let lat = firstLocation.lat, let lon = firstLocation.lon {
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            self.restaurantMarkerLocation = coordinate
                            
                            // Build full address string
                            var addressParts: [String] = []
                            if let name = firstLocation.name, !name.isEmpty {
                                addressParts.append(name)
                            }
                            if let address = firstLocation.address, !address.isEmpty {
                                addressParts.append(address)
                            }
                            
                            self.restaurantAddress = addressParts.isEmpty ? nil : addressParts.joined(separator: ", ")
                            
                            // Calculate route if user location is available
                            self.calculateRouteIfNeeded()
                            
                            // If no user location yet, center on restaurant
                            if self.userMarkerLocation == nil {
                                withAnimation {
                                    self.region.center = coordinate
                                }
                            }
                        }
                    }
                }
            case .failure(let error):
                print("❌ Failed to fetch professional data: \(error)")
            }
        }
    }
    
    private func setupSubscriptions() {
        // Connection status
        socketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { isConnected in
                self.isConnected = isConnected
            }
            .store(in: &cancellables)
        
        // Restaurant location from socket
        socketManager.restaurantLocationSubject
            .receive(on: DispatchQueue.main)
            .sink { data in
                if let lat = data["lat"] as? Double, let lng = data["lon"] as? Double {
                    self.restaurantMarkerLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    if let address = data["address"] as? String {
                        self.restaurantAddress = address
                    } else if let name = data["name"] as? String {
                        // Use name if address not available
                        self.restaurantAddress = name
                    }
                    self.updateMapRegion()
                    self.calculateRouteIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        // Location updates from socket (includes distance from backend)
        socketManager.locationUpdateSubject
            .receive(on: DispatchQueue.main)
            .sink { data in
                if let lat = data["lat"] as? Double, let lng = data["lng"] as? Double {
                    self.userMarkerLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    
                    // Use backend-calculated distance if available
                    if let distanceFormatted = data["distanceFormatted"] as? String {
                        self.distanceFormatted = distanceFormatted
                    } else if let distance = data["distance"] as? Double {
                        if distance < 1 {
                            self.distanceFormatted = String(format: "%.0f m", distance * 1000)
                        } else {
                            self.distanceFormatted = String(format: "%.2f km", distance)
                        }
                    }
                    
                    // Update restaurant location if provided in location update
                    if let restaurantLocation = data["restaurantLocation"] as? [String: Any],
                       let restLat = restaurantLocation["lat"] as? Double,
                       let restLng = restaurantLocation["lon"] as? Double {
                        self.restaurantMarkerLocation = CLLocationCoordinate2D(latitude: restLat, longitude: restLng)
                        if let restName = restaurantLocation["name"] as? String, self.restaurantAddress == nil {
                            self.restaurantAddress = restName
                        }
                    }
                    
                    self.calculateRouteIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        // Current location from tracking service (for users sharing location or just viewing)
        trackingService.$currentLocation
            .receive(on: DispatchQueue.main)
            .sink { loc in
                if let location = loc {
                    // Always update user marker location when we get location updates
                    self.userMarkerLocation = location.coordinate
                    self.calculateRouteIfNeeded()
                    self.updateMapRegionToFitBoth()
                    
                    // Calculate distance if restaurant location is known
                    if let restLoc = self.restaurantMarkerLocation {
                        let restLocation = CLLocation(latitude: restLoc.latitude, longitude: restLoc.longitude)
                        let dist = location.distance(from: restLocation)
                        if dist < 1000 {
                            self.distanceFormatted = String(format: "%.0f m", dist)
                        } else {
                            self.distanceFormatted = String(format: "%.2f km", dist / 1000)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        // Listen for route updates
        routeCalculator.$route
            .receive(on: DispatchQueue.main)
            .sink { route in
                if route != nil {
                    // Route calculated, update map region to show route
                    self.updateMapRegionToFitBoth()
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateRouteIfNeeded() {
        guard let userLoc = userMarkerLocation, let restLoc = restaurantMarkerLocation else { return }
        
        // Always recalculate route when locations are available
        // This ensures the route is updated as the user moves
        routeCalculator.calculateRoute(from: userLoc, to: restLoc)
        
        // Update map region to show both locations
        updateMapRegionToFitBoth()
    }
    
    private func updateMapRegionToFitBoth() {
        guard let userLoc = userMarkerLocation, let restLoc = restaurantMarkerLocation else { return }
        
        // Calculate region that includes both locations
        let minLat = min(userLoc.latitude, restLoc.latitude)
        let maxLat = max(userLoc.latitude, restLoc.latitude)
        let minLon = min(userLoc.longitude, restLoc.longitude)
        let maxLon = max(userLoc.longitude, restLoc.longitude)
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Add padding
        let latDelta = max((maxLat - minLat) * 1.5, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
        
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        }
    }
    
    private func updateMapRegion() {
        guard let rest = restaurantMarkerLocation else { return }
        withAnimation {
            region.center = rest
        }
    }
    
    private func openMaps(lat: Double, lng: Double, name: String) {
        // Get user's current location
        let userLoc = userMarkerLocation ?? trackingService.currentLocation?.coordinate
        
        var urlString: String
        
        if let userLocation = userLoc {
            // Include both source and destination for complete route
            // saddr = source address (user location)
            // daddr = destination address (restaurant)
            // dirflg = direction flag: d=driving, w=walking, r=transit
            urlString = "http://maps.apple.com/?saddr=\(userLocation.latitude),\(userLocation.longitude)&daddr=\(lat),\(lng)&dirflg=d"
        } else {
            // Fallback: just open destination if user location not available
            urlString = "http://maps.apple.com/?daddr=\(lat),\(lng)&dirflg=d"
        }
        
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// Local helper struct to avoid conflict if reused
struct MapItemCard: Identifiable {
    let id: Int
    let type: ItemType
    let coordinate: CLLocationCoordinate2D
    
    enum ItemType {
        case restaurant
        case user
    }
}
