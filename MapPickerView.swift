import SwiftUI
import MapKit

struct MapPinLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct MapPickerView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedLocation: MapPinLocation?
    @State private var locationName: String = "Déplacez la carte pour sélectionner"
    @State private var isLoadingAddress: Bool = false
    
    var body: some View {
        ZStack {
            // La carte
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                annotationItems: selectedLocation != nil ? [selectedLocation!] : []
            ) { location in
                MapMarker(coordinate: location.coordinate, tint: .red)
            }
            .edgesIgnoringSafeArea(.all)
            
            // Pin fixe au centre de la carte
            VStack {
                Spacer()
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.red)
                    .shadow(radius: 5)
                Spacer()
            }
            
            VStack {
                // Info du lieu en haut
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if isLoadingAddress {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Recherche de l'adresse...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text(locationName)
                                .font(.headline)
                                .foregroundColor(BrandColors.TextPrimary)
                            
                            Text(String(format: "%.4f, %.4f",
                                      region.center.latitude,
                                      region.center.longitude))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.95))
                .cornerRadius(12)
                .shadow(radius: 4)
                .padding()
                
                Spacer()
                
                // Instructions
                Text("📍 Déplacez la carte pour positionner le pin")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(20)
                    .padding(.bottom, 8)
                
                // Boutons en bas
                HStack(spacing: 16) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(BrandColors.TextPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    Button("Confirmer") {
                        // Toujours utiliser le centre de la carte
                        selectedCoordinate = region.center
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(BrandColors.Yellow)
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white.opacity(0.95))
                .shadow(radius: 4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Charger l'adresse initiale
            reverseGeocode(coordinate: region.center)
        }
        .onChange(of: region.center.latitude) { _ in
            // Mettre à jour l'adresse quand la carte bouge
            debounceGeocoding()
        }
        .onChange(of: region.center.longitude) { _ in
            // Mettre à jour l'adresse quand la carte bouge
            debounceGeocoding()
        }
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        isLoadingAddress = true
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                isLoadingAddress = false
                
                if let error = error {
                    print("Erreur de géocodage: \(error.localizedDescription)")
                    locationName = "Lieu sélectionné"
                    return
                }
                
                if let placemark = placemarks?.first {
                    var addressComponents: [String] = []
                    
                    if let name = placemark.name {
                        addressComponents.append(name)
                    }
                    if let thoroughfare = placemark.thoroughfare {
                        if !addressComponents.contains(thoroughfare) {
                            addressComponents.append(thoroughfare)
                        }
                    }
                    if let locality = placemark.locality {
                        addressComponents.append(locality)
                    }
                    if let country = placemark.country {
                        addressComponents.append(country)
                    }
                    
                    locationName = addressComponents.isEmpty
                        ? "Lieu sélectionné"
                        : addressComponents.joined(separator: ", ")
                }
            }
        }
    }
    
    // Timer pour éviter trop d'appels API pendant le déplacement de la carte
    @State private var geocodingWorkItem: DispatchWorkItem?
    
    private func debounceGeocoding() {
        geocodingWorkItem?.cancel()
        
        let workItem = DispatchWorkItem {
            reverseGeocode(coordinate: region.center)
        }
        
        geocodingWorkItem = workItem
        
        // Attendre 0.5 secondes après l'arrêt du déplacement
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
}
