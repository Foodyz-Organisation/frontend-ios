import SwiftUI
import CoreLocation
import Combine

// MARK: - Share Location Screen
struct ShareLocationScreen: View {
    var onShare: () -> Void
    var onSkip: () -> Void
    
    @StateObject private var locationHelper = LocationPermissionHelper()
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with Back Button (Visual only as per design usually having one, but this is interstitial)
            // Design shows "Votre Commande" top bar. This might be presented FROM OrderConfirmation.
            
            Spacer()
            
            // Icon
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(Color(hex: 0xFF8B5CF6)) // Purple Color
                .background(
                    Circle()
                        .fill(Color(hex: 0xFF8B5CF6).opacity(0.1))
                        .frame(width: 160, height: 160)
                )
            
            // Title
            Text("Partager votre localisation ?")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Permettez-nous d'accéder à votre localisation pour améliorer votre expérience de livraison et vous aider à trouver le restaurant le plus proche.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .lineSpacing(4)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 16) {
                Button(action: {
                    locationHelper.requestPermission {
                        onShare()
                    }
                }) {
                    Text("Partager la localisation")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: 0xFFFFC107)) // Yellow
                        .cornerRadius(12)
                }
                
                Button(action: onSkip) {
                    Text("Passer")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: 0xFF1F2A37), lineWidth: 1)
                        )
                        .cornerRadius(12)
                }
            }
            .padding(.bottom, 20)
        }
        .padding(24)
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
    }
}

// Helper for simple internal permission request
class LocationPermissionHelper: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    var onAuthChange: (() -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestPermission(completion: @escaping () -> Void) {
        self.onAuthChange = completion
        locationManager.requestWhenInUseAuthorization()
        
        // If already authorized, just call completion
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            completion()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            onAuthChange?()
        }
    }
}
