import SwiftUI
import MapKit
import Combine

// MARK: - UserOrderTrackingScreen
struct UserOrderTrackingScreen: View {
    let orderId: String
    let userId: String
    let restaurantName: String
    let restaurantLocation: CLLocationCoordinate2D? // Initial restaurant location
    
    @StateObject private var trackingService = OrderTrackingService.shared
    @StateObject private var socketManager = LocationSocketManager.shared
    
    // UI State
    @State private var region: MKCoordinateRegion
    @State private var distanceText: String? = nil
    @State private var selectedETA: Int? = nil
    
    // Markers could be simpler in SwiftUI Map but explicit state helps
    @State private var restaurantMarkerLocation: CLLocationCoordinate2D?
    @State private var userMarkerLocation: CLLocationCoordinate2D?
    
    init(orderId: String, userId: String, restaurantName: String, restaurantLocation: CLLocationCoordinate2D? = nil) {
        self.orderId = orderId
        self.userId = userId
        self.restaurantName = restaurantName
        self.restaurantLocation = restaurantLocation
        
        // Default region: Tunis (from user context) or restaurant or user location
        let center = restaurantLocation ?? CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
        _restaurantMarkerLocation = State(initialValue: restaurantLocation)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Map View
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: getAnnotations()) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    if item.type == .restaurant {
                        VStack(spacing: 4) {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.orange)
                                .background(Circle().fill(Color.white))
                            Text(restaurantName)
                                .font(.caption)
                                .padding(4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    } else {
                        // User marker (Custom implementation if showsUserLocation isn't enough or for shadow)
                        // But standard showsUserLocation is better for "me"
                        EmptyView() 
                    }
                }
            }
            .ignoresSafeArea(edges: .top) // Fill screen
            
            // MARK: - Controls Details Sheet
            VStack(spacing: 20) {
                // Drag handle
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                // Status Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Live Tracking")
                            .font(.headline)
                        if let distance = distanceText {
                            Text("Distance: \(distance)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                    // Status Badge
                    if trackingService.isSharing {
                        Text("SHARING LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                 Divider()
                
                // Location Controls
                if !trackingService.isSharing {
                    Button(action: {
                        trackingService.startSharing(orderId: orderId, userId: userId)
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Start Sharing Location")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#F59E0B")) // Primary Color
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Button(action: {
                        trackingService.stopSharing()
                    }) {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Sharing")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // ETA Selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estimated Arrival Time")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach([5, 10, 15, 20, 30], id: \.self) { minutes in
                                Button(action: {
                                    selectedETA = minutes
                                    trackingService.setETA(minutes: minutes)
                                }) {
                                    Text("\(minutes) min")
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedETA == minutes ? Color(hex: "#F59E0B") : Color.gray.opacity(0.1))
                                        .foregroundColor(selectedETA == minutes ? .white : .black)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .disabled(!trackingService.isSharing)
                .opacity(trackingService.isSharing ? 1 : 0.5)
                
                // Restaurant Info
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    VStack(alignment: .leading) {
                        Text(restaurantName)
                            .fontWeight(.medium)
                        Text("Restaurant Location")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        // Open Apple Maps
                        if let loc = restaurantMarkerLocation {
                             openMaps(lat: loc.latitude, lng: loc.longitude, name: restaurantName)
                        }
                    }) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#F59E0B"))
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer().frame(height: 20)
            }
            .background(Color.white)
            .cornerRadius(24, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        }
        .onAppear {
            trackingService.connectAndJoin(orderId: orderId)
            
            // Listen for restaurant location update from socket if not initially provided
            socketManager.restaurantLocationSubject
                .receive(on: DispatchQueue.main)
                .sink { data in
                    if let lat = data["lat"] as? Double, let lng = data["lon"] as? Double {
                         restaurantMarkerLocation = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                         // Center map to include restaurant
                         updateMapRegion()
                    }
                }
                .store(in: &cancellables)
            
            // Listen to current location to update data
             trackingService.$currentLocation
                .sink { loc in
                    if let location = loc {
                        userMarkerLocation = location.coordinate
                        // Calculate distance if restaurant known
                        if let restLoc = restaurantMarkerLocation {
                            let restLocation = CLLocation(latitude: restLoc.latitude, longitude: restLoc.longitude)
                            let dist = location.distance(from: restLocation)
                            distanceText = String(format: "%.2f km", dist / 1000)
                        }
                    }
                }
                .store(in: &cancellables)
        }
        .onDisappear {
            // Optional: Auto stop sharing? Or leave it running?
            // Usually valid to stop when leaving screen unless background service intent
            if trackingService.isSharing {
                // trackingService.stopSharing() // User might want to background it
            }
        }
    }
    
    // Internal state handling
    @State private var cancellables = Set<AnyCancellable>()
    
    private func updateMapRegion() {
        guard let rest = restaurantMarkerLocation else { return }
        // Simple centering logic
        withAnimation {
            region.center = rest
        }
    }
    
    private func getAnnotations() -> [MapItem] {
        var items: [MapItem] = []
        if let rest = restaurantMarkerLocation {
            items.append(MapItem(id: 1, type: .restaurant, coordinate: rest))
        }
        return items
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

// Helper Structures
struct MapItem: Identifiable {
    let id: Int
    let type: ItemType
    let coordinate: CLLocationCoordinate2D
    
    enum ItemType {
        case restaurant
        case user
    }
}

// Extend View for specific corner radius (Already provided in PostsScreen?)
// If redundant, we rely on existing. If not, we add. 
// PostsScreen defined it as extension View. If it's private or Fileprivate?
// PostsScreen extension was public/internal.
// If it was defined in PostsScreen.swift OUTSIDE the struct, it's global internal.
// Checking PostsScreen.swift content... 
// It was: extension View { func cornerRadius(...) } lines 460-464.
// So it is available.
