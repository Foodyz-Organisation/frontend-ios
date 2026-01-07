import SwiftUI

// MARK: - Shopping Cart Screen
struct ShoppingCartScreen: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: CartViewModel
    
    @State private var selectedItem: CartItemResponse?
    @State private var showItemDetails = false
    
    let professionalId: String
    let onCheckout: (CartViewModel) -> Void
    
    init(professionalId: String, userId: String, onCheckout: @escaping (CartViewModel) -> Void) {
        self.professionalId = professionalId
        self.onCheckout = onCheckout
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            CartTopBar(
                itemCount: viewModel.itemCount,
                onBackClick: { dismiss() }
            )
            
            // Content based on state
            switch viewModel.uiState {
            case .loading:
                LoadingCartView()
                
            case .error(let message):
                ErrorCartView(message: message, onRetry: {
                    viewModel.loadCart()
                })
                
            case .empty:
                EmptyCartView()
                
            case .success(let cart):
                CartContentView(
                    cart: cart,
                    onRemove: { index in
                        viewModel.removeItem(index: index)
                    },
                    onQuantityChange: { index, quantity in
                        viewModel.updateQuantity(index: index, newQuantity: quantity)
                    },
                    onItemTap: { item in
                        selectedItem = item
                        showItemDetails = true
                    }
                )
            }
            
            // Checkout Bar
            if case .success = viewModel.uiState {
                CheckoutBar(
                    subtotal: viewModel.totalPrice,
                    onCheckout: {
                        onCheckout(viewModel)
                    }
                )
            }
        }
        .background(Color(hex: 0xFFF9FAFB))
        .onAppear {
            print("📱 [ShoppingCartScreen] onAppear - Loading cart...")
            print("📱 [ShoppingCartScreen] Current UI state: \(String(describing: viewModel.uiState))")
            print("📱 [ShoppingCartScreen] Item count: \(viewModel.itemCount)")
            viewModel.loadCart()
        }
        .onChange(of: viewModel.uiState) { newState in
            print("📱 [ShoppingCartScreen] UI state changed: \(String(describing: newState))")
            switch newState {
            case .loading:
                print("📱 [ShoppingCartScreen] State: Loading...")
            case .empty:
                print("📱 [ShoppingCartScreen] State: Empty cart")
            case .success(let cart):
                print("📱 [ShoppingCartScreen] State: Success - \(cart.items.count) items")
            case .error(let message):
                print("📱 [ShoppingCartScreen] State: Error - \(message)")
            }
        }
        .sheet(isPresented: $showItemDetails) {
            if let item = selectedItem {
                CartItemDetailsSheet(item: item, onDismiss: {
                    showItemDetails = false
                })
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Cart Top Bar
struct CartTopBar: View {
    let itemCount: Int
    let onBackClick: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBackClick) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
            }
            
            Text("Your Cart (\(itemCount))")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
    }
}

// MARK: - Cart Content View
struct CartContentView: View {
    let cart: CartResponse
    let onRemove: (Int) -> Void
    let onQuantityChange: (Int, Int) -> Void
    let onItemTap: (CartItemResponse) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(cart.items.enumerated()), id: \.offset) { index, item in
                    CartItemCardView(
                        item: item,
                        index: index,
                        onRemove: onRemove,
                        onQuantityChange: onQuantityChange,
                        onItemTap: onItemTap
                    )
                }
                
                Spacer().frame(height: 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Cart Item Card
struct CartItemCardView: View {
    let item: CartItemResponse
    let index: Int
    let onRemove: (Int) -> Void
    let onQuantityChange: (Int, Int) -> Void
    let onItemTap: (CartItemResponse) -> Void
    
    @State private var isExpanded = false
    
    var totalPrice: Double {
        item.calculatedPrice * Double(item.quantity)
    }
    
    var imageUrl: String {
        guard let image = item.image, !image.isEmpty else { return "" }
        return BaseUrlProvider.shared.getFullImageUrl(image) ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main card content
            HStack(spacing: 12) {
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
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    
                    Text(String(format: "%.3f TND", totalPrice))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFFFFC107))
                }
                
                Spacer()
                
                // Actions
                VStack(alignment: .trailing, spacing: 8) {
                    Button(action: { onRemove(index) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: 0xFF9CA3AF))
                    }
                    
                    Spacer()
                    
                    // Quantity controls
                    HStack(spacing: 8) {
                        Button(action: {
                            if item.quantity > 1 {
                                onQuantityChange(index, item.quantity - 1)
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                                .frame(width: 20, height: 20)
                        }
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: 0xFF1F2A37))
                            .frame(minWidth: 20)
                        
                        Button(action: {
                            onQuantityChange(index, item.quantity + 1)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: 0xFFFFC107))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .frame(height: 70)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                onItemTap(item)
            }
            .onLongPressGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    if !item.chosenIngredients.isEmpty {
                        Text("Ingredients:")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(hex: 0xFF1F2A37))
                            .padding(.top, 4)
                        
                        // Show ingredients with intensity sliders if available
                        ForEach(item.chosenIngredients, id: \.name) { ingredient in
                            if ingredient.intensityType != nil, let intensityValue = ingredient.intensityValue {
                                CartIngredientWithIntensityRow(ingredient: ingredient, intensityValue: intensityValue)
                            } else {
                                HStack {
                                    Circle()
                                        .fill(Color(hex: 0xFFFFC107))
                                        .frame(width: 6, height: 6)
                                    Text(ingredient.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(.gray)
                                    if ingredient.isDefault {
                                        Text("(Default)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.leading, 8)
                            }
                        }
                    }
                    
                    if !item.chosenOptions.isEmpty {
                        Divider()
                            .padding(.vertical, 4)
                        
                        CartDetailsList(
                            title: "Options",
                            details: item.chosenOptions.map { 
                                "\($0.name) (+\(String(format: "%.3f", $0.price)) TND)" 
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: 0xFFF3F4F6))
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Cart Details List
struct CartDetailsList: View {
    let title: String
    let details: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(title):")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            ForEach(details, id: \.self) { detail in
                Text("• \(detail)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Cart Ingredients With Intensity
struct CartIngredientsWithIntensity: View {
    let ingredients: [CartIngredientDto]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            ForEach(ingredients, id: \.name) { ingredient in
                if let intensityType = ingredient.intensityType, let intensityValue = ingredient.intensityValue {
                    CartIngredientWithIntensityCard(
                        ingredient: ingredient,
                        intensityValue: Float(intensityValue)
                    )
                } else {
                    // Regular ingredient without intensity
                    HStack {
                        Circle()
                            .fill(Color(hex: 0xFFFFC107))
                            .frame(width: 6, height: 6)
                        Text(ingredient.name)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        if ingredient.isDefault {
                            Text("(Default)")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.leading, 8)
                }
            }
        }
    }
}

// MARK: - Cart Ingredient With Intensity Row (for expanded card)
struct CartIngredientWithIntensityRow: View {
    let ingredient: CartIngredientDto
    let intensityValue: Double
    
    var intensityColor: Color {
        getIntensityColorForCart(
            type: ingredient.intensityType,
            hexColor: ingredient.intensityColor,
            value: Float(intensityValue)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: 0xFFFFC107))
                    .frame(width: 6, height: 6)
                Text(ingredient.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                if ingredient.isDefault {
                    Text("(Default)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                CartIntensitySlider(
                    value: Float(intensityValue),
                    activeColor: intensityColor,
                    inactiveColor: intensityColor.opacity(0.3)
                )
                
                // Intensity icons
                HStack(spacing: 6) {
                    if intensityValue >= 0.3 {
                        CartBouncingIcon(
                            emoji: getIntensityEmojiForCart(type: ingredient.intensityType),
                            intensity: Float(intensityValue),
                            delay: 0.0
                        )
                    }
                    if intensityValue >= 0.8 {
                        CartBouncingIcon(
                            emoji: getIntensityEmojiForCart(type: ingredient.intensityType),
                            intensity: Float(intensityValue),
                            delay: 0.1
                        )
                    }
                }
            }
        }
        .padding(.leading, 8)
    }
}

// MARK: - Cart Ingredient With Intensity Card (for details sheet)
struct CartIngredientWithIntensityCard: View {
    let ingredient: CartIngredientDto
    let intensityValue: Float
    
    var intensityColor: Color {
        getIntensityColorForCart(
            type: ingredient.intensityType,
            hexColor: ingredient.intensityColor,
            value: intensityValue
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: 0xFFFFC107))
                    .frame(width: 6, height: 6)
                Text(ingredient.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                if ingredient.isDefault {
                    Text("(Default)")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            
            HStack(spacing: 12) {
                CartIntensitySlider(
                    value: intensityValue,
                    activeColor: intensityColor,
                    inactiveColor: intensityColor.opacity(0.3)
                )
                
                // Intensity icons
                HStack(spacing: 6) {
                    if intensityValue >= 0.3 {
                        CartBouncingIcon(
                            emoji: getIntensityEmojiForCart(type: ingredient.intensityType),
                            intensity: intensityValue,
                            delay: 0.0
                        )
                    }
                    if intensityValue >= 0.8 {
                        CartBouncingIcon(
                            emoji: getIntensityEmojiForCart(type: ingredient.intensityType),
                            intensity: intensityValue,
                            delay: 0.1
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0xFFF9FAFB))
        .cornerRadius(12)
    }
}

// MARK: - Cart Options List
struct CartOptionsList: View {
    let options: [CartOptionDto]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Options:")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            ForEach(options, id: \.name) { option in
                Text("• \(option.name) (+\(String(format: "%.3f", option.price)) TND)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
            }
        }
    }
}

// MARK: - Cart Intensity Slider (Read-only display)
struct CartIntensitySlider: View {
    let value: Float
    let activeColor: Color
    let inactiveColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Inactive track
                RoundedRectangle(cornerRadius: 8)
                    .fill(inactiveColor)
                    .frame(height: 6)
                
                // Active track
                RoundedRectangle(cornerRadius: 8)
                    .fill(activeColor)
                    .frame(width: geometry.size.width * CGFloat(value), height: 6)
                
                // Vertical bar thumb
                RoundedRectangle(cornerRadius: 2)
                    .fill(activeColor)
                    .frame(width: 3, height: 20)
                    .offset(x: geometry.size.width * CGFloat(value) - 1.5)
            }
        }
        .frame(height: 20)
    }
}

// MARK: - Cart Bouncing Icon
struct CartBouncingIcon: View {
    let emoji: String
    let intensity: Float
    let delay: Double
    
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: intensity >= 0.8 ? 18 : 16))
            .offset(y: bounceOffset)
            .onAppear {
                let bounceAmount = CGFloat(intensity) * 3
                withAnimation(
                    Animation.easeInOut(duration: 0.7 + Double(intensity) * 0.3)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    bounceOffset = -bounceAmount
                }
            }
    }
}

// MARK: - Helper Functions
func getIntensityEmojiForCart(type: IntensityType?) -> String {
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

func getIntensityColorForCart(type: IntensityType?, hexColor: String?, value: Float) -> Color {
    // If hex color provided, parse and adjust by intensity
    if let hex = hexColor, let color = Color(hexString: hex) {
        return color.opacity(Double(0.5 + value * 0.5))
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

// MARK: - Checkout Bar
struct CheckoutBar: View {
    let subtotal: Double
    let onCheckout: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Subtotal:")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(String(format: "%.3f TND", subtotal))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
            }
            
            Button(action: onCheckout) {
                Text("Proceed to Checkout")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: 0xFFFFC107))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: -2)
    }
}

// MARK: - Loading Cart View
struct LoadingCartView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading cart...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 16)
            Spacer()
        }
    }
}

// MARK: - Error Cart View
struct ErrorCartView: View {
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

// MARK: - Empty Cart View
struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: 0xFFD1D5DB))
            Text("Your Cart is Empty!")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            Text("Time to find some delicious food.")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Cart Item Details Sheet
struct CartItemDetailsSheet: View {
    let item: CartItemResponse
    let onDismiss: () -> Void
    
    var imageUrl: URL? {
        guard let image = item.image, !image.isEmpty else { return nil }
        guard let fullUrl = BaseUrlProvider.shared.getFullImageUrl(image) else { return nil }
        return URL(string: fullUrl)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // Item Image
                    if let url = imageUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
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
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Color(hex: 0xFFE5E7EB)
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    }
                    
                    // Item Name
                    Text(item.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Ingredients with Intensity
                        if !item.chosenIngredients.isEmpty {
                            CartIngredientsWithIntensity(ingredients: item.chosenIngredients)
                        }
                        
                        // Options
                        if !item.chosenOptions.isEmpty {
                            CartOptionsList(options: item.chosenOptions)
                        }
                        
                        Divider()
                            .background(Color(hex: 0xFFE5E7EB))
                        
                        // Quantity and Price
                        HStack {
                            Text("Quantity:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                            Spacer()
                            Text("\(item.quantity)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                        }
                        
                        HStack {
                            Text("Total Price:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                            Spacer()
                            Text(String(format: "%.3f TND", item.calculatedPrice * Double(item.quantity)))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: 0xFFFFC107))
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 20)
            }
            
            // Close Button
            Button("Close") {
                onDismiss()
            }
            .foregroundColor(Color(hex: 0xFF1F2A37))
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: 0xFFFFC107))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(hex: 0xFFF9FAFB))
    }
}

// MARK: - Color Extension (using existing extension from other files)
