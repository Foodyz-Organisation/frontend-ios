import SwiftUI

// MARK: - AppColor Helper
/// A wrapper around SwiftUI Color to avoid redeclaration conflicts.
struct AppColor {
    var color: Color // Store the actual SwiftUI Color

    init(hex: UInt, alpha: Double = 1.0) {
        self.color = Color( // Assign to the 'color' property
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// Extension to allow easy conversion/access to SwiftUI's Color
extension AppColor {
    // Computed property to return the internal Color instance
    var swiftUIColor: Color {
        return color
    }
}
// You can also extend Color for convenience when using AppColor.swiftUIColor is too verbose
// This allows you to use AppColor.swiftUIColor in most places it's required.
// For the places where you used 'AppColor(hex: ...)' directly,
// you will need to append '.swiftUIColor'
// OR, you can make AppColor conform to ExpressibleByIntegerLiteral and/or CustomStringConvertible,
// but for simplicity, the computed property is enough.

// ---

struct SplashView: View {
    // MARK: - Properties
    var title: String = "Foodies"
    var subtitle: String = "Discover & Order"
    var logoBackgroundColor: Color = .white
    // FIX: Use .swiftUIColor to get the actual Color value.
    var logoTint: Color = AppColor(hex: 0xF59E0B).swiftUIColor
    var duration: Double = 1.6 // in seconds
    var onFinished: (() -> Void)? = nil
    
    // MARK: - State
    @State private var currentActiveDotIndex = 0
    @State private var animateDots = false
    
    // MARK: - Body
    var body: some View {
        let gradient = LinearGradient(
            colors: [
                // FIX: Use .swiftUIColor to provide Color elements to the array.
                AppColor(hex: 0xFFF176).swiftUIColor,
                AppColor(hex: 0xFFD60A).swiftUIColor
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        ZStack {
            gradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ... (Logo Card and Text remains the same)
                
                // --- Logo Card ---
                ZStack {
                    RoundedRectangle(cornerRadius: 48)
                        .fill(logoBackgroundColor)
                        .frame(width: 160, height: 160)
                        .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 8)
                    
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(logoTint)
                }
                
                Spacer().frame(height: 24)
                
                // --- Title ---
                Text(title)
                    .font(.system(size: 48, weight: .black))
                    .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
                
                Spacer().frame(height: 8)
                
                // --- Subtitle ---
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.17))
                    .multilineTextAlignment(.center)
                
                Spacer().frame(height: 28)
                
                // --- Animated Dots ---
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        let isActive = index == currentActiveDotIndex
                        // FIX: Use .swiftUIColor here as well
                        let color = isActive
                            ? AppColor(hex: 0xFFF1B0).swiftUIColor
                            : AppColor(hex: 0xFFF1B0).swiftUIColor.opacity(0.6)
                        
                        Circle()
                            .fill(color)
                            .frame(width: isActive ? 14 : 12, height: isActive ? 14 : 12)
                            .scaleEffect(animateDots && isActive ? 1.1 : 0.85)
                            .animation(.easeInOut(duration: 0.6), value: animateDots)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            animateDots = true
            startDotAnimation()
        }
    }
    
    // MARK: - Animation Logic
    private func startDotAnimation() {
        let cycleDuration: Double = 0.6
        let totalCycles = Int((duration / cycleDuration).rounded(.down))
        
        Task {
            for _ in 0..<totalCycles {
                // Best practice for Task.sleep is to use the actual time units for clarity
                try? await Task.sleep(for: .nanoseconds(UInt64(cycleDuration * 1_000_000_000)))
                withAnimation(.linear(duration: 0.3)) {
                    currentActiveDotIndex = (currentActiveDotIndex + 1) % 3
                }
            }
            
            // Delay remaining and trigger callback
            let remainingDelay = duration - (Double(totalCycles) * cycleDuration)
            if remainingDelay > 0 {
                // Best practice for Task.sleep is to use the actual time units for clarity
                try? await Task.sleep(for: .nanoseconds(UInt64(remainingDelay * 1_000_000_000)))
            }
            
            // Execute onFinished on the main actor since it updates the UI
            await MainActor.run {
                onFinished?()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
}
