import SwiftUI

// MARK: - TopAppBar Colors (self-contained for this file)
struct TopAppBarColors {
    static let background = AppColors.background
    static let lightGray = AppColors.lightGray
    static let darkGray = AppColors.darkGray
    static let primary = AppColors.primary
}

// MARK: - 1. TopAppBarView (Header)
struct TopAppBarView: View {
    @Binding var showNotifications: Bool
    var openDrawer: () -> Void
    var onSearchClick: () -> Void
    var onProfileClick: () -> Void
    var onOrdersClick: (() -> Void)? = nil // NEW: Navigate to orders
    var onMessagesTap: () -> Void
    @EnvironmentObject private var session: SessionManager
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Profile Button
                Button(action: onProfileClick) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable().scaledToFit().frame(width: 28, height: 28)
                        .foregroundColor(TopAppBarColors.darkGray)
                        .padding(10)
                        .background(TopAppBarColors.lightGray)
                        .clipShape(Circle())
                    AvatarView(avatarURL: session.avatarURL, size: 44, fallback: session.displayName)
                        .overlay(Circle().stroke(TopAppBarColors.lightGray, lineWidth: 1))
                }

                Text("Foodies")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(TopAppBarColors.darkGray)

                Spacer()

                // Plus Button (Add)
                Button(action: { print("Add Clicked") }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(TopAppBarColors.darkGray)
                        .padding(10)
                        .background(TopAppBarColors.lightGray)
                        .clipShape(Circle())
                }

                // Search Button
                Button(action: onSearchClick) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(TopAppBarColors.darkGray)
                        .padding(10)
                        .background(TopAppBarColors.lightGray)
                        .clipShape(Circle())
                }

                // Notifications with badge
                Button(action: { withAnimation { showNotifications.toggle() } }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(TopAppBarColors.darkGray)
                            .padding(10)
                            .background(TopAppBarColors.lightGray)
                            .clipShape(Circle())

                        Circle()
                            .fill(Color(red: 1.0, green: 0.67, blue: 0.0))
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: 4)
                            .fill(Color.red)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Text("3")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 6, y: -6)
                    }
                }

                // Drawer Button
                Button(action: openDrawer) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(TopAppBarColors.darkGray)
                        .padding(10)
                        .background(TopAppBarColors.lightGray)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 12)
            .background(TopAppBarColors.background)

            Divider().padding(.horizontal, 8)

            SecondaryNavBarView(onOrdersClick: onOrdersClick)
            SecondaryNavBarView(onMessagesTap: onMessagesTap)
        }
        .background(TopAppBarColors.background.ignoresSafeArea(edges: .top))
    }
}

// MARK: - 2. SecondaryNavBarView
struct SecondaryNavBarView: View {
    var onMessagesTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            NavBarItem(icon: "house.fill", selected: true)
            NavBarItem(icon: "chart.line.uptrend.xyaxis")
            NavBarItem(icon: "play.fill")
            NavBarItem(icon: "message.fill", action: onMessagesTap)
            NavBarItem(icon: "dollarsign.circle.fill")
        }
        .padding(.vertical, 10)
        .background(TopAppBarColors.background)
    }
}

// MARK: - 3. NavBarItem
struct NavBarItem: View {
    var icon: String
    var selected: Bool = false
    var onClick: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            onClick?()
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(selected ? .black : Color.gray)
                .frame(width: 48, height: 48)
                .background(selected ? Color(red: 1.0, green: 0.93, blue: 0.60) : Color.clear)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle()) // Prevents default button styling
    }
}

// MARK: - Preview
struct TopAppBarView_Previews: PreviewProvider {
    static var previews: some View {
        TopAppBarPreviewWrapper()
    }

    struct TopAppBarPreviewWrapper: View {
        @State private var showingNotifications = false
        var body: some View {
            VStack {
                TopAppBarView(
                    showNotifications: $showingNotifications,
                    openDrawer: { },
                    onSearchClick: { },
                    onProfileClick: { },
                    onMessagesTap: { }
                )
                .environmentObject(SessionManager.shared)
                Spacer()
            }
            .background(TopAppBarColors.background.ignoresSafeArea())
        }
    }
}
