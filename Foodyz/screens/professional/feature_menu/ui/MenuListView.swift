import SwiftUI
import WebKit

let BASE_URL = "http://localhost:3000/"

// MARK: - MenuItemManagementScreen (Container View)
struct MenuItemManagementScreen: View {
    @ObservedObject var viewModel: MenuViewModel
    var professionalId: String
    @Binding var path: NavigationPath // BINDING TO THE ROOT NAVIGATION STACK
    
    @State private var selectedCategory: Category? = nil
    @State private var allCategories: [Category] = []
    
    var body: some View {
        // ❌ REMOVED: NavigationView is provided by AppNavigation/NavigationStack
        VStack(spacing: 0) {
            // Category Selector - Always show all categories
            ProfessionalCategorySelector(
                categories: allCategories,
                selectedCategory: selectedCategory,
                onCategorySelected: { category in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedCategory = category
                    }
                }
            )
            
            // Content
            ZStack(alignment: .bottom) { // Changed to .bottom alignment for ZStack
                content
                    .padding(.bottom, 100) // Add padding for bottom bar
                
                // Floating button (Keep distinct or integrate? User didn't ask to remove/move, but bottom bar might overlap)
                // The floating button is in the content ZStack. 
                // Let's move floating button to be above bottom bar.
                floatingButton
                    .padding(.bottom, 80) // Adjust padding to be above bottom bar

                // MARK: - Bottom Bar
                ProfessionalBottomBar(
                    path: $path,
                    selectedTab: "menu",
                    openDrawer: { withAnimation { showingDrawer = true } }
                )
                
                // Drawer Overlay (Required since we added BottomBar with drawer callback)
                if showingDrawer {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showingDrawer = false } }
                    
                    ProfessionalDrawer(
                        onCloseDrawer: { withAnimation { showingDrawer = false } },
                        navigateTo: { route in
                            if route == "logout" {
                                // Handle logout if needed, otherwise just close
                                 path.removeLast(path.count)
                                 path.append(Screen.login)
                                 TokenManager.shared.clearAllData()
                            } else if route == "profile" {
                                path.append(Screen.professionalProfile(professionalId))
                            }
                            withAnimation { showingDrawer = false }
                        }
                    )
                    .transition(.move(edge: .trailing))
                    .animation(.easeInOut, value: showingDrawer)
                }
            }
        }
        .navigationTitle("Menu Items")
        .navigationBarBackButtonHidden(true) // ❌ Hide Back Button
        .onAppear {
            // Initialize all categories
            allCategories = Category.allCases.sorted { $0.rawValue < $1.rawValue }
            
            // Get the real access token from TokenManager
            guard let accessToken = TokenManager.shared.getAccessToken() else {
                viewModel.menuListUiState = .error("Vous devez être connecté pour voir le menu")
                return
            }
            
            // Validate professionalId is not empty
            guard !professionalId.isEmpty else {
                viewModel.menuListUiState = .error("ID professionnel invalide")
                return
            }
            
            viewModel.fetchGroupedMenu(professionalId: professionalId, token: accessToken)
        }
    }
    
    @State private var showingDrawer = false // Added state for drawer

    @ViewBuilder
    private var content: some View {
        switch viewModel.menuListUiState {
        case .idle:
            Text("Idle state")
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            Text("Error: \(message)").foregroundColor(.red)
        case .success(let groupedMenu):
            if groupedMenu.isEmpty {
                EmptyMenuStateView()
            } else {
                MenuSectionList(
                    viewModel: viewModel,
                    path: $path,
                    professionalId: professionalId,
                    groupedMenu: filteredMenu(from: groupedMenu),
                    selectedCategory: selectedCategory
                )
            }
        }
    }
    
    // Helper function to filter menu based on selected category
    private func filteredMenu(from groupedMenu: [String: [MenuItemResponse]]) -> [String: [MenuItemResponse]] {
        if let selectedCategory = selectedCategory {
            // Show only selected category, or empty if it doesn't exist
            let categoryKey = selectedCategory.rawValue
            return groupedMenu[categoryKey] != nil 
                ? [categoryKey: groupedMenu[categoryKey]!]
                : [:]
        } else {
            // Show all categories
            return groupedMenu
        }
    }

    private var floatingButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // NAVIGATE TO CREATE SCREEN
                    path.append(Screen.createMenuItem(professionalId))
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.yellow)
                        .clipShape(Circle())
                }
                .padding()
            }
        }
    }
}

// MARK: - Professional Category Selector
struct ProfessionalCategorySelector: View {
    let categories: [Category]
    let selectedCategory: Category?
    let onCategorySelected: (Category?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // "All" option
                    ProfessionalCategoryChip(
                        category: nil,
                        isSelected: selectedCategory == nil,
                        onClick: {
                            onCategorySelected(nil)
                        }
                    )
                    
                    ForEach(categories, id: \.self) { category in
                        ProfessionalCategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            onClick: {
                                if selectedCategory == category {
                                    onCategorySelected(nil)
                                } else {
                                    onCategorySelected(category)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            Divider()
        }
        .background(Color.white)
    }
}

// MARK: - Professional Category Chip
struct ProfessionalCategoryChip: View {
    let category: Category?
    let isSelected: Bool
    let onClick: () -> Void
    
    var categoryEmoji: String {
        guard let category = category else {
            return "📋" // All items icon
        }
        
        switch category {
        // Core Categories
        case .burger: return "🍔"
        case .pizza: return "🍕"
        case .pasta: return "🍝"
        case .mexican: return "🌮"
        case .sushi: return "🍣"
        case .asian: return "🥢"
        case .indian: return "🍛"
        case .mideast: return "🥙"
        case .seafood: return "🦞"
        case .chicken: return "🍗"
        case .sandwiches: return "🥪"
        case .soups: return "🍲"
        
        // Dietary and Flavor
        case .salad: return "🥗"
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .healthy: return "🥑"
        case .glutenFree: return "🌾"
        case .spicy: return "🌶️"
        
        // Item Type and Occasion
        case .breakfast: return "🥐"
        case .dessert: return "🍰"
        case .drinks: return "🥤"
        case .kidsMenu: return "🍟"
        case .familyMeal: return "👨‍👩‍👧‍👦"
        }
    }
    
    var categoryLabel: String {
        category?.rawValue ?? "All"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isSelected ? Color(hex: 0xFFFFC107).opacity(0.2) : Color(hex: 0xFFF5F5F5))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(categoryEmoji)
                        .font(.system(size: 28))
                )
            
            Text(categoryLabel)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color(hex: 0xFFFFC107) : Color(hex: 0xFF1F2A37))
                .lineLimit(1)
                .frame(maxWidth: 60)
        }
        .onTapGesture(perform: onClick)
    }
}

// MARK: - Empty Menu State
struct EmptyMenuStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            EmptyCategoryAnimationView(category: nil)
                .frame(width: 300, height: 300)
            Text("No items yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.secondary)
            Text("Click + to create one")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: 0xFFFBEA).ignoresSafeArea())
    }
}

// MARK: - Empty Category Animation View
struct EmptyCategoryAnimationView: View {
    let category: Category?
    
    var body: some View {
        VStack(spacing: 20) {
            // Load and display Lottie animation
            LottieAnimationView(filename: "empty")
                .frame(width: 250, height: 250)
            
            if let category = category {
                Text("No items in \(category.rawValue)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            } else {
                Text("No items available")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Lottie Animation View Wrapper
struct LottieAnimationView: UIViewRepresentable {
    let filename: String
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        // Try multiple paths to find the animation file
        var animationData: Data?
        var foundPath: String?
        
        // Path 1: Try from bundle with subdirectory
        if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "screens/professional/feature_menu/viewmodel/animation"),
           let data = try? Data(contentsOf: url) {
            animationData = data
            foundPath = "bundle subdirectory"
            print("✅ Found animation at: \(url.path)")
        }
        // Path 2: Try from bundle with animation subdirectory
        else if let url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "animation"),
                let data = try? Data(contentsOf: url) {
            animationData = data
            foundPath = "bundle animation"
            print("✅ Found animation at: \(url.path)")
        }
        // Path 3: Try direct in bundle
        else if let url = Bundle.main.url(forResource: filename, withExtension: "json"),
                let data = try? Data(contentsOf: url) {
            animationData = data
            foundPath = "bundle root"
            print("✅ Found animation at: \(url.path)")
        }
        // Path 4: Try from project directory (for development/debugging)
        else if let projectPath = Bundle.main.resourcePath {
            let possiblePaths = [
                "\(projectPath)/screens/professional/feature_menu/viewmodel/animation/\(filename).json",
                "\(projectPath)/animation/\(filename).json",
                "\(projectPath)/\(filename).json"
            ]
            
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                    animationData = data
                    foundPath = "file system"
                    print("✅ Found animation at: \(path)")
                    break
                }
            }
        }
        
        if animationData == nil {
            print("❌ Animation file '\(filename).json' not found in bundle or file system")
        }
        
        if let data = animationData {
            // Use WKWebView to display Lottie animation via CDN
            let webView = WKWebView()
            webView.backgroundColor = .clear
            webView.isOpaque = false
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            
            // Use base64 encoding for the JSON to avoid escaping issues
            let base64Json = data.base64EncodedString()
            
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                <script src="https://cdnjs.cloudflare.com/ajax/libs/bodymovin/5.12.2/lottie.min.js" integrity="sha512-jEnuDt6jfecCjthQAJ+ed0MTVA++5ZKmlUcmDGBv2vUI/REn6FuIdixLNnQT+vKusE2hhTk2is3c2vvh06HNxw==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>
                <style>
                    * {
                        margin: 0;
                        padding: 0;
                        box-sizing: border-box;
                    }
                    body {
                        margin: 0;
                        padding: 0;
                        background: transparent;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        width: 100vw;
                        overflow: hidden;
                    }
                    #lottie-container {
                        width: 100%;
                        height: 100%;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                    }
                    .loading {
                        color: #999;
                        text-align: center;
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    }
                </style>
            </head>
            <body>
                <div id="lottie-container">
                    <div class="loading">Loading animation...</div>
                </div>
                <script>
                    (function() {
                        function loadAnimation() {
                            try {
                                // Decode base64 JSON
                                var jsonBase64 = '\(base64Json)';
                                var jsonString = atob(jsonBase64);
                                var animationData = JSON.parse(jsonString);
                                
                                // Check if Lottie is loaded
                                if (typeof lottie === 'undefined') {
                                    console.log('Waiting for Lottie to load...');
                                    setTimeout(loadAnimation, 100);
                                    return;
                                }
                                
                                console.log('Loading Lottie animation...');
                                var animation = lottie.loadAnimation({
                                    container: document.getElementById('lottie-container'),
                                    renderer: 'svg',
                                    loop: true,
                                    autoplay: true,
                                    animationData: animationData
                                });
                                
                                animation.addEventListener('data_ready', function() {
                                    console.log('Animation ready');
                                });
                                
                                animation.addEventListener('DOMLoaded', function() {
                                    console.log('Animation DOM loaded');
                                });
                                
                            } catch(e) {
                                console.error('Lottie animation error:', e);
                                document.getElementById('lottie-container').innerHTML = '<div class="loading">Animation Error: ' + e.message + '</div>';
                            }
                        }
                        
                        // Start loading
                        if (document.readyState === 'loading') {
                            document.addEventListener('DOMContentLoaded', loadAnimation);
                        } else {
                            loadAnimation();
                        }
                    })();
                </script>
            </body>
            </html>
            """
            
            webView.loadHTMLString(html, baseURL: nil)
            
            containerView.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                webView.topAnchor.constraint(equalTo: containerView.topAnchor),
                webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        } else {
            // Fallback placeholder if file not found
            let placeholderView = UIView()
            let label = UILabel()
            label.text = "📦"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 80)
            
            // Add pulsing animation
            let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
            pulseAnimation.duration = 1.5
            pulseAnimation.fromValue = 0.9
            pulseAnimation.toValue = 1.1
            pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            pulseAnimation.autoreverses = true
            pulseAnimation.repeatCount = .greatestFiniteMagnitude
            label.layer.add(pulseAnimation, forKey: "pulse")
            
            placeholderView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor)
            ])
            containerView.addSubview(placeholderView)
            placeholderView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                placeholderView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                placeholderView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                placeholderView.topAnchor.constraint(equalTo: containerView.topAnchor),
                placeholderView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

// MARK: - MenuSectionList
struct MenuSectionList: View {
    @ObservedObject var viewModel: MenuViewModel
    @Binding var path: NavigationPath // REQUIRED: Path to pass down
    var professionalId: String
    var groupedMenu: [String: [MenuItemResponse]]
    var selectedCategory: Category?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // If filtering by a category and it's empty, show empty animation
                if let selectedCategory = selectedCategory,
                   let items = groupedMenu[selectedCategory.rawValue],
                   items.isEmpty {
                    EmptyCategoryAnimationView(category: selectedCategory)
                        .frame(height: 400)
                } else if groupedMenu.isEmpty && selectedCategory != nil {
                    // Selected category doesn't exist in menu
                    EmptyCategoryAnimationView(category: selectedCategory!)
                        .frame(height: 400)
                } else {
                    // Show menu items
                    ForEach(groupedMenu.keys.sorted(), id: \.self) { categoryKey in
                        VStack(alignment: .leading, spacing: 12) {
                            // Category Header with Icon
                            if let category = Category(rawValue: categoryKey) {
                                HStack(spacing: 8) {
                                    Text(getCategoryEmoji(for: category))
                                        .font(.system(size: 24))
                                    Text(categoryKey)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            } else {
                                Text(categoryKey)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 8)
                            }
                            
                            Divider()
                                .padding(.horizontal, 16)

                            // Menu Items - Display in grid (2 columns)
                            let items = groupedMenu[categoryKey] ?? []
                            if items.isEmpty {
                                EmptyCategoryAnimationView(category: Category(rawValue: categoryKey) ?? .burger)
                                    .frame(height: 300)
                                    .padding(.horizontal, 16)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 12),
                                    GridItem(.flexible(), spacing: 12)
                                ], spacing: 16) {
                                    ForEach(items, id: \.id) { item in
                                        MenuItemCard(viewModel: viewModel,
                                                     path: $path,
                                                     item: item,
                                                     professionalId: professionalId)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(hex: 0xFFFBEA).ignoresSafeArea())
    }
    
    // Helper function to get category emoji
    private func getCategoryEmoji(for category: Category) -> String {
        switch category {
        case .burger: return "🍔"
        case .pizza: return "🍕"
        case .pasta: return "🍝"
        case .mexican: return "🌮"
        case .sushi: return "🍣"
        case .asian: return "🥢"
        case .indian: return "🍛"
        case .mideast: return "🥙"
        case .seafood: return "🦞"
        case .chicken: return "🍗"
        case .sandwiches: return "🥪"
        case .soups: return "🍲"
        case .salad: return "🥗"
        case .vegetarian: return "🥬"
        case .vegan: return "🌱"
        case .healthy: return "🥑"
        case .glutenFree: return "🌾"
        case .spicy: return "🌶️"
        case .breakfast: return "🥐"
        case .dessert: return "🍰"
        case .drinks: return "🥤"
        case .kidsMenu: return "🍟"
        case .familyMeal: return "👨‍👩‍👧‍👦"
        }
    }
}

// MARK: - MenuItemCard
struct MenuItemCard: View {
    @ObservedObject var viewModel: MenuViewModel
    @Binding var path: NavigationPath
    var item: MenuItemResponse
    var professionalId: String
    
    // Calculate number of adjustable items (ingredients with intensity support + options)
    var adjustableCount: Int {
        let adjustableIngredients = item.ingredients.filter { $0.supportsIntensity }.count
        return adjustableIngredients + item.options.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon Section - Stylized menu icon
            ZStack {
                // Yellow menu/tablet background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: 0xFFFFC107).opacity(0.2))
                    .frame(height: 120)
                
                VStack(spacing: 8) {
                    // Cloche icon
                    Image(systemName: "bell.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                        .offset(y: -10)
                    
                    // Menu/document icon
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: 0xFFFFC107))
                    
                    // Hand/thumbs up icon
                    Image(systemName: "hand.thumbsup.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .offset(x: 30, y: -20)
                }
            }
            
            // Item Name
            Text(item.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(2)
            
            // Adjustable indicator
            if adjustableCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("\(adjustableCount) adjustable")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // Price Section
            VStack(alignment: .leading, spacing: 2) {
                Text("Starting From")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                
                Text(String(format: "%.3f TND", item.price))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0xFFFF6F00))
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    let navItem = MenuNavigationItem(professionalId: professionalId, itemId: item.id)
                    path.append(Screen.editMenuItem(navItem))
                }) {
                    Text("Edit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    guard let accessToken = TokenManager.shared.getAccessToken() else {
                        return
                    }
                    viewModel.deleteMenuItem(id: item.id, professionalId: professionalId, token: accessToken)
                }) {
                    Text("Delete")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

