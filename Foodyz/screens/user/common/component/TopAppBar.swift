import SwiftUI

// MARK: - TopAppBar Colors (self-contained for this file)
struct TopAppBarColors {
    static let background = Color.white
    static let lightGray = Color(red: 0.94, green: 0.94, blue: 0.94) // #F0F0F0
    static let darkGray = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.0) // #FF6B00
}

// MARK: - 1. TopAppBarView (Header)
struct TopAppBarView: View {
    @Binding var showNotifications: Bool
    var openDrawer: () -> Void
    var onSearchClick: () -> Void
    var onProfileClick: () -> Void
    var onOrdersClick: (() -> Void)? = nil // NEW: Navigate to orders

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
        }
        .background(TopAppBarColors.background.ignoresSafeArea(edges: .top))
    }
}

// MARK: - 2. SecondaryNavBarView
struct SecondaryNavBarView: View {
    var onOrdersClick: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            NavBarItem(icon: "house.fill", selected: true)
            NavBarItem(icon: "chart.line.uptrend.xyaxis")
            NavBarItem(icon: "play.fill")
            NavBarItem(icon: "message.fill")
            NavBarItem(icon: "dollarsign.circle.fill", onClick: {
                onOrdersClick?()
            })
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
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
                    onProfileClick: { }
                )
                Spacer()
            }
            .background(TopAppBarColors.background.ignoresSafeArea())
        }
    }
}
