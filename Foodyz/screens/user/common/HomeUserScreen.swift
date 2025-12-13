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
    @State private var showingSearch = false
    @State private var showingNotifications = false
    @State private var selectedFilter: String = "All"
    @State private var currentRoute: String = "home"
    @State private var navigateToProfessionalId: String? = nil

    let filters = ["All", "Spicy", "Healthy", "Sweet"]
    
    var onNavigateDrawer: ((String) -> Void)? = nil
    var onNavigateToProfessional: ((String) -> Void)? = nil
    var onNavigateToOrders: (() -> Void)? = nil // NEW: Navigate to order history
    var onNavigateToDeals: (() -> Void)? = nil // NEW: Navigate to deals list
    var onOpenMessages: (() -> Void)? = nil
    var onOpenProfile: (() -> Void)? = nil
    @StateObject private var postsViewModel = PostsViewModel()
    @State private var selectedFoodType: String? = nil
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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Promotional Cards - Side by Side
                        HStack(spacing: 16) {
                            // Delivery Card - Light Green
                            PromoCard(
                                icon: "truck.box.fill",
                                title: "Delivery",
                                subtitle: "Delivered to your door",
                                backgroundColor: Color(red: 0.85, green: 0.95, blue: 0.85), // Light green
                                iconColor: Color(red: 0.2, green: 0.7, blue: 0.3) // Green
                            )
                            
                            // Daily Deals Card - Light Yellow
                            PromoCard(
                                icon: "gift.fill",
                                title: "Daily Deals",
                                subtitle: "Up to 50% off",
                                backgroundColor: Color(red: 1.0, green: 0.95, blue: 0.8), // Light yellow
                                iconColor: Color(red: 1.0, green: 0.65, blue: 0.0) // Orange
                            )
                            .onTapGesture {
                                onNavigateToDeals?()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Category Filters - Horizontal Scroll
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filters, id: \.self) { filter in
                                    CategoryFilterChip(
                                        label: filter,
                                        isSelected: selectedFilter == filter,
                                        icon: filterIcon(for: filter),
                                        iconColor: filterIconColor(for: filter)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = filter
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 8)

                        // Food Items List
                        VStack(spacing: 16) {
                            ForEach(sampleFoodItems, id: \.id) { item in
                                FoodItemCard(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
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
    
    private func filterIconColor(for filter: String) -> Color {
        switch filter {
        case "Spicy": return .red
        case "Healthy": return .green
        case "Sweet": return .orange
        default: return .gray
        }
    }
    
    // Sample data for food items
    private var sampleFoodItems: [FoodItem] {
        [
            FoodItem(
                id: "1",
                name: "creqtine impact",
                prepareTime: 15,
                rating: 4.9,
                price: 28
            ),
            FoodItem(
                id: "2",
                name: "Grilled Chicken",
                prepareTime: 20,
                rating: 4.7,
                price: 35
            ),
            FoodItem(
                id: "3",
                name: "Vegetarian Pasta",
                prepareTime: 15,
                rating: 4.8,
                price: 32
            )
        ]
    }
}

// MARK: - Food Item Model
struct FoodItem: Identifiable {
    let id: String
    let name: String
    let prepareTime: Int
    let rating: Double
    let price: Double
}

// MARK: - PromoCard - Professional Design
struct PromoCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let backgroundColor: Color
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 50, height: 50)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(HomeColors.darkGray)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - CategoryFilterChip - Enhanced Design
struct CategoryFilterChip: View {
    let label: String
    let isSelected: Bool
    let icon: String?
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : iconColor)
            }
            Text(label)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.horizontal, isSelected ? 18 : 16)
        .padding(.vertical, 10)
        .foregroundColor(isSelected ? .white : HomeColors.darkGray)
        .background(isSelected ? HomeColors.darkGray : Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(
            color: isSelected ? Color.black.opacity(0.1) : Color.black.opacity(0.05),
            radius: isSelected ? 4 : 2,
            x: 0,
            y: isSelected ? 2 : 1
        )
    }
}

// MARK: - FoodItemCard - Professional Design Matching Reference
struct FoodItemCard: View {
    let item: FoodItem
    @State private var isFavorite = false
    @State private var isBookmarked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section (Placeholder)
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    )
                
                // Prepare Time Badge - Top Left
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text("Prepare \(item.prepareTime) min")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(HomeColors.darkGray)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.95))
                .cornerRadius(12)
                .padding(12)
                
                // Three Dots Menu - Top Right
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(HomeColors.darkGray)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Content Section
            VStack(alignment: .leading, spacing: 12) {
                // Rating - Top
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", item.rating))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(HomeColors.darkGray)
                }
                
                // Item Name
                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(HomeColors.darkGray)
                    .lineLimit(2)
                
                // Price and Action Icons
                HStack {
                    // Price
                    Text("\(Int(item.price)) DT")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(HomeColors.darkGray)
                    
                    Spacer()
                    
                    // Action Icons
                    HStack(spacing: 16) {
                        // Comment
                        Button(action: {}) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        // Share
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        // Favorite
                        Button(action: { isFavorite.toggle() }) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.system(size: 18))
                                .foregroundColor(isFavorite ? .yellow : .gray)
                        }
                        
                        // Bookmark
                        Button(action: { isBookmarked.toggle() }) {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .font(.system(size: 18))
                                .foregroundColor(isBookmarked ? HomeColors.primary : .gray)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - CategoryCard (For use in FoodyzApp.swift)
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


// MARK: - Preview
struct HomeUserScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeUserScreen()
            .previewLayout(.sizeThatFits)
            .environmentObject(SessionManager.shared)
    }
}
