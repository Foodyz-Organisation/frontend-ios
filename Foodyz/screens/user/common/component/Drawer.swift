import SwiftUI

struct DrawerItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let route: String // Used to track selection or initiate external navigation
    let isLogout: Bool
}

struct DrawerView: View {
    let onCloseDrawer: () -> Void
    let navigateTo: (String) -> Void
    var currentRoute: String // Highlight the currently active route
    @EnvironmentObject private var session: SessionManager
    
    let menuItems: [DrawerItem] = [
        DrawerItem(icon: "house.fill", label: "Home", route: "home", isLogout: false),
        DrawerItem(icon: "bubble.left.and.bubble.right.fill", label: "Messages", route: "chat", isLogout: false),
        DrawerItem(icon: "gearshape.fill", label: "Settings", route: "settings", isLogout: false),
        DrawerItem(icon: "heart.fill", label: "Favorites", route: "favorites", isLogout: false),
        DrawerItem(icon: "person.fill", label: "Profile", route: "profile", isLogout: false),
        DrawerItem(icon: "questionmark.circle.fill", label: "Help & Support", route: "help", isLogout: false),
        DrawerItem(icon: "person.badge.plus", label: "Signup as Professional", route: "signup_pro", isLogout: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Profile Header
            VStack(alignment: .leading, spacing: 8) {
                AvatarView(avatarURL: session.avatarURL, size: 64, fallback: session.displayName)
                    .overlay(Circle().stroke(AppColors.primary, lineWidth: 2))

                Text(session.displayName ?? "Foodies Member")
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(AppColors.darkGray)
                Text(session.email ?? "Add your email")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
            
            Divider()
            
            // MARK: Menu Items
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(menuItems) { item in
                        DrawerRow(item: item, isSelected: currentRoute == item.route)
                            .onTapGesture {
                                navigateTo(item.route)
                                onCloseDrawer()
                            }
                    }
                    
                    // MARK: Logout Item
                    DrawerRow(
                        item: DrawerItem(icon: "arrow.right.square.fill", label: "Logout", route: "logout", isLogout: true),
                        isSelected: currentRoute == "logout"
                    )
                    .onTapGesture {
                        Task {
                            do {
                                // Call your logout API
                                try await AuthAPI.shared.logout()
                                
                                // Close drawer
                                onCloseDrawer()
                                
                                // Navigate back to login
                                navigateTo("login")
                            } catch {
                                print("Logout failed: \(error.localizedDescription)")
                                // Optionally show alert to user
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
            
            Spacer()
        }
        .frame(width: 280)
        .background(AppColors.white)
        .edgesIgnoringSafeArea(.vertical)
    }
}

// MARK: Drawer Row Sub-Component
struct DrawerRow: View {
    let item: DrawerItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(item.isLogout ? .red : (isSelected ? AppColors.primary : AppColors.darkGray))
            
            Text(item.label)
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(item.isLogout ? .red : AppColors.darkGray)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(isSelected && !item.isLogout ? AppColors.primary.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}
