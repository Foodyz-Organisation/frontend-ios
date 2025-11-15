import SwiftUI

// MARK: - Home Colors
struct HomeColors {
    static let background = Color(red: 1.0, green: 0.98, blue: 0.92) // #FFFBEA
    static let lightGray = Color(red: 0.94, green: 0.94, blue: 0.94) // #F0F0F0
    static let darkGray = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.0) // #FF6B00
    static let white = Color.white
}

// Optional Hex initializer
extension Color {
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            r = (int >> 16) & 0xFF
            g = (int >> 8) & 0xFF
            b = int & 0xFF
        default:
            r = 1; g = 1; b = 1
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: alpha)
    }
}

// MARK: - HomeUserScreen
struct HomeUserScreen: View {
    @State private var showingDrawer = false
    @State private var currentRoute: String = "home"
    
    var onNavigateDrawer: ((String) -> Void)? = nil

    var body: some View {
        ZStack {
            // Utiliser MainTabView comme écran principal
            MainTabView()
                .navigationBarBackButtonHidden(true)

            // Drawer overlay
            if showingDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showingDrawer = false } }

                HStack(spacing: 0) {
                    DrawerView(
                        onCloseDrawer: { withAnimation { showingDrawer = false } },
                        navigateTo: { route in
                            onNavigateDrawer?(route)
                            withAnimation { showingDrawer = false }
                        },
                        currentRoute: currentRoute
                    )
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .animation(.easeInOut, value: showingDrawer)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { withAnimation { showingDrawer = true } }) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - CategoryCard
struct CategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .padding(12)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            Text(title).font(.system(size: 18, weight: .semibold)).foregroundColor(HomeColors.darkGray)
            Text(subtitle).font(.system(size: 14)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(HomeColors.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon { Image(systemName: icon) }
            Text(label).font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundColor(isSelected ? HomeColors.white : HomeColors.darkGray)
        .background(isSelected ? HomeColors.darkGray : HomeColors.lightGray)
        .cornerRadius(20)
        .shadow(color: isSelected ? .clear : Color.black.opacity(0.05), radius: 2)
    }
}

// MARK: - Preview
struct HomeUserScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeUserScreen(onNavigateDrawer: { _ in })
        }
    }
}
