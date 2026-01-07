import SwiftUI

// Ensure TokenManager is accessible

// MARK: - Brand Colors (Matching Android)
private let AppBackgroundLight = Color(hex: 0xFFF6F6F9)
private let AppCardBackground = Color(hex: 0xFFF7F7F7)
private let AppCartButtonYellow = Color(hex: 0xFFFFC107)
private let AppDarkText = Color(hex: 0xFF1F2A37)
private let AppPrimaryRed = Color(hex: 0xFFEF4444)
private let OffWhiteBeige = Color(hex: 0xFFFFF8F0)

// MARK: - Dynamic Menu Screen (100% matching Android design)
struct DynamicMenuScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: DynamicMenuViewModel
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @State private var selectedItemForCustomization: MenuItemResponse?
    @State private var selectedItemDeal: Deal?
    @State private var showCustomizationOverlay: Bool = false
    
    let professionalId: String
    let onBackClick: () -> Void
    let onCartClick: () -> Void
    let onConfirmOrderClick: () -> Void
    
    init(professionalId: String, userId: String, onBackClick: @escaping () -> Void, onCartClick: @escaping () -> Void, onConfirmOrderClick: @escaping () -> Void = {}) {
        self.professionalId = professionalId
        self.onBackClick = onBackClick
        self.onCartClick = onCartClick
        self.onConfirmOrderClick = onConfirmOrderClick
        let authToken = TokenManager.shared.getAccessToken() ?? ""
        _viewModel = StateObject(wrappedValue: DynamicMenuViewModel(professionalId: professionalId, authToken: authToken))
        // Note: cartViewModel is now passed via @EnvironmentObject from AppNavigation
    }
    
    var body: some View {
        let currentCartItemCount: Int = {
            if case .success(let cart) = cartViewModel.uiState {
                return cart.items.count
            }
            return 0
        }()
        
        let currentTotalPrice: Double = {
            if case .success(let cart) = cartViewModel.uiState {
                return cart.items.reduce(0.0) { $0 + ($1.calculatedPrice * Double($1.quantity)) }
            }
            return 0.0
        }()
        
        return ZStack {
            AppBackgroundLight.ignoresSafeArea()
            
        VStack(spacing: 0) {
            // Top App Bar
            MenuTopAppBar(
                    restaurantName: "Chili's",
                onBackClick: onBackClick,
                onCartClick: onCartClick,
                    cartItemCount: currentCartItemCount
                )
            
            // Content based on state
            if viewModel.isLoading {
                    LoadingMenuView()
            } else if let errorMessage = viewModel.errorMessage {
                    ErrorMenuView(message: errorMessage, onRetry: {
                    viewModel.fetchMenu()
                })
            } else if viewModel.filteredMenuItems.isEmpty {
                    EmptyCategoryState(categoryName: viewModel.selectedCategory?.rawValue ?? "this category")
            } else {
                    MenuContentGrid(
                    items: viewModel.filteredMenuItems,
                        availableCategories: viewModel.availableCategories,
                        selectedCategory: viewModel.selectedCategory,
                        viewModel: viewModel,
                        onCategorySelected: { category in
                            viewModel.selectCategory(category)
                        },
                    onItemTap: { item in
                        // DEBUG: Log item selection
                        print("🔵 [DynamicMenu] Item tapped: \(item.name) (ID: \(item.id))")
                        print("🔵 [DynamicMenu] Item has \(item.ingredients.count) ingredients")
                        print("🔵 [DynamicMenu] Item has \(item.options.count) options")
                        print("🔵 [DynamicMenu] Item price: \(item.price)")
                        
                        // Get applicable deal for this item
                        let applicableDeal = viewModel.getApplicableDeal(for: item)
                        
                        // Set item and deal first, then show overlay after a tiny delay to ensure state is updated
                        selectedItemForCustomization = item
                        selectedItemDeal = applicableDeal
                        print("🔵 [DynamicMenu] selectedItemForCustomization set to: \(item.name)")
                        if let deal = applicableDeal {
                            print("🔵 [DynamicMenu] Deal applied: \(deal.discountPercentage)% off")
                        }
                        
                        DispatchQueue.main.async {
                            print("🔵 [DynamicMenu] Setting showCustomizationOverlay = true")
                            showCustomizationOverlay = true
                        }
                    }
                )
            }
                
                // Bottom Bar
                MenuBottomBar(
                    totalOrderPrice: currentTotalPrice,
                    onConfirmClick: onConfirmOrderClick
                )
            }
            
            // Custom overlay (manual ZStack implementation)
            if showCustomizationOverlay, let item = selectedItemForCustomization {
                // Dimmed Background
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showCustomizationOverlay = false
                            selectedItemForCustomization = nil
                        }
                    }
                    .transition(.opacity)
                    .zIndex(100)
                
                // Content Sheet
                CustomizationOverlayWrapper(
                    item: item,
                    deal: selectedItemDeal,
                    cartViewModel: cartViewModel,
                    onDismiss: {
                        withAnimation {
                            selectedItemForCustomization = nil
                            selectedItemDeal = nil
                            showCustomizationOverlay = false
                        }
                    },
                    onConfirmAddToCart: { menuItem, quantity, ingredientsToRemove, selectedOptions, ingredientIntensities in
                        
                        // Calculate base price with deal discount if applicable
                        var basePrice = menuItem.price
                        if let deal = selectedItemDeal {
                            let discount = Double(deal.discountPercentage) / 100.0
                            basePrice = basePrice * (1.0 - discount)
                        }
                        
                        let optionsPrice = selectedOptions.reduce(0.0) { $0 + $1.price }
                        let unitPrice = basePrice + optionsPrice
                        
                        let keptIngredients = menuItem.ingredients
                            .filter { !ingredientsToRemove.contains($0.name) }
                            .map { ingredient in
                                let intensityValueFloat = ingredient.supportsIntensity == true ? (ingredientIntensities[ingredient.name] ?? 0.5) : 0.0
                                return CartIngredientDto(
                                    name: ingredient.name,
                                    isDefault: ingredient.isDefault,
                                    intensityType: ingredient.supportsIntensity ? ingredient.intensityType : nil,
                                    intensityColor: ingredient.supportsIntensity ? ingredient.intensityColor : nil,
                                    intensityValue: ingredient.supportsIntensity ? Double(intensityValueFloat) : nil
                                )
                            }
                        
                        let cartOptions = selectedOptions.map { CartOptionDto(name: $0.name, price: $0.price) }
                        
                        let request = AddToCartRequest(
                            menuItemId: menuItem.id,
                            quantity: quantity,
                            name: menuItem.name,
                            chosenIngredients: keptIngredients,
                            chosenOptions: cartOptions,
                            calculatedPrice: unitPrice
                        )
                        
                        cartViewModel.addItem(request: request, professionalId: menuItem.professionalId)
                        
                        withAnimation {
                            selectedItemForCustomization = nil
                            showCustomizationOverlay = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            cartViewModel.loadCart(professionalId: menuItem.professionalId)
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(101)
                .padding(.top, 100) // Create transparent top area
            }
        }
        .onAppear {
            cartViewModel.loadCart(professionalId: professionalId)
            // Ensure menu is loaded (in case it failed during init)
            if !viewModel.isLoading && viewModel.menuItems.isEmpty && viewModel.errorMessage == nil {
                viewModel.fetchMenu()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: showCustomizationOverlay) { newValue in
             if newValue {
                 print("🟢 [DynamicMenu] Overlay shown")
             }
        }
    }
}

// MARK: - Customization Overlay Wrapper
struct CustomizationOverlayWrapper: View {
    let item: MenuItemResponse?
    let deal: Deal?
    let cartViewModel: CartViewModel
    let onDismiss: () -> Void
    let onConfirmAddToCart: (MenuItemResponse, Int, Set<String>, Set<OptionDto>, [String: Float]) -> Void
    
    init(item: MenuItemResponse?, deal: Deal?, cartViewModel: CartViewModel, onDismiss: @escaping () -> Void, onConfirmAddToCart: @escaping (MenuItemResponse, Int, Set<String>, Set<OptionDto>, [String: Float]) -> Void) {
        self.item = item
        self.deal = deal
        self.cartViewModel = cartViewModel
        self.onDismiss = onDismiss
        self.onConfirmAddToCart = onConfirmAddToCart
        
        // DEBUG: Log wrapper initialization
        if let item = item {
            print("🟡 [CustomizationOverlayWrapper] Initialized with item: \(item.name) (ID: \(item.id))")
            print("🟡 [CustomizationOverlayWrapper] Ingredients: \(item.ingredients.count)")
            print("🟡 [CustomizationOverlayWrapper] Options: \(item.options.count)")
        } else {
            print("🔴 [CustomizationOverlayWrapper] Initialized with nil item!")
        }
    }
    
    var body: some View {
        Group {
            if let item = item {
                ItemCustomizationOverlay(
                    item: item,
                    deal: deal,
                    onDismiss: onDismiss,
                    onConfirmAddToCart: onConfirmAddToCart
                )
            } else {
                // Fallback: Show error or close overlay if item is nil
                ZStack {
                    Color.white.ignoresSafeArea()
                    VStack {
                        Text("Error: Item not found")
                            .foregroundColor(.red)
                        Button("Close") {
                            onDismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Menu Top App Bar
struct MenuTopAppBar: View {
    let restaurantName: String
    let onBackClick: () -> Void
    let onCartClick: () -> Void
    let cartItemCount: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBackClick) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.backward")
                        Text("Back to search")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(AppDarkText)
                }
                
                Spacer()
                
                // Cart button with badge
                    ZStack {
                    Button(action: onCartClick) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppDarkText)
                    }
                        
                        if cartItemCount > 0 {
                        Text("\(cartItemCount > 99 ? "99+" : "\(cartItemCount)")")
                                .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppDarkText)
                                .padding(4)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(AppCartButtonYellow)
                                .clipShape(Circle())
                            .offset(x: 14, y: -14)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Restaurant info
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: 0xFFE5E7EB))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(restaurantName.prefix(1))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppDarkText)
                    )
                
                Text(restaurantName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppDarkText)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            Divider()
                .background(Color(hex: 0xFFE5E7EB))
        }
        .background(Color.white)
    }
}

// MARK: - Menu Content Grid (2 columns)
struct MenuContentGrid: View {
    let items: [MenuItemResponse]
    let availableCategories: [Category]
    let selectedCategory: Category?
    let viewModel: DynamicMenuViewModel
    let onCategorySelected: (Category?) -> Void
    let onItemTap: (MenuItemResponse) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Category Selector
                if !availableCategories.isEmpty {
                    CategorySelectorHorizontal(
                        categories: availableCategories,
                        selectedCategory: selectedCategory,
                        onCategorySelected: onCategorySelected
                    )
                }
                
                // Items Grid (2 columns)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(items, id: \.id) { item in
                        let applicableDeal = viewModel.getApplicableDeal(for: item)
                        UserMenuItemCard(item: item, deal: applicableDeal, onAddClick: {
                            onItemTap(item)
                        })
                    }
                }
                .padding(.horizontal, 16)
                
                // Bottom spacing for bottom bar
                Spacer()
                    .frame(height: 100)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Category Selector Horizontal
struct CategorySelectorHorizontal: View {
    let categories: [Category]
    let selectedCategory: Category?
    let onCategorySelected: (Category?) -> Void
    
    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            onClick: {
                            onCategorySelected(selectedCategory == category ? nil : category)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let onClick: () -> Void
    
    var categoryEmoji: String {
        switch category {
        case .burger: return "🍔"
        case .pizza: return "🍕"
        case .pasta: return "🍝"
        case .mexican: return "🌮"
        case .sushi: return "🍣"
        case .asian: return "🥡"
        case .seafood: return "🦞"
        case .chicken: return "🍗"
        case .sandwiches: return "🥪"
        case .soups: return "🍲"
        case .salad: return "🥗"
        case .dessert: return "🍰"
        case .drinks: return "🥤"
        default: return "🍽️"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(isSelected ? AppCartButtonYellow : Color.white)
                    .frame(width: 80, height: 110)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(spacing: 12) {
                    // Icon background circle
            Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                .overlay(
                    Text(categoryEmoji)
                                .font(.system(size: 36))
                        )
                    
                    // Category name
                    Text(category.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? AppDarkText : Color(hex: 0xFF9A9A9D))
                        .lineLimit(1)
                        .frame(width: 70)
                }
                .padding(.vertical, 12)
            }
        }
        .onTapGesture(perform: onClick)
    }
}

// MARK: - Menu Item Card (2-column grid style)
struct UserMenuItemCard: View {
    let item: MenuItemResponse
    let deal: Deal?
    let onAddClick: () -> Void
    
    var imageUrl: String? {
        return BaseUrlProvider.shared.getFullImageUrl(item.image)
    }
    
    // Calculate discounted price if deal exists
    var originalPrice: Double {
        item.price
    }
    
    var discountedPrice: Double? {
        guard let deal = deal else { return nil }
        let discount = Double(deal.discountPercentage) / 100.0
        return originalPrice * (1.0 - discount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Area (Edge-to-edge)
            ZStack(alignment: .topTrailing) {
                if let urlString = imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure, .empty:
                            Color(hex: 0xFFE5E7EB)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                } else {
                    Color(hex: 0xFFE5E7EB)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // Preparation Time Badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    Text("\(item.preparationTimeMinutes ?? 15) min")
                        .font(.system(size: 11, weight: .bold)) // Slightly bigger text
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: 0xFF4CAF50))
                .cornerRadius(4)
                .padding(8) // Margin from top-right edge
            }
            
            // Content Area
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(item.name)
                    .font(.system(size: 17, weight: .bold)) // Bigger font
                    .foregroundColor(AppDarkText)
                    .lineLimit(1)
                    .padding(.top, 4)
                
                // Description
                Text(item.description ?? "Delicious item")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Spacer().frame(height: 12) // More separation
                
                // Price and Add Button
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let discountedPrice = discountedPrice {
                            // Show old price (strikethrough) and new price
                            HStack(spacing: 4) {
                                Text(String(format: "%.2f TND", originalPrice))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gray)
                                    .strikethrough()
                                
                                Text(String(format: "%.2f TND", discountedPrice))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppCartButtonYellow)
                            }
                        } else {
                            // Show regular price
                            Text(String(format: "%.2f TND", originalPrice))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppCartButtonYellow)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onAddClick) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36) // Bigger button
                            .background(AppCartButtonYellow)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(12) // Padding for text content only
        }
        .background(Color.white)
        .cornerRadius(16) // Rounded corners for the whole card
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3) // Softer, deeper shadow
        .onTapGesture(perform: onAddClick)
    }
}

// MARK: - Menu Bottom Bar
struct MenuBottomBar: View {
    let totalOrderPrice: Double
    let onConfirmClick: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total Price:")
                    .font(.system(size: 18))
                    .foregroundColor(AppDarkText)
                
                Spacer()
                
                Text(String(format: "%.2f TND", totalOrderPrice))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppCartButtonYellow)
            }
            
            Button(action: onConfirmClick) {
                HStack {
                    Text("Confirm Order")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppDarkText)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.forward")
                        .foregroundColor(AppDarkText)
                }
                .frame(height: 56)
                .padding(.horizontal, 24)
                .background(AppCartButtonYellow)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(AppCardBackground)
    }
}

// MARK: - Loading View
struct LoadingMenuView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(AppCartButtonYellow)
                .scaleEffect(1.5)
            Text("Loading menu...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 16)
            Spacer()
        }
    }
}

// MARK: - Error View
struct ErrorMenuView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Error loading menu")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppDarkText)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                onRetry()
            }
            .foregroundColor(AppDarkText)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppCartButtonYellow)
            .cornerRadius(8)
            Spacer()
        }
    }
}

// MARK: - Empty Category State
struct EmptyCategoryState: View {
    let categoryName: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            // Lottie animation placeholder (using emoji for now)
            Text("📦")
                .font(.system(size: 150))
            
            Text("No items in \(categoryName.replacingOccurrences(of: "_", with: " "))")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppDarkText)
            
            Text("Try selecting a different category")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Item Customization Overlay (Full Screen)
struct ItemCustomizationOverlay: View {
    let item: MenuItemResponse
    let deal: Deal?
    let onDismiss: () -> Void
    let onConfirmAddToCart: (MenuItemResponse, Int, Set<String>, Set<OptionDto>, [String: Float]) -> Void
    
    @State private var quantity = 1
    @State private var ingredientsToRemove: Set<String> = []
    @State private var selectedOptions: Set<OptionDto> = []
    @State private var ingredientIntensities: [String: Float] = [:]
    @State private var showAISuggestions = false
    
    init(item: MenuItemResponse, deal: Deal?, onDismiss: @escaping () -> Void, onConfirmAddToCart: @escaping (MenuItemResponse, Int, Set<String>, Set<OptionDto>, [String: Float]) -> Void) {
        self.item = item
        self.deal = deal
        self.onDismiss = onDismiss
        self.onConfirmAddToCart = onConfirmAddToCart
        
        // Initialize ingredient intensities with default value 0.5 (middle) for ingredients that support intensity
        var initialIntensities: [String: Float] = [:]
        for ingredient in item.ingredients {
            if ingredient.supportsIntensity == true {
                initialIntensities[ingredient.name] = 0.5 // Default to middle (0.5)
            }
        }
        
        // DEBUG: Log overlay initialization
        print("🟠 [ItemCustomizationOverlay] Initialized with item: \(item.name) (ID: \(item.id))")
        print("🟠 [ItemCustomizationOverlay] Price: \(item.price)")
        print("🟠 [ItemCustomizationOverlay] Ingredients count: \(item.ingredients.count)")
        item.ingredients.forEach { ingredient in
            print("🟠 [ItemCustomizationOverlay]   - \(ingredient.name) (default: \(ingredient.isDefault), intensity: \(ingredient.supportsIntensity ?? false))")
        }
        print("🟠 [ItemCustomizationOverlay] Options count: \(item.options.count)")
        item.options.forEach { option in
            print("🟠 [ItemCustomizationOverlay]   - \(option.name) (price: \(option.price))")
        }
        print("🟠 [ItemCustomizationOverlay] Initial intensities: \(initialIntensities)")
        
        // Initialize the state with default values
        _ingredientIntensities = State(initialValue: initialIntensities)
    }
    
    var imageUrl: String? {
        return BaseUrlProvider.shared.getFullImageUrl(item.image)
    }
    
    var unitPrice: Double {
        // Apply deal discount to base price if deal exists
        var basePrice = item.price
        if let deal = deal {
            let discount = Double(deal.discountPercentage) / 100.0
            basePrice = basePrice * (1.0 - discount)
        }
        
        let optionsPrice = selectedOptions.reduce(0.0) { $0 + $1.price }
        return basePrice + optionsPrice
    }
    
    var originalUnitPrice: Double {
        let optionsPrice = selectedOptions.reduce(0.0) { $0 + $1.price }
        return item.price + optionsPrice
    }
    
    var finalTotal: Double {
        unitPrice * Double(quantity)
    }
    
    var body: some View {

        VStack(spacing: 0) {
            // Main content starts directly - wrapper handles sheet position
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Circular image
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                    .frame(width: 200, height: 200)
                                    .shadow(color: Color.black.opacity(0.2), radius: 12)
                                
                                if let urlString = imageUrl, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        case .failure, .empty:
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .frame(width: 200, height: 200)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "photo")
                                        .font(.system(size: 80))
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.top, 16)
                            
                            // Quantity selector and price
                            VStack(spacing: 6) {
                                QuantitySelectorRedesigned(
                                    quantity: $quantity
                                )
                                
                                if deal != nil {
                                    // Show old and new price when deal is applied
                                    VStack(spacing: 2) {
                                        Text(String(format: "%.2f TND", originalUnitPrice))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .strikethrough()
                                        
                                        Text(String(format: "%.2f TND", unitPrice))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(AppCartButtonYellow)
                                    }
                                } else {
                                    // Show regular price
                                    Text(String(format: "%.2f TND", unitPrice))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(AppDarkText)
                                }
                            }
                            
                            // Product title
                            Text(item.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppDarkText)
                                .padding(.top, 16)
                            
                            // Description
                            Text(item.description ?? "Fresh ingredients with premium quality. Customize your order to your taste preferences.")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 12)
                            
                            // Ask AI for Suggestions Button
                            Button(action: {
                                showAISuggestions = true
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Ask AI for Suggestions")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: 0xFFFF6B35))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 20)
                            
                            // Ingredients Customizer (with intensity sliders)
                            IngredientsCustomizer(
                                ingredients: item.ingredients,
                                ingredientsToRemove: $ingredientsToRemove,
                                ingredientIntensities: $ingredientIntensities
                            )
                            
                            // Options Customizer
                    if !item.options.isEmpty {
                                OptionsCustomizer(
                            options: item.options,
                            selectedOptions: $selectedOptions
                        )
                    }
                            
                            // Bottom spacing for fixed footer
                            Spacer()
                                .frame(height: 120)
                }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
            }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(OffWhiteBeige)
                .clipShape(TopRoundedRectangle(radius: 40))
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: -5)
            
                // Fixed footer with total and Add to Cart button
            CustomizationFooter(
                total: finalTotal,
                onAddToCart: {
                        onConfirmAddToCart(item, quantity, ingredientsToRemove, selectedOptions, ingredientIntensities)
                }
            )
            }
            .fullScreenCover(isPresented: $showAISuggestions) {
                AISuggestionsDialog(isPresented: $showAISuggestions, itemId: item.id)
            }
    }
}




// MARK: - Quantity Selector Redesigned
struct QuantitySelectorRedesigned: View {
    @Binding var quantity: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Minus button - Yellow square
            Button(action: {
                if quantity > 1 {
                    quantity -= 1
                }
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 24))
                    .foregroundColor(AppDarkText)
                    .frame(width: 48, height: 48)
                    .background(AppCartButtonYellow)
                    .cornerRadius(8)
            }
            .disabled(quantity <= 1)
            .opacity(quantity <= 1 ? 0.5 : 1.0)
            
            // Quantity number - White background
            Text("\(quantity)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppDarkText)
                .frame(width: 60, height: 48)
            
            // Plus button - Yellow square
            Button(action: {
                quantity += 1
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(AppCartButtonYellow)
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Ingredients Customizer (with intensity sliders)
struct IngredientsCustomizer: View {
    let ingredients: [IngredientDto]
    @Binding var ingredientsToRemove: Set<String>
    @Binding var ingredientIntensities: [String: Float]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customize Ingredients")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppDarkText)
            
            Text("Tap to remove • Adjust intensity with slider")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            ForEach(ingredients, id: \.name) { ingredient in
                let isSelected = !ingredientsToRemove.contains(ingredient.name)
                
                if ingredient.supportsIntensity == true {
                    // Ingredient with intensity slider
                    IntensityIngredientCard(
                    ingredient: ingredient,
                        isSelected: isSelected,
                        intensityValue: Binding(
                            get: { ingredientIntensities[ingredient.name] ?? 0.5 },
                            set: { ingredientIntensities[ingredient.name] = $0 }
                        ),
                    onToggle: {
                            if ingredientsToRemove.contains(ingredient.name) {
                                ingredientsToRemove.remove(ingredient.name)
                        } else {
                                ingredientsToRemove.insert(ingredient.name)
                            }
                        }
                    )
                } else {
                    // Regular ingredient without intensity
                    RegularIngredientCard(
                        ingredient: ingredient,
                        isSelected: isSelected,
                        onToggle: {
                            if ingredientsToRemove.contains(ingredient.name) {
                                ingredientsToRemove.remove(ingredient.name)
                            } else {
                                ingredientsToRemove.insert(ingredient.name)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Intensity Ingredient Card
struct IntensityIngredientCard: View {
    let ingredient: IngredientDto
    let isSelected: Bool
    @Binding var intensityValue: Float
    let onToggle: () -> Void
    
    var intensityColor: Color {
        getIntensityColor(for: ingredient.intensityType, hexColor: ingredient.intensityColor, value: intensityValue)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Ingredient name row
        HStack {
                // Yellow dot indicator
                Circle()
                    .fill(isSelected ? AppCartButtonYellow : Color(hex: 0xFFD1D5DB))
                    .frame(width: 8, height: 8)
            
            Text(ingredient.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? AppDarkText : .gray)
            
            Spacer()
                
                if isSelected {
                    Text("Tap to remove")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
        }
            }
            .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
            
            // Intensity slider
            if isSelected {
                HStack(spacing: 12) {
                    CustomIntensitySlider(
                        value: $intensityValue,
                        activeColor: intensityColor,
                        inactiveColor: intensityColor.opacity(0.3)
                    )
                    
                    // Intensity icons on the right with bouncing animation
                    HStack(spacing: 6) {
                        if intensityValue >= 0.3 {
                            AnimatedBouncingIcon(
                                emoji: getIntensityEmoji(for: ingredient.intensityType),
                                intensity: intensityValue,
                                delay: 0.0
                            )
                        }
                        if intensityValue >= 0.8 {
                            AnimatedBouncingIcon(
                                emoji: getIntensityEmoji(for: ingredient.intensityType),
                                intensity: intensityValue,
                                delay: 0.1
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(isSelected ? AppCardBackground : Color(hex: 0xFFF5F5F5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.clear : Color(hex: 0xFFE0E0E0), lineWidth: isSelected ? 0 : 1)
        )
        .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 2)
    }
}

// MARK: - Regular Ingredient Card
struct RegularIngredientCard: View {
    let ingredient: IngredientDto
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(isSelected ? AppPrimaryRed : Color(hex: 0xFFD1D5DB))
                .frame(width: 8, height: 8)
            
            Text(ingredient.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? AppDarkText : .gray)
            
            Spacer()
            
            if isSelected {
                Text("Tap to remove")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(isSelected ? AppCardBackground : Color(hex: 0xFFF5F5F5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.clear : Color(hex: 0xFFE0E0E0), lineWidth: isSelected ? 0 : 1)
        )
        .shadow(color: isSelected ? Color.black.opacity(0.08) : Color.clear, radius: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Custom Intensity Slider
struct CustomIntensitySlider: View {
    @Binding var value: Float
    let activeColor: Color
    let inactiveColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Inactive track (background)
                RoundedRectangle(cornerRadius: 8)
                    .fill(inactiveColor)
                    .frame(height: 6)
                
                // Active track (filled portion)
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeColor)
                    .frame(width: geometry.size.width * CGFloat(value), height: 6)
                
                // Vertical bar thumb
                RoundedRectangle(cornerRadius: 2)
                    .fill(activeColor)
                    .frame(width: 3, height: 20)
                    .offset(x: geometry.size.width * CGFloat(value) - 1.5)
                
                // Large invisible touch area for better interaction
                Color.clear
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = Float(max(0, min(1, gesture.location.x / geometry.size.width)))
                                value = newValue
                            }
                    )
            }
        }
        .frame(height: 44) // Larger frame for better touch target
    }
}

// MARK: - Options Customizer
struct OptionsCustomizer: View {
    let options: [OptionDto]
    @Binding var selectedOptions: Set<OptionDto>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Extra Options (Add-ons)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppDarkText)
            
            Text("Add extra sauces or toppings")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            ForEach(options, id: \.name) { option in
                OptionCard(
                    option: option,
                    isSelected: selectedOptions.contains(option),
                    onToggle: {
                        if selectedOptions.contains(option) {
                            selectedOptions.remove(option)
                        } else {
                            selectedOptions.insert(option)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Option Card
struct OptionCard: View {
    let option: OptionDto
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            )) {
            Text(option.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDarkText)
            }
            .tint(AppCartButtonYellow)
            
            Spacer()
            
            Text(String(format: "+%.2f TND", option.price))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppCartButtonYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppCardBackground)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Customization Footer
struct CustomizationFooter: View {
    let total: Double
    let onAddToCart: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Total")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppDarkText)
                
                Spacer()
                
                Text(String(format: "%.2f TND", total))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppCartButtonYellow)
            }
            
            Button(action: onAddToCart) {
                Text("Add To Cart")
                        .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                    .background(AppCartButtonYellow)
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(OffWhiteBeige)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -5)
    }
}

// MARK: - Animated Bouncing Icon
struct AnimatedBouncingIcon: View {
    let emoji: String
    let intensity: Float
    let delay: Double
    
    @State private var bounceOffset: CGFloat = 0
    @State private var previousIntensity: Float = 0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Text(emoji)
            .font(.system(size: intensity >= 0.8 ? 22 : 20))
            .offset(y: bounceOffset)
            .onChange(of: intensity) { newValue in
                // Calculate base offset based on intensity
                let baseOffset = -CGFloat(newValue) * 6
                
                // If intensity changed significantly, trigger a bounce
                if abs(newValue - previousIntensity) > 0.03 {
                    isAnimating = true
                    
                    // Bounce up
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.5).delay(delay)) {
                        bounceOffset = baseOffset - 6
                    }
                    
                    // Bounce back to base position
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + delay) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            bounceOffset = baseOffset
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isAnimating = false
                            // Start continuous subtle animation
                            startContinuousAnimation(baseOffset: baseOffset)
                        }
                    }
                } else {
                    // Smooth transition for small changes
                    if !isAnimating {
                        withAnimation(.easeOut(duration: 0.15)) {
                            bounceOffset = baseOffset
                        }
                    }
                }
                
                previousIntensity = newValue
            }
            .onAppear {
                previousIntensity = intensity
                let baseOffset = -CGFloat(intensity) * 6
                bounceOffset = baseOffset
                startContinuousAnimation(baseOffset: baseOffset)
            }
    }
    
    private func startContinuousAnimation(baseOffset: CGFloat) {
        // Continuous subtle bounce animation
        let bounceAmount: CGFloat = 3
        withAnimation(
            Animation.easeInOut(duration: 0.7 + Double(intensity) * 0.3)
                .repeatForever(autoreverses: true)
                .delay(delay)
        ) {
            bounceOffset = baseOffset - bounceAmount
        }
    }
}

// MARK: - Helper Functions for Intensity
func getIntensityColor(for type: IntensityType?, hexColor: String?, value: Float) -> Color {
    // If hex color provided, parse and adjust by intensity
    if let hex = hexColor {
        if let color = Color(hexString: hex) {
            return color.opacity(Double(0.5 + value * 0.5))
        }
    }
    
    // Default colors based on type
    switch type {
    case .coffee:
        return Color(red: 0.2 + Double(value) * 0.2, green: 0.15 + Double(value) * 0.1, blue: 0.1 + Double(value) * 0.1)
    case .harissa, .chili:
        return Color(red: 0.6 + Double(value) * 0.4, green: max(0, 0.2 - Double(value) * 0.2), blue: max(0, 0.2 - Double(value) * 0.2))
    case .sauce:
        return Color(red: 0.9 + Double(value) * 0.1, green: 0.6 + Double(value) * 0.2, blue: max(0, 0.2 - Double(value) * 0.1))
    case .spice:
        return Color(red: 0.8 + Double(value) * 0.2, green: 0.5 + Double(value) * 0.2, blue: max(0, 0.2 - Double(value) * 0.1))
    case .sugar:
        return Color(red: 0.95 + Double(value) * 0.05, green: 0.9 + Double(value) * 0.1, blue: 0.7 + Double(value) * 0.2)
    case .salt:
        return Color(red: 0.85 + Double(value) * 0.1, green: 0.85 + Double(value) * 0.1, blue: 0.9 + Double(value) * 0.1)
    case .pepper:
        return Color(red: 0.2 + Double(value) * 0.2, green: 0.2 + Double(value) * 0.2, blue: 0.2 + Double(value) * 0.2)
    case .garlic:
        return Color(red: 0.95 + Double(value) * 0.05, green: 0.95 + Double(value) * 0.05, blue: 0.9 + Double(value) * 0.1)
    case .lemon:
        return Color(red: 0.95 + Double(value) * 0.05, green: 0.9 + Double(value) * 0.1, blue: max(0, 0.4 - Double(value) * 0.2))
    default:
        return Color(red: 0.6 + Double(value) * 0.2, green: 0.6 + Double(value) * 0.2, blue: 0.6 + Double(value) * 0.2)
    }
}

func getIntensityEmoji(for type: IntensityType?) -> String {
    switch type {
    case .coffee: return "☕"
    case .harissa, .chili: return "🌶️"
    case .sauce: return "🍯"
    case .spice: return "🌿"
    case .sugar: return "🍬"
    case .salt: return "🧂"
    case .pepper: return "🫚"
    case .garlic: return "🧄"
    case .lemon: return "🍋"
    default: return "⭐"
    }
}


extension Color {
    init?(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Top Rounded Rectangle Shape
struct TopRoundedRectangle: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - OptionDto Hashable Extension
extension OptionDto: Hashable {
    static func == (lhs: OptionDto, rhs: OptionDto) -> Bool {
        lhs.name == rhs.name && lhs.price == rhs.price
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(price)
    }
}
