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
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(
                coordinateRegion: $region,
                interactionModes: .all,
                annotationItems: selectedCoordinate != nil
                    ? [MapPinLocation(coordinate: selectedCoordinate!)]
                    : []
            ) { location in
                MapMarker(coordinate: location.coordinate, tint: .red)
            }
            .edgesIgnoringSafeArea(.all)
            
            Button("Confirmer") {
                selectedCoordinate = region.center
                dismiss()
            }
            .padding()
            .background(.white)
            .cornerRadius(10)
            .padding()
        }
    }
}
