import SwiftUI

// MARK: - Filter Chip Component
struct FilterChipComponent: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : Color(hex: "#1F2937"))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: "#111827") : Color(hex: "#F3F4F6"))
                .cornerRadius(25)
        }
    }
}

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
    @StateObject private var postsViewModel = PostsViewModel()
    @State private var selectedFoodType: String? = nil
    @State private var showingNotifications = false
    @State private var showingDrawer = false
    @State private var selectedTab: String = "home"
    @State private var showCreatePost = false
    
    var onNavigateDrawer: ((String) -> Void)? = nil
    var onNavigateToProfile: (() -> Void)? = nil
    var onNavigateToPost: ((String) -> Void)? = nil


    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Top App Bar (Only show on Home)
                if selectedTab == "home" {
                    TopAppBarView(
                        showNotifications: $showingNotifications,
                        selectedTab: $selectedTab,
                        openDrawer: { withAnimation { showingDrawer = true } },
                        onSearchClick: { print("Search Clicked") },
                        onProfileClick: { onNavigateToProfile?() }
                    )
                }

                // Content Area
                ZStack {
                    if selectedTab == "home" {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Categories
                                HStack(spacing: 16) {
                                    CategoryCard(icon: "bag.fill", title: "Takeaway", subtitle: "Pick up your food", color: HomeColors.primary)
                                    CategoryCard(icon: "gift.fill", title: "Daily Deals", subtitle: "Up to 50% off", color: Color(hex: "#F59E0B"))
                                }
                                .padding(.horizontal, 16)
                                
                                // Filter Chips
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        // "All" Filter Chip
                                        FilterChipComponent(
                                            text: "All",
                                            isSelected: selectedFoodType == nil,
                                            action: {
                                                selectedFoodType = nil
                                                Task {
                                                    await postsViewModel.fetchPosts()
                                                }
                                            }
                                        )
                                        
                                        // Food Type Filter Chips
                                        if postsViewModel.isLoadingFoodTypes {
                                            ProgressView()
                                                .frame(width: 20, height: 20)
                                        } else {
                                            ForEach(postsViewModel.foodTypes, id: \.self) { foodType in
                                                FilterChipComponent(
                                                    text: foodType,
                                                    isSelected: selectedFoodType == foodType,
                                                    action: {
                                                        selectedFoodType = foodType
                                                        Task {
                                                            await postsViewModel.fetchPostsByFoodType(foodType)
                                                        }
                                                    }
                                                )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }

                                // Posts screen
                                PostsScreen(
                                    viewModel: postsViewModel,
                                    selectedFoodType: $selectedFoodType,
                                    onPostClick: { postId in
                                        onNavigateToPost?(postId)
                                    }
                                )
                                    .padding(.bottom, 80) // Extra padding for FAB
                            }
                            .padding(.top, 16)
                        }
                        .background(HomeColors.background)
                    } else if selectedTab == "reels" {
                        ReelsScreen(onBack: { selectedTab = "home" })
                    } else if selectedTab == "trending" {
                        TrendingScreen(onBack: { selectedTab = "home" })
                    } else {
                        // Placeholder for other tabs
                        VStack {
                            Text(selectedTab.capitalized)
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(HomeColors.background)
                    }
                }
            }
            .background(HomeColors.background.ignoresSafeArea())

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
                        currentRoute: selectedTab
                    )
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .animation(.easeInOut, value: showingDrawer)
            }
            
            // Floating Action Button (FAB) - Only show on Home
            if selectedTab == "home" {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showCreatePost = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#F59E0B"), Color(hex: "#EF4444")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color(hex: "#F59E0B").opacity(0.4), radius: 8, x: 0, y: 4)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 80) // Move up above nav bar
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Hide system back button
        .sheet(isPresented: $showCreatePost) {
            MediaSelectionView(isPresented: $showCreatePost)
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


// MARK: - Preview
struct HomeUserScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeUserScreen()
            .previewLayout(.sizeThatFits)
    }
}
