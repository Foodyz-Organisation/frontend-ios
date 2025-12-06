import SwiftUI

// MARK: - Dynamic Menu Screen
struct DynamicMenuScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: DynamicMenuViewModel
    @StateObject private var cartViewModel: CartViewModel
    
    @State private var selectedItemForCustomization: MenuItemResponse?
    
    let professionalId: String
    let onBackClick: () -> Void
    let onCartClick: () -> Void
    
    init(professionalId: String, userId: String, onBackClick: @escaping () -> Void, onCartClick: @escaping () -> Void) {
        self.professionalId = professionalId
        self.onBackClick = onBackClick
        self.onCartClick = onCartClick
        _viewModel = StateObject(wrappedValue: DynamicMenuViewModel(professionalId: professionalId))
        _cartViewModel = StateObject(wrappedValue: CartViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top App Bar
            MenuTopAppBar(
                restaurantName: "Restaurant Menu",
                onBackClick: onBackClick,
                onCartClick: onCartClick,
                cartItemCount: cartViewModel.itemCount
            )
            
            // Category Selector
            if !viewModel.availableCategories.isEmpty {
                CategorySelector(
                    categories: viewModel.availableCategories,
                    selectedCategory: viewModel.selectedCategory,
                    onCategorySelected: { category in
                        viewModel.selectCategory(category)
                    }
                )
            }
            
            // Content based on state
            if viewModel.isLoading {
                LoadingView()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage, onRetry: {
                    viewModel.fetchMenu()
                })
            } else if viewModel.filteredMenuItems.isEmpty {
                EmptyStateView(categoryName: viewModel.selectedCategory?.rawValue ?? "this category")
            } else {
                MenuItemsList(
                    items: viewModel.filteredMenuItems,
                    onItemTap: { item in
                        selectedItemForCustomization = item
                    }
                )
            }
        }
        .background(Color(hex: 0xFFF9FAFB))
        .onAppear {
            cartViewModel.loadCart()
        }
        .sheet(item: $selectedItemForCustomization) { item in
            ItemCustomizationSheet(
                item: item,
                onDismiss: { selectedItemForCustomization = nil },
                onAddToCart: { menuItem, quantity, removedIngredients, selectedOptions in
                    // Build cart request
                    let basePrice = menuItem.price
                    let optionsPrice = selectedOptions.reduce(0.0) { $0 + $1.price }
                    let unitPrice = basePrice + optionsPrice
                    
                    // Get ingredients to keep (not removed)
                    let keptIngredients = menuItem.ingredients.filter { ingredient in
                        !removedIngredients.contains(ingredient.name)
                    }.map { ingredient in
                        CartIngredientDto(name: ingredient.name, isDefault: ingredient.isDefault)
                    }
                    
                    // Map selected options to cart options
                    let cartOptions = selectedOptions.map { option in
                        CartOptionDto(name: option.name, price: option.price)
                    }
                    
                    // Create add to cart request
                    let request = AddToCartRequest(
                        menuItemId: menuItem.id,
                        quantity: quantity,
                        name: menuItem.name,
                        chosenIngredients: keptIngredients,
                        chosenOptions: cartOptions,
                        calculatedPrice: unitPrice
                    )
                    
                    // Add to cart
                    cartViewModel.addItem(request: request)
                    selectedItemForCustomization = nil
                }
            )
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
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                }
                
                Spacer()
                
                // Cart button
                Button(action: onCartClick) {
                    ZStack {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: 0xFF1F2A37))
                        
                        if cartItemCount > 0 {
                            Text("\(cartItemCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 12, y: -12)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            HStack {
                Circle()
                    .fill(Color(hex: 0xFFE5E7EB))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(restaurantName.prefix(1))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: 0xFF1F2A37))
                    )
                
                Text(restaurantName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            Divider()
        }
        .background(Color.white)
    }
}

// MARK: - Category Selector
struct CategorySelector: View {
    let categories: [Category]
    let selectedCategory: Category?
    let onCategorySelected: (Category?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
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

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let onClick: () -> Void
    
    var categoryEmoji: String {
        switch category {
        case .burger: return "🍔"
        case .pizza: return "🍕"
        case .seafood: return "🦞"
        case .salad: return "🥗"
        case .spicy: return "🌶️"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(isSelected ? Color(hex: 0xFFEF4444).opacity(0.1) : Color(hex: 0xFFFEF3F2))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(categoryEmoji)
                        .font(.system(size: 32))
                )
            
            Text(category.rawValue)
                .font(.system(size: 12, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? Color(hex: 0xFFEF4444) : Color(hex: 0xFF1F2A37))
        }
        .onTapGesture(perform: onClick)
    }
}

// MARK: - Menu Items List
struct MenuItemsList: View {
    let items: [MenuItemResponse]
    let onItemTap: (MenuItemResponse) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    UserMenuItemCard(item: item) {
                        onItemTap(item)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - User Menu Item Card
struct UserMenuItemCard: View {
    let item: MenuItemResponse
    let onAddClick: () -> Void
    
    var imageUrl: String {
        if item.image.isEmpty {
            return ""
        }
        return "http://127.0.0.1:3000/\(item.image)"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Image
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(hex: 0xFFE5E7EB)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16, corners: [.topLeft, .bottomLeft]))
            
            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .lineLimit(2)
                
                if let description = item.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(String(format: "%.2f DT", item.price))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Add Button
            Button(action: onAddClick) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(width: 48, height: 48)
                    .background(Color(hex: 0xFFFFC107))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
        }
        .frame(height: 120)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
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
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                onRetry()
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(hex: 0xFFFFC107))
            .cornerRadius(8)
            Spacer()
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let categoryName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: 0xFFD1D5DB))
            Text("No items in \(categoryName)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            Text("Try selecting a different category")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Item Customization Sheet
struct ItemCustomizationSheet: View {
    let item: MenuItemResponse
    let onDismiss: () -> Void
    let onAddToCart: (MenuItemResponse, Int, Set<String>, Set<OptionDto>) -> Void
    
    @State private var quantity = 1
    @State private var removedIngredients: Set<String> = []
    @State private var selectedOptions: Set<OptionDto> = []
    
    var finalTotal: Double {
        let optionsPrice = selectedOptions.reduce(0.0) { $0 + $1.price }
        return (item.price + optionsPrice) * Double(quantity)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CustomizationHeader(item: item, onDismiss: onDismiss)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Quantity Selector
                    QuantitySelector(quantity: $quantity)
                    
                    // Ingredients
                    if !item.ingredients.isEmpty {
                        IngredientsSection(
                            ingredients: item.ingredients,
                            removedIngredients: $removedIngredients
                        )
                    }
                    
                    // Options
                    if !item.options.isEmpty {
                        OptionsSection(
                            options: item.options,
                            selectedOptions: $selectedOptions
                        )
                    }
                }
                .padding(16)
            }
            
            // Footer
            CustomizationFooter(
                total: finalTotal,
                onAddToCart: {
                    onAddToCart(item, quantity, removedIngredients, selectedOptions)
                }
            )
        }
    }
}

// MARK: - Customization Header
struct CustomizationHeader: View {
    let item: MenuItemResponse
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                
                Text(String(format: "%.2f DT", item.price))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: 0xFFEF4444))
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .background(Color(hex: 0xFFF9FAFB))
    }
}

// MARK: - Quantity Selector
struct QuantitySelector: View {
    @Binding var quantity: Int
    
    var body: some View {
        HStack {
            Text("Quantity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Spacer()
            
            Button(action: { if quantity > 1 { quantity -= 1 } }) {
                Image(systemName: "minus")
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2)
            }
            
            Text("\(quantity)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
                .frame(minWidth: 40)
            
            Button(action: { quantity += 1 }) {
                Image(systemName: "plus")
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(width: 40, height: 40)
                    .background(Color(hex: 0xFFFFC107))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2)
            }
        }
    }
}

// MARK: - Ingredients Section
struct IngredientsSection: View {
    let ingredients: [IngredientDto]
    @Binding var removedIngredients: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customize Ingredients")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Text("Remove any ingredients you don't like")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            ForEach(ingredients, id: \.name) { ingredient in
                IngredientRow(
                    ingredient: ingredient,
                    isRemoved: removedIngredients.contains(ingredient.name),
                    onToggle: {
                        if removedIngredients.contains(ingredient.name) {
                            removedIngredients.remove(ingredient.name)
                        } else {
                            removedIngredients.insert(ingredient.name)
                        }
                    }
                )
            }
        }
    }
}

struct IngredientRow: View {
    let ingredient: IngredientDto
    let isRemoved: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isRemoved ? "circle" : "checkmark.circle.fill")
                .foregroundColor(isRemoved ? .gray : Color(hex: 0xFFEF4444))
            
            Text(ingredient.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture(perform: onToggle)
    }
}

// MARK: - Options Section
struct OptionsSection: View {
    let options: [OptionDto]
    @Binding var selectedOptions: Set<OptionDto>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extra Options (Add-ons)")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Text("Add extra sauces or toppings")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            ForEach(options, id: \.name) { option in
                OptionRow(
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

struct OptionRow: View {
    let option: OptionDto
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundColor(isSelected ? Color(hex: 0xFFFFC107) : .gray)
            
            Text(option.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Spacer()
            
            Text(String(format: "+%.2f DT", option.price))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0xFFEF4444))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
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
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                
                Spacer()
                
                Text(String(format: "%.2f DT", total))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: 0xFFFFC107))
            }
            
            Button(action: onAddToCart) {
                HStack {
                    Text("Add to Cart")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    
                    Image(systemName: "arrow.forward")
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: 0xFFFFC107))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Helper Extension for Rounded Corners
extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.init(cornerRadius: cornerRadius)
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
