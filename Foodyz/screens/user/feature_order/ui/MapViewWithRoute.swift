import SwiftUI
import MapKit
import Combine

// MARK: - MapViewRepresentable with Route Support
struct MapViewWithRoute: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var restaurantLocation: CLLocationCoordinate2D?
    var userLocation: CLLocationCoordinate2D?
    var route: MKRoute?
    var showsUserLocation: Bool = false
    var onMapTap: (() -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.userTrackingMode = .none
        mapView.mapType = .standard
        
        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.mapTapped(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        // Remove existing annotations
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        
        // Add restaurant annotation
        if let restaurantLocation = restaurantLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = restaurantLocation
            annotation.title = "Restaurant"
            mapView.addAnnotation(annotation)
        }
        
        // Add user annotation
        // Always show custom annotation if userLocation is provided, even if showsUserLocation is true
        // This ensures the user location is visible with a custom marker
        if let userLocation = userLocation {
            // Check if we already have a "You" annotation
            let existingUserAnnotation = mapView.annotations.first { annotation in
                annotation.title == "You"
            }
            
            if existingUserAnnotation == nil {
                let annotation = MKPointAnnotation()
                annotation.coordinate = userLocation
                annotation.title = "You"
                mapView.addAnnotation(annotation)
            } else if let existing = existingUserAnnotation as? MKPointAnnotation {
                // Update existing annotation coordinate
                existing.coordinate = userLocation
            }
        }
        
        // Add route polyline
        if let route = route {
            mapView.addOverlay(route.polyline, level: .aboveRoads)
            // Fit map to show the entire route
            let rect = route.polyline.boundingMapRect
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 80, left: 50, bottom: 80, right: 50), animated: true)
        } else if let userLoc = userLocation, let restLoc = restaurantLocation {
            // If no route but both locations exist, draw a straight line and fit both in view
            let coordinates = [userLoc, restLoc]
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
            
            // Fit map to show both locations
            let rect = polyline.boundingMapRect
            mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 80, left: 50, bottom: 80, right: 50), animated: true)
        } else if let restLoc = restaurantLocation {
            // Only restaurant location - center on it
            mapView.setRegion(MKCoordinateRegion(center: restLoc, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWithRoute
        
        init(_ parent: MapViewWithRoute) {
            self.parent = parent
        }
        
        @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
            parent.onMapTap?()
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "CustomAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize based on annotation title
            if annotation.title == "Restaurant" {
                annotationView?.image = UIImage(systemName: "fork.knife.circle.fill")
                annotationView?.tintColor = .red
                annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            } else if annotation.title == "You" {
                annotationView?.image = UIImage(systemName: "person.circle.fill")
                annotationView?.tintColor = .blue
                annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            }
            
            return annotationView
        }
    }
}

// MARK: - Route Calculator
final class RouteCalculator: ObservableObject {
    @Published var route: MKRoute?
    @Published var isCalculating = false
    @Published var error: String?
    
    func calculateRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        isCalculating = true
        error = nil
        
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        directionsRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionsRequest)
        
        directions.calculate { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isCalculating = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    print("❌ Route calculation error: \(error.localizedDescription)")
                    return
                }
                
                guard let route = response?.routes.first else {
                    self?.error = "No route found"
                    return
                }
                
                self?.route = route
                print("✅ Route calculated: \(route.distance / 1000) km, \(route.expectedTravelTime / 60) min")
            }
        }
    }
}

