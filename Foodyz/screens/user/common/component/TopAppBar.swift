import SwiftUI

// MARK: - TopAppBar Colors (Enhanced Professional Design)
struct TopAppBarColors {
    static let background = Color.white
    static let lightGray = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15) // #262626
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.0) // #FF6B00
    static let notificationBadge = Color(red: 1.0, green: 0.65, blue: 0.0) // #FFA500
    static let selectedBackground = Color(red: 1.0, green: 0.93, blue: 0.60) // #FFF499
}

// MARK: - UserBottomBar (Floating Design)
struct UserBottomBar: View {
    @Binding var selectedTab: String
    var onTabSelect: (String) -> Void
    var onReels: () -> Void
    var onTrending: () -> Void
    var onChat: () -> Void
    var onMenu: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Home
            bottomBarButton(icon: "house.fill", tab: "home", action: { onTabSelect("home") })
            Spacer()
            
            // Reels
            bottomBarButton(icon: "play.fill", tab: "reels", action: onReels)
            Spacer()
            
            // Trending
            bottomBarButton(icon: "chart.line.uptrend.xyaxis", tab: "trending", action: onTrending)
            Spacer()
            
            // Chat
            bottomBarButton(icon: "message.fill", tab: "chat", action: onChat)
            Spacer()
            
            // Notifications
            bottomBarButton(icon: "bell.fill", tab: "notifications", action: onMenu)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(35)
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 5)
        .padding(.horizontal, 24)
        .padding(.bottom, 10)
    }
    
    private func bottomBarButton(icon: String, tab: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if selectedTab == tab {
                    Circle()
                        .fill(Color(red: 0.96, green: 0.62, blue: 0.04)) // Yellow/Orange #F59E0B
                        .frame(width: 48, height: 48)
                        .scaleEffect(1.0)
                        .transition(.scale)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? .black : .gray)
            }
            .frame(width: 48, height: 48)
        }
    }
}

// MARK: - Legacy TopAppBarView (Kept for compatibility if needed, but intended to be replaced)
struct TopAppBarView: View {
    @Binding var showNotifications: Bool
    @Binding var selectedTab: String
    var openDrawer: () -> Void
    var onSearchClick: () -> Void
    var onProfileClick: () -> Void
    var onMessagesTap: () -> Void
    var onOrdersClick: (() -> Void)? = nil
    var onAddPostClick: (() -> Void)? = nil
    var onReelsClick: (() -> Void)? = nil
    var onHomeClick: (() -> Void)? = nil
    var onAnalyticsClick: (() -> Void)? = nil
    var onDeleteClick: (() -> Void)? = nil
    var showDeleteButton: Bool = false
    var currentScreen: NavigationScreen = .home

    var body: some View {
        // This view is deprecated for the Home Screen but kept for other screens that might use it
        // until they are refactored.
        VStack(spacing: 0) {
            HStack {
                Text("Foodies")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
                Button(action: openDrawer) {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.black)
                }
            }
            .background(Color.white)
        }
    }
}

// MARK: - Screen Type for Navigation
enum NavigationScreen: String {
    case home = "home"
    case analytics = "analytics"
    case reels = "reels"
    case chat = "chat"
    case orders = "orders"
}
