import SwiftUI

// MARK: - TopAppBar Colors (Enhanced Professional Design)
struct TopAppBarColors {
    static let background = Color.white
    static let lightGray = Color(red: 0.96, green: 0.96, blue: 0.96) // #F5F5F5 - Softer gray
    static let darkGray = Color(red: 0.15, green: 0.15, blue: 0.15) // #262626 - Darker for better contrast
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.0) // #FF6B00
    static let notificationBadge = Color(red: 1.0, green: 0.65, blue: 0.0) // #FFA500 - Orange/Yellow badge
    static let selectedBackground = Color(red: 1.0, green: 0.93, blue: 0.60) // #FFF499 - Light yellow highlight
}

// MARK: - 1. TopAppBarView (Header) - Professional Redesign
struct TopAppBarView: View {
    @Binding var showNotifications: Bool
    @Binding var selectedTab: String
    var openDrawer: () -> Void
    var onSearchClick: () -> Void
    var onProfileClick: () -> Void
    var onMessagesTap: () -> Void
    var onOrdersClick: (() -> Void)? = nil
    var appTitle: String = "Foodies" // App title

    var body: some View {
        VStack(spacing: 0) {
            // Main Header Row
            HStack(spacing: 16) {
                // Profile Button - Left
                Button(action: onProfileClick) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(TopAppBarColors.darkGray)
                        .padding(8)
                        .background(TopAppBarColors.lightGray)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())

                // App Title - Center (Bold & Prominent)
                Text(appTitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(TopAppBarColors.darkGray)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                // Action Buttons - Right
                HStack(spacing: 8) {
                    // Plus Button
                    Button(action: { print("Add Clicked") }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(TopAppBarColors.darkGray)
                            .frame(width: 36, height: 36)
                            .background(TopAppBarColors.lightGray)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Search Button
                    Button(action: onSearchClick) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(TopAppBarColors.darkGray)
                            .frame(width: 36, height: 36)
                            .background(TopAppBarColors.lightGray)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Notifications with Badge
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showNotifications.toggle()
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(TopAppBarColors.darkGray)
                                .frame(width: 36, height: 36)
                                .background(TopAppBarColors.lightGray)
                                .clipShape(Circle())

                            // Notification Badge - Yellow/Orange dot
                            Circle()
                                .fill(TopAppBarColors.notificationBadge)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                                .offset(x: 6, y: -6)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Hamburger Menu
                    Button(action: openDrawer) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(TopAppBarColors.darkGray)
                            .frame(width: 36, height: 36)
                            .background(TopAppBarColors.lightGray)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(TopAppBarColors.background)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)

            // Subtle Divider
            Divider()
                .background(Color.gray.opacity(0.1))
                .padding(.horizontal, 0)

            // Secondary Navigation Bar
            SecondaryNavBarView(onOrdersClick: onOrdersClick, onMessagesClick: onMessagesTap)
        }
        .background(TopAppBarColors.background.ignoresSafeArea(edges: .top))
    }
}

// MARK: - 2. SecondaryNavBarView - Enhanced Design
struct SecondaryNavBarView: View {
    @State private var selectedIndex: Int = 0
    var onOrdersClick: (() -> Void)? = nil
    var onMessagesClick: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            // Home - Selected by default
            NavBarItem(
                icon: "house.fill",
                selected: selectedIndex == 0,
                onClick: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = 0
                    }
                }
            )
            
            // Analytics/Charts
            NavBarItem(
                icon: "chart.line.uptrend.xyaxis",
                selected: selectedIndex == 1,
                onClick: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = 1
                    }
                }
            )
            
            // Events/Media
            NavBarItem(
                icon: "play.fill",
                selected: selectedIndex == 2,
                onClick: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = 2
                    }
                }
            )
            
            // Messages/Chat
            NavBarItem(
                icon: "message.fill",
                selected: selectedIndex == 3,
                onClick: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = 3
                    }
                    onMessagesClick?()
                }
            )
            
            // Orders/Transactions
            NavBarItem(
                icon: "dollarsign.circle.fill",
                selected: selectedIndex == 4,
                onClick: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = 4
                    }
                    onOrdersClick?()
                }
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(TopAppBarColors.background)
    }
}

// MARK: - 3. NavBarItem - Professional Styling
struct NavBarItem: View {
    var icon: String
    var selected: Bool = false
    var onClick: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            onClick?()
        }) {
            ZStack {
                // Background - Light yellow when selected
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? TopAppBarColors.selectedBackground : Color.clear)
                    .frame(width: 52, height: 52)
                    .shadow(
                        color: selected ? Color.black.opacity(0.05) : Color.clear,
                        radius: selected ? 4 : 0,
                        x: 0,
                        y: selected ? 2 : 0
                    )
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 22, weight: selected ? .semibold : .medium))
                    .foregroundColor(selected ? TopAppBarColors.darkGray : Color(red: 0.5, green: 0.5, blue: 0.5))
                    .frame(width: 52, height: 52)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(maxWidth: .infinity)
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
                    selectedTab: .constant("home"),
                    openDrawer: { },
                    onSearchClick: { },
                    onProfileClick: { },
                    onMessagesTap: { }
                )
                Spacer()
            }
            .background(TopAppBarColors.background.ignoresSafeArea())
        }
    }
}
