import SwiftUI
import MapKit
import Combine

// MARK: - All Users Tracking Screen
struct AllUsersTrackingScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var socketManager = LocationSocketManager.shared
    @StateObject private var trackingService = OrderTrackingService.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815), // Tunis, Tunisia
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var userLocations: [String: CLLocationCoordinate2D] = [:]
    @State private var isConnected = false
    @State private var isLoading = true
    
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // Full Screen Map
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: getAnnotations()) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                            .background(Circle().fill(Color.white))
                        Text(item.userName)
                            .font(.caption)
                            .padding(4)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(4)
                    }
                }
            }
            .ignoresSafeArea(.all)
            
            // Top Header
            VStack {
                HStack {
                    // Back Button
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Title
                    Text("All Users Tracking")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Connection Status
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(isConnected ? "Connected" : "Disconnected")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Info Card (when no active users)
            if userLocations.isEmpty && !isLoading {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No Active Users")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            Text("Waiting for users to share location")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .padding(.horizontal, 16)
                    .padding(.top, 100)
                }
            }
            
            // Loading Indicator
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(hex: "#F59E0B"))
                    Text("Loading locations...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 8)
            }
            
            // Bottom Status
            VStack {
                Spacer()
                
                if !userLocations.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                        Text("Tracking \(userLocations.count) user\(userLocations.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    .padding(.bottom, 30)
                } else if !isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.red)
                        Text("Waiting for location...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 4)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            setupSocketConnection()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Setup Socket Connection
    private func setupSocketConnection() {
        // Note: Backend currently only supports order-specific tracking
        // General "all users" tracking is not yet implemented in the backend
        // This screen will show a message indicating the feature is not available
        
        socketManager.connect()
        
        // Listen to connection status
        socketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [self] connected in
                isConnected = connected
                isLoading = false
                
                // Show message that general tracking is not available
                // Backend only supports order-specific tracking via join-order
                if connected {
                    print("⚠️ General tracking not supported by backend. Backend only supports order-specific tracking.")
                }
            }
            .store(in: &cancellables)
        
        // Request current location for display
        trackingService.getCurrentLocationOnce()
    }
    
    // MARK: - Update Map Region
    private func updateMapRegion() {
        guard !userLocations.isEmpty else { return }
        
        let coordinates = Array(userLocations.values)
        let minLat = coordinates.map { $0.latitude }.min() ?? region.center.latitude
        let maxLat = coordinates.map { $0.latitude }.max() ?? region.center.latitude
        let minLon = coordinates.map { $0.longitude }.min() ?? region.center.longitude
        let maxLon = coordinates.map { $0.longitude }.max() ?? region.center.longitude
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max((maxLat - minLat) * 1.3, 0.01)
        let lonDelta = max((maxLon - minLon) * 1.3, 0.01)
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
    
    // MARK: - Get Annotations
    private func getAnnotations() -> [UserLocationAnnotation] {
        userLocations.map { userId, coordinate in
            UserLocationAnnotation(
                id: userId,
                coordinate: coordinate,
                userName: userId // You might want to fetch actual usernames
            )
        }
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        cancellables.removeAll()
    }
}

// MARK: - User Location Annotation
struct UserLocationAnnotation: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
    let userName: String
}

