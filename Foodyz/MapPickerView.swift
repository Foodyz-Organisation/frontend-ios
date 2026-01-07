import SwiftUI
import MapKit
import CoreLocation

// MARK: - Search Result Model
struct SearchResult: Identifiable, Codable {
    let id: UUID
    let displayName: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Nominatim Response
struct NominatimResponse: Codable {
    let display_name: String
    let lat: String
    let lon: String
}

struct MapPickerView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @State private var region: MKCoordinateRegion
    @State private var annotation: MKPointAnnotation?
    @Environment(\.dismiss) private var dismiss
    
    // Search state
    @State private var searchText: String = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching: Bool = false
    @State private var showSearchResults: Bool = false
    
    init(selectedCoordinate: Binding<CLLocationCoordinate2D?>) {
        self._selectedCoordinate = selectedCoordinate
        
        // Initialize region with existing coordinate or default location (Tunis, Tunisia)
        if let coord = selectedCoordinate.wrappedValue {
            _region = State(initialValue: MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
            _annotation = State(initialValue: {
                let annot = MKPointAnnotation()
                annot.coordinate = coord
                return annot
            }())
        } else {
            // Default to Tunis, Tunisia
            let defaultCoord = CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815)
            _region = State(initialValue: MKCoordinateRegion(
                center: defaultCoord,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }
    
    var body: some View {
        ZStack {
            // Map with coordinate region
            Map(coordinateRegion: $region, annotationItems: annotationItems) { item in
                MapMarker(coordinate: item.coordinate, tint: .red)
            }
            .onChange(of: region.center.latitude) { oldValue, newValue in
                // Update annotation when region center changes
                updateAnnotation(for: region.center)
            }
            .onChange(of: region.center.longitude) { oldValue, newValue in
                // Update annotation when region center changes
                updateAnnotation(for: region.center)
            }
            
            // Center marker overlay
            VStack {
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                    .offset(y: -20)
            }
            
            // Search Bar
            VStack {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Rechercher un lieu...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { oldValue, newValue in
                                if !newValue.isEmpty {
                                    searchPlaces(query: newValue)
                                } else {
                                    searchResults = []
                                    showSearchResults = false
                                }
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                                showSearchResults = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                }
                .padding()
                
                // Search Results
                if showSearchResults && !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(searchResults) { result in
                                Button(action: {
                                    selectSearchResult(result)
                                }) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.blue)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(result.displayName)
                                                .foregroundColor(.primary)
                                                .font(.body)
                                                .lineLimit(2)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.white)
                                }
                                
                                Divider()
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                    }
                    .frame(maxHeight: 300)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            
            // Action buttons
            VStack {
                Spacer()
                HStack {
                    Button("Annuler") {
                        dismiss()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    Spacer()
                    
                    Button("Sélectionner") {
                        updateSelectedCoordinate(region.center)
                        dismiss()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .padding()
            }
        }
        .onAppear {
            // Update annotation on appear
            if let coord = selectedCoordinate {
                updateAnnotation(for: coord)
            }
        }
    }
    
    private var annotationItems: [MapAnnotation] {
        if let annotation = annotation {
            return [MapAnnotation(coordinate: annotation.coordinate)]
        }
        return []
    }
    
    private func updateSelectedCoordinate(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        updateAnnotation(for: coordinate)
    }
    
    private func updateAnnotation(for coordinate: CLLocationCoordinate2D) {
        let annot = MKPointAnnotation()
        annot.coordinate = coordinate
        annotation = annot
    }
    
    // MARK: - Search Functions
    private func searchPlaces(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            showSearchResults = false
            return
        }
        
        isSearching = true
        
        // Encode query for URL
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            isSearching = false
            return
        }
        
        // Nominatim API endpoint
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(encodedQuery)&format=json&limit=5&countrycodes=tn"
        guard let url = URL(string: urlString) else {
            isSearching = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Foodyz iOS App", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSearching = false
                
                guard let data = data, error == nil else {
                    print("Search error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                do {
                    let responses = try JSONDecoder().decode([NominatimResponse].self, from: data)
                    searchResults = responses.map { response in
                        SearchResult(
                            id: UUID(),
                            displayName: response.display_name,
                            latitude: Double(response.lat) ?? 0.0,
                            longitude: Double(response.lon) ?? 0.0
                        )
                    }
                    showSearchResults = true
                } catch {
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
    
    private func selectSearchResult(_ result: SearchResult) {
        // Update region to show selected location
        region = MKCoordinateRegion(
            center: result.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        // Update annotation
        updateAnnotation(for: result.coordinate)
        
        // Clear search
        searchText = ""
        searchResults = []
        showSearchResults = false
    }
}

// Helper struct for Map annotations
private struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview
#Preview {
    MapPickerView(selectedCoordinate: .constant(nil))
}

