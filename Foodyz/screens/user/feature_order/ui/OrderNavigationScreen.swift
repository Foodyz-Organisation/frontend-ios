import SwiftUI
import MapKit

struct OrderNavigationScreen: View {
    @Environment(\.dismiss) var dismiss
    
    let orderId: String
    let restaurantName: String
    let restaurantLocation: CLLocationCoordinate2D?
    let userLocation: CLLocationCoordinate2D?
    
    // Services
    @StateObject private var trackingService = OrderTrackingService.shared
    
    @State private var region: MKCoordinateRegion
    @State private var distanceText: String = "-- km"
    @State private var etaText: String = "On Time"
    
    init(orderId: String, restaurantName: String, restaurantLocation: CLLocationCoordinate2D?, userLocation: CLLocationCoordinate2D?) {
        self.orderId = orderId
        self.restaurantName = restaurantName
        self.restaurantLocation = restaurantLocation
        self.userLocation = userLocation
        
        // Initialize region centering on restaurant or default
        let center = restaurantLocation ?? CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815)
        _region = State(initialValue: MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    @StateObject private var routeCalculator = RouteCalculator()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full Screen Map with Route
            MapViewWithRoute(
                region: $region,
                restaurantLocation: restaurantLocation,
                userLocation: userLocation,
                route: routeCalculator.route,
                showsUserLocation: true
            )
            .edgesIgnoringSafeArea(.all)
            
            // Top Controls
            VStack {
                HStack(alignment: .top) {
                    // Close Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Live Navigation Button
                    Button(action: {
                        if let loc = restaurantLocation {
                            openMaps(lat: loc.latitude, lng: loc.longitude, name: restaurantName)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                            Text("Live Navigation")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0xFF1F2937)) // Dark gray/black
                        .cornerRadius(24)
                        .shadow(radius: 4)
                    }
                }
                .padding(.top, 50) // Adjust for status bar
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Bottom Card
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 16) {
                        // Arrow Icon
                        Image(systemName: "arrow.up") // Or navigation arrow
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Follow route")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            // Restaurant Address/Name
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                                Text("to \(restaurantName)")
                                    .font(.system(size: 15))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    
                    Divider()
                        .padding(.bottom, 20)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(distanceText)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: 0xFF10B981)) // Green
                            Text("Distance")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(etaText)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Color(hex: 0xFF10B981)) // Green
                            Text("ETA Status")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(radius: 10)
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .statusBar(hidden: true) // Often full screen maps hide status bar or have it translucent
        .onAppear {
            // For simulator: If user location is nil, set a test location
            #if targetEnvironment(simulator)
            if userLocation == nil, let restLoc = restaurantLocation {
                // Set user location slightly away from restaurant for testing
                let testUserLocation = CLLocationCoordinate2D(
                    latitude: restLoc.latitude + 0.01, // ~1km away
                    longitude: restLoc.longitude + 0.01
                )
                trackingService.setTestLocation(
                    latitude: testUserLocation.latitude,
                    longitude: testUserLocation.longitude
                )
                // Recalculate route with test location
                routeCalculator.calculateRoute(from: testUserLocation, to: restLoc)
                updateDistance(userLoc: testUserLocation)
                print("📍 [Simulator] Set test user location for navigation screen")
            }
            #endif
            
            // Calculate route if both locations are available
            if let userLoc = userLocation ?? trackingService.currentLocation?.coordinate, 
               let restLoc = restaurantLocation {
                routeCalculator.calculateRoute(from: userLoc, to: restLoc)
            }
            
            // Sync with tracking service if needed
            if let loc = trackingService.currentLocation {
                updateDistance(userLoc: loc.coordinate)
            }
        }
        .onReceive(trackingService.$currentLocation) { loc in
            if let location = loc {
                withAnimation {
                    // Update user position on map if we were tracking it manually
                    // Update distance
                    updateDistance(userLoc: location.coordinate)
                    
                    // Recalculate route if restaurant location is known
                    if let restLoc = restaurantLocation {
                        routeCalculator.calculateRoute(from: location.coordinate, to: restLoc)
                    }
                }
            }
        }
        .onReceive(routeCalculator.$route) { route in
            if let route = route {
                // Update distance from route
                let dist = route.distance / 1000
                distanceText = String(format: "%.2f km", dist)
                
                // Update ETA
                let etaMinutes = Int(route.expectedTravelTime / 60)
                etaText = "\(etaMinutes) min"
            }
        }
    }
    
    private func updateDistance(userLoc: CLLocationCoordinate2D) {
        guard let restLoc = restaurantLocation else { return }
        
        let userLocation = CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
        let restaurantLocation = CLLocation(latitude: restLoc.latitude, longitude: restLoc.longitude)
        
        let dist = userLocation.distance(from: restaurantLocation)
        distanceText = String(format: "%.2f km", dist / 1000)
    }
    
    private func openMaps(lat: Double, lng: Double, name: String) {
        // Get user's current location
        let userLoc = userLocation ?? trackingService.currentLocation?.coordinate
        
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
