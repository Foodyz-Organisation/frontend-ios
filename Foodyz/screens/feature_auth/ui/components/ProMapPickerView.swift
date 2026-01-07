import SwiftUI
import MapKit

struct ProMapPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedLocation: LocationDto?
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815), // Tunis default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    @State private var pickedCoordinate: CLLocationCoordinate2D?
    @State private var addressString: String = ""
    @State private var locationName: String = "My Restaurant"
    @State private var isLoadingAddress = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // Map
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: annotationItems) { item in
                    MapMarker(coordinate: item.coordinate, tint: .red)
                }
                .ignoresSafeArea()
                .overlay(
                    Image(systemName: "mappin")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                        .padding(.bottom, 20) // Adjust for center alignment visual
                )
                
                // Bottom Card
                VStack(spacing: 16) {
                    Text("Move map to select location")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if isLoadingAddress {
                        ProgressView()
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(addressString.isEmpty ? "No address selected" : addressString)
                                .font(.body)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            TextField("Location Name (e.g. Main Branch)", text: $locationName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Button(action: confirmLocation) {
                        Text("Confirm Location")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow) // Foodyz Brand Color
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 5)
                .padding()
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            // If already has location, center on it
            if let existing = selectedLocation, let lat = existing.lat, let lon = existing.lon {
                region.center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                pickedCoordinate = region.center
                addressString = existing.address ?? ""
                locationName = existing.name ?? "My Restaurant"
            }
        }
        .onChange(of: region.center.latitude) { _ in
            // Debounce or just wait for explicit "confirm" action?
            // For better UX, let's update immediately but maybe don't reverse geocode constantly to save API calls/rate limits
            // Just update coordinate
            pickedCoordinate = region.center
        }
        // Use a task to handle "drag end" roughly by debouncing
        .task(id: region.center) {
            do {
                try await Task.sleep(nanoseconds: 800_000_000) // 0.8s debounce
                await reverseGeocode(coordinate: region.center)
            } catch {}
        }
    }
    
    private var annotationItems: [IdentifiableCoordinate] {
        // Only show marker if we have a stable pick? 
        // Actually, the center overlay "pin" is better for "move map to select" style.
        // So we don't strictly need extra annotations unless we want to show the 'final' pick.
        return [] 
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) async {
        isLoadingAddress = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let first = placemarks.first {
                let street = first.thoroughfare ?? ""
                let number = first.subThoroughfare ?? ""
                let city = first.locality ?? ""
                let country = first.country ?? ""
                
                await MainActor.run {
                    self.addressString = "\(number) \(street), \(city), \(country)".trimmingCharacters(in: .whitespacesAndNewlines)
                    if self.addressString.hasPrefix(", ") { self.addressString.removeFirst(2) }
                    self.isLoadingAddress = false
                }
            }
        } catch {
            await MainActor.run {
                self.addressString = "Unknown Address" // Could just leave coordinate
                self.isLoadingAddress = false
            }
        }
    }
    
    private func confirmLocation() {
        let coord = region.center
        // Preserve existing ID if editing
        let existingId = selectedLocation?.id
        let newLocation = LocationDto(
            id: existingId, // Preserve ID when editing
            name: locationName.isEmpty ? "My Restaurant" : locationName,
            address: addressString,
            lat: coord.latitude,
            lon: coord.longitude
        )
        selectedLocation = newLocation
        presentationMode.wrappedValue.dismiss()
    }
}

// Wrapper for map markers if needed
struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// Helper for task ID
extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}
