import SwiftUI

// MARK: - Home Colors
struct HomeColors {
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98) // Light gray background
    static let lightGray = Color(red: 0.94, green: 0.94, blue: 0.94) // #F0F0F0
    static let darkGray = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.0) // #FF6B00
    static let white = Color.white
    static let pinkCard = Color(red: 0.98, green: 0.88, blue: 0.93) // Pastel pink #FAE1ED
    static let yellowCard = Color(red: 1.0, green: 0.95, blue: 0.80) // Pastel yellow #FFF4CC
    static let yellowHighlight = Color(red: 1.0, green: 0.93, blue: 0.60) // Yellow highlight #FFED99
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
}


// MARK: - HomeUserScreen
struct HomeUserScreen: View {
    @State private var showingDrawer = false
    @State private var showingSearch = false
    @State private var selectedFilter: String = "All"
    @State private var currentRoute: String = "home"
    @State private var navigateToProfessionalId: String? = nil

    let filters = ["All", "Spicy", "Healthy", "Sweet"]
    
    var onNavigateDrawer: ((String) -> Void)? = nil
    var onNavigateToProfessional: ((String) -> Void)? = nil
    var onNavigateToOrders: (() -> Void)? = nil // NEW: Navigate to order history
    var onOpenMessages: (() -> Void)? = nil
    var onOpenProfile: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Top App Bar
                TopAppBarView(
                    showNotifications: $showingNotifications,
                    openDrawer: { withAnimation { showingDrawer = true } },
                    onSearchClick: { showingSearch = true },
                    onProfileClick: {
                        currentRoute = "profile"
                        onOpenProfile?()
                    },
                    onMessagesTap: {
                        currentRoute = "chat"
                        onOpenMessages?()
                    },
                    onOrdersClick: {
                        currentRoute = "orders"
                        onNavigateToOrders?()
                    }
                )

                ScrollView {
                    VStack(spacing: 20) {
                        // Categories
                        HStack(spacing: 16) {
                            CategoryCard(icon: "fork.knife", title: "Eat-in", subtitle: "Dine with us", backgroundColor: HomeColors.pinkCard, iconColor: Color(red: 0.89, green: 0.27, blue: 0.58))
                            
                            CategoryCard(icon: "calendar", title: "Daily Deals", subtitle: "Up to 50% off", backgroundColor: HomeColors.yellowCard, iconColor: Color(red: 0.96, green: 0.62, blue: 0.14))
                                .onTapGesture {
                                    onNavigateToOrders?()
                                }
                        }
                        .padding(.horizontal, 16)

                        // Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filters, id: \.self) { filter in
                                    FilterChip(
                                        label: filter,
                                        isSelected: selectedFilter == filter,
                                        icon: filterIcon(for: filter)
                                    )
                                    .onTapGesture { selectedFilter = filter }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Posts screen
                        PostsScreen()
                            .padding(.bottom, 30)
                    }
                    .padding(.top, 16)
                }
                .background(AppColors.background)
            }
            .background(AppColors.background.ignoresSafeArea())

            // Drawer overlay
            if showingDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showingDrawer = false } }

                HStack(spacing: 0) {
                    DrawerView(
                        onCloseDrawer: { withAnimation { showingDrawer = false } },
                        navigateTo: { route in
                                currentRoute = route
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
        .sheet(isPresented: $showingSearch) {
            SearchScreen { professionalId in
                showingSearch = false
                onNavigateToProfessional?(professionalId)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Helpers
    private func filterIcon(for filter: String) -> String? {
        switch filter {
        case "Spicy": return "flame.fill"
        case "Healthy": return "leaf.fill"
        case "Sweet": return "birthday.cake.fill"
        default: return nil
        }
    }
}

// MARK: - CategoryCard
struct CategoryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 56, height: 56)
                .background(iconColor.opacity(0.2))
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HomeColors.darkGray)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(backgroundColor)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
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
        .foregroundColor(isSelected ? AppColors.white : AppColors.darkGray)
        .background(isSelected ? AppColors.darkGray : AppColors.lightGray)
        .cornerRadius(20)
        .shadow(color: isSelected ? .clear : Color.black.opacity(0.05), radius: 2)
    }
}

// MARK: - Preview
struct HomeUserScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeUserScreen()
            .previewLayout(.sizeThatFits)
            .environmentObject(SessionManager.shared)
    }
}
