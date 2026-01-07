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
    @State private var currentRoute: String = "home"
    @State private var navigateToProfessionalId: String? = nil
    
    var onNavigateDrawer: ((String) -> Void)? = nil
    var onNavigateToProfessional: ((String) -> Void)? = nil
    var onNavigateToOrders: (() -> Void)? = nil // NEW: Navigate to order history
    var onNavigateToDeals: (() -> Void)? = nil // NEW: Navigate to deals list
    var onNavigateToReels: (() -> Void)? = nil // NEW: Navigate to reels screen
    var onNavigateToTrending: (() -> Void)? = nil // NEW: Navigate to trending screen
    var onOpenMessages: (() -> Void)? = nil
    var onOpenProfile: (() -> Void)? = nil
    var onPostClick: ((String) -> Void)? = nil // NEW: Navigate to post details
    var onNotificationsClick: (() -> Void)? = nil // NEW: Navigate to notifications screen
    @StateObject private var postsViewModel = PostsViewModel()
    @StateObject private var dealsViewModel = DealsViewModel()
    @State private var selectedFoodType: String? = nil
    @State private var showingDrawer = false
    @State private var selectedTab: String = "home"
    @State private var showCreatePost = false
    @State private var selectedFilter: String = "All"
    @State private var foodTypes: [String] = FoodType.getAllValues()
    
    // MARK: - Category Model
    struct Category {
        let name: String
        let icon: String // Emoji
        // color is no longer needed for background if uniform, but kept for compatibility or text color if needed
    }
    
    let categories: [Category] = [
        Category(name: "Breakfast", icon: "🥐"),
        Category(name: "Healthy", icon: "🥑"),
        Category(name: "Dessert", icon: "🍰"),
        Category(name: "Burger", icon: "🍔"),
        Category(name: "Pizza", icon: "🍕"),
        Category(name: "Seafood", icon: "🦞"),
        Category(name: "Salad", icon: "🥗"),
        Category(name: "Chicken", icon: "🍗"),
        Category(name: "Pasta", icon: "🍝"),
        Category(name: "Sushi", icon: "�"),
    ]
    
    // Map category names to food type values
    private func mapCategoryToFoodType(_ categoryName: String) -> String? {
        let mapping: [String: String] = [
            "Breakfast": "Fast food",
            "Healthy": "Healthy",
            "Dessert": "Desserts",
            "Burger": "Fast food",
            "Pizza": "Fast food",
            "Seafood": "Seafood",
            "Salad": "Vegetarian-Friendly",
            "Chicken": "Meat",
            "Pasta": "Fast food",
            "Sushi": "Seafood"
        ]
        return mapping[categoryName]
    }

    var body: some View {
        // 1. GeometryReader allows us to get the size, but we shouldn't force the frame size manually
        GeometryReader { geometry in
            ZStack {
                // 2. Background Color needs to be the first layer of ZStack and ignore safe area
                Color.white
                    .ignoresSafeArea()

                // Main content
                VStack(spacing: 0) {
                    // MARK: - Custom Top Bar
                    VStack(spacing: 0) {
                        ZStack {
                            Text("foodyz")
                                .font(.custom("Snell Roundhand", size: 32))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#F59E0B"))
                            
                            HStack {
                                Spacer()
                                
                                Button(action: { withAnimation { showingDrawer = true } }) {
                                    Image(systemName: "line.3.horizontal")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(HomeColors.darkGray)
                                        .padding(10)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }

                        .padding(.top, safeAreaTop) // Use your helper here to avoid the notch
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .background(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
                    }

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {

                        
                        // MARK: - Search & Filter
                        HStack(spacing: 12) {
                            // Search Bar
                            Button(action: {
                                showingSearch = true
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                    Text("Search foods and Kitchen")
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Yellow Filter/Add Button
                            Button(action: {
                                showCreatePost = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color(hex: "#F59E0B")) // Yellow
                                    .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Special Offers Section (without title)
                        VStack(alignment: .leading, spacing: 12) {
                            // Fixed height container to prevent layout shifts
                            Group {
                                if case .loading = dealsViewModel.dealsState {
                                    HStack {
                                        ProgressView()
                                            .tint(Color(hex: "#F59E0B"))
                                        Text("Loading deals...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 160)
                                } else if case .success(let deals) = dealsViewModel.dealsState, !deals.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(deals.prefix(5)) { deal in
                                                DealHomeCard(deal: deal)
                                                    .onTapGesture {
                                                        onNavigateToDeals?()
                                                    }
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                    }
                                    .frame(height: 160)
                                } else {
                                    // No deals available
                                    ZStack {
                                        Color(hex: "#1F2937")
                                        
                                        VStack(spacing: 8) {
                                            Text("🎉")
                                                .font(.system(size: 60))
                                                .padding(.bottom, 4)
                                            
                                            Text("Exciting Deals")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(hex: "#F59E0B"))
                                            
                                            Text("Coming Soon!")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        }
                                        .padding(30)
                                    }
                                    .cornerRadius(20)
                                    .frame(height: 160)
                                }
                            }
                        }
                        
                        // MARK: - Kitchen Near You (Categories) (without title)
                        VStack(alignment: .leading, spacing: 16) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    // "All" option
                                    let isAllSelected = selectedFilter == "All"
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(isAllSelected ? Color(hex: "#F59E0B") : Color(hex: "#FFF9C4"))
                                                .frame(width: 70, height: 70)
                                            
                                            Text("🍽️")
                                                .font(.system(size: 32))
                                        }
                                        
                                        Text("All")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(isAllSelected ? Color(hex: "#F59E0B") : .black)
                                    }
                                    .onTapGesture {
                                        selectedFilter = "All"
                                        Task {
                                            await postsViewModel.fetchPosts()
                                        }
                                    }
                                    
                                    // Category options
                                    ForEach(categories, id: \.name) { category in
                                        let isSelected = selectedFilter != "All" && mapCategoryToFoodType(category.name) == selectedFilter
                                        
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(isSelected ? Color(hex: "#F59E0B") : Color(hex: "#FFF9C4")) // Orange when selected, yellow otherwise
                                                    .frame(width: 70, height: 70)
                                                
                                                Text(category.icon)
                                                    .font(.system(size: 32))
                                            }
                                            
                                            Text(category.name)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(isSelected ? Color(hex: "#F59E0B") : .black) // Orange text when selected
                                        }
                                        .onTapGesture {
                                            // Map category to food type
                                            if let foodType = mapCategoryToFoodType(category.name) {
                                                selectedFilter = foodType
                                                Task {
                                                    await postsViewModel.fetchPostsByFoodType(foodType)
                                                }
                                            } else {
                                                // If no mapping, show all
                                                selectedFilter = "All"
                                                Task {
                                                    await postsViewModel.fetchPosts()
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // MARK: - Feed
                        if postsViewModel.isLoading && postsViewModel.posts.isEmpty {
                            ProgressView()
                                .padding(.vertical, 40)
                        } else if postsViewModel.posts.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(selectedFilter == "All" ? "No posts available" : "No posts found for this category")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 20) {
                                ForEach(postsViewModel.posts) { post in
                                    RecipeCard(post: post)
                                        .onTapGesture {
                                            onPostClick?(post.id)
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                    .padding(.top, 10)
                }
                .background(Color.white) // Main background white
            }
            .background(Color.white.ignoresSafeArea())

            .background(Color.white.ignoresSafeArea())
            
            // MARK: - Floating Bottom Bar
            VStack {
                Spacer()
                UserBottomBar(
                    selectedTab: $selectedTab,
                    onTabSelect: { tab in
                        selectedTab = tab
                    },
                    onReels: { onNavigateToReels?() },
                    onTrending: { onNavigateToTrending?() },
                    onChat: {
                        currentRoute = "chat"
                         onOpenMessages?()
                    },
                    onMenu: {
                        withAnimation { showingDrawer = true }
                    }
                )
            }
            .ignoresSafeArea(.keyboard)

            // Drawer overlay
            if showingDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showingDrawer = false } }

                DrawerView(
                    onCloseDrawer: { withAnimation { showingDrawer = false } },
                    navigateTo: { route in
                            currentRoute = route
                        onNavigateDrawer?(route)
                        withAnimation { showingDrawer = false }
                    },
                    currentRoute: selectedTab
                )
                .transition(.move(edge: .trailing))
                .animation(.easeInOut, value: showingDrawer)
            }
            
        }
        .navigationBarBackButtonHidden(true) // Hide system back button
        .sheet(isPresented: $showCreatePost) {
            MediaSelectionView(
                isPresented: $showCreatePost,
                onPostCreated: {
                    // Refresh posts feed after post creation
                    Task {
                        if selectedFilter == "All" {
                            await postsViewModel.fetchPosts()
                        } else {
                            await postsViewModel.fetchPostsByFoodType(selectedFilter)
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showingSearch) {
            SearchScreen { professionalId in
                showingSearch = false
                onNavigateToProfessional?(professionalId)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await loadFoodTypes()
                // Load posts when screen appears
                await postsViewModel.fetchPosts()
                // Load deals when screen appears
                dealsViewModel.loadDeals()
            }
        }
        .refreshable {
            // Pull to refresh
            if selectedFilter == "All" {
                await postsViewModel.fetchPosts()
            } else {
                await postsViewModel.fetchPostsByFoodType(selectedFilter)
            }
            // Refresh deals
            dealsViewModel.loadDeals()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RefreshPostsFeed"))) { _ in
            Task {
                if selectedFilter == "All" {
                    await postsViewModel.fetchPosts()
                } else {
                    await postsViewModel.fetchPostsByFoodType(selectedFilter)
                }
            }
        }
        }
        // 6. Apply ignoresSafeArea to the GeometryReader itself so it tucks behind the status bar
        .ignoresSafeArea()
    }

    // MARK: - Computed Properties
    private var filtersWithAll: [String] {
        ["All"] + foodTypes
    }

    // MARK: - Helpers
    private var safeAreaTop: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }.first
        
        return keyWindow?.safeAreaInsets.top ?? 47
    }
    
    private func loadFoodTypes() async {
        do {
            let loadedTypes = try await PostsAPI.shared.getFoodTypes()
            await MainActor.run {
                foodTypes = loadedTypes
            }
        } catch {
            print("Failed to load food types: \(error.localizedDescription)")
            // Fallback to enum values if API fails
            await MainActor.run {
                foodTypes = FoodType.getAllValues()
            }
        }
    }
    
    private func filterIcon(for filter: String) -> String? {
        if filter == "All" {
            return nil
        }
        
        // Map common food types to icons
        switch filter.lowercased() {
        case "spicy":
            return "flame.fill"
        case "healthy":
            return "leaf.fill"
        case "desserts", "sweet":
            return "birthday.cake.fill"
        case "seafood":
            return "fish.fill"
        case "meat":
            return "fork.knife"
        case "vegetarian-friendly", "vegetarian":
            return "leaf.fill"
        case "fast food", "fastfood":
            return "takeoutbag.and.cup.and.straw.fill"
        case "street food", "streetfood":
            return "cart.fill"
        default:
            return "fork.knife"
        }
    }
    
    private func filterIconColor(for filter: String) -> Color {
        if filter == "All" {
            return .gray
        }
        
        switch filter.lowercased() {
        case "spicy":
            return .red
        case "healthy", "vegetarian-friendly", "vegetarian":
            return .green
        case "desserts", "sweet":
            return .orange
        case "seafood":
            return .blue
        case "meat":
            return .brown
        default:
            return .gray
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


// MARK: - Deal Home Card Component (Android Design - Text Only)
struct DealHomeCard: View {
    let deal: Deal
    
    var body: some View {
        ZStack {
            // Dark blue/black background matching Android
            Color(hex: "#1F2937")
            
            VStack(alignment: .leading, spacing: 12) {
                // SPECIAL OFFER text at top
                Text("SPECIAL OFFER")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .tracking(0.5)
                
                // Large discount percentage in yellow
                Text("\(deal.discountPercentage)% OFF")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: "#F59E0B"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 0)
                
                // Category/Item name in white
                Text(deal.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Restaurant name in yellow
                Text(deal.restaurantName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "#F59E0B"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(width: 260, height: 160)
        .fixedSize(horizontal: true, vertical: true)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
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


