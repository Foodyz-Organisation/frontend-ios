import SwiftUI

// MARK: - Shopping Cart Screen
struct ShoppingCartScreen: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: CartViewModel  // Use shared CartViewModel
    
    @State private var selectedItem: CartItemResponse?
    @State private var showItemDetails = false
    
    let professionalId: String
    let onCheckout: (CartViewModel) -> Void
    
    init(professionalId: String, userId: String, onCheckout: @escaping (CartViewModel) -> Void) {
        self.professionalId = professionalId
        self.onCheckout = onCheckout
        // No longer creating our own CartViewModel
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
            viewModel.loadCart()
        }
        .sheet(isPresented: $showItemDetails) {
            if let item = selectedItem {
                CartItemDetailsSheet(item: item, onDismiss: {
                    showItemDetails = false
                })
            }
        }
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
        .padding(. horizontal, 16)
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
            LazyVStack(spacing: 10) {
                ForEach(Array(cart.items.enumerated()), id: \.element.id) { index, item in
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
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
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
        if let image = item.image, !image.isEmpty {
            return "http://127.0.0.1:3000/\(image)"
        }
        return ""
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
                .clipShape(RoundedCornerShape(corners: .allCorners, radius: 8))
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    
                    Text(String(format: "$%.2f", totalPrice))
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
            .clipShape(RoundedCornerShape(corners: .allCorners, radius: 12))
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
                VStack(alignment: .leading, spacing: 8) {
                    if !item.chosenIngredients.isEmpty {
                        CartDetailsList(
                            title: "Ingredients",
                            details: item.chosenIngredients.map { 
                                "\($0.name) (\($0.isDefault ? "Default" : "Added"))" 
                            }
                        )
                    }
                    
                    if !item.chosenOptions.isEmpty {
                        CartDetailsList(
                            title: "Options",
                            details: item.chosenOptions.map { 
                                "\($0.name) (+$\(String(format: "%.2f", $0.price)))" 
                            }
                        )
                    }
                }
                .padding( .horizontal, 16)
                .padding(.vertical, 8)
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
                
                Text(String(format: "$%.2f", subtotal))
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
                    .clipShape(RoundedCornerShape(corners: .allCorners, radius: 12))
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
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(item.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !item.chosenIngredients.isEmpty {
                        CartDetailsList(
                            title: "Ingredients",
                            details: item.chosenIngredients.map { 
                                "\($0.name) (\($0.isDefault ? "Default" : "Added"))" 
                            }
                        )
                    }
                    
                    if !item.chosenOptions.isEmpty {
                        CartDetailsList(
                            title: "Options",
                            details: item.chosenOptions.map { 
                                "\($0.name) (+$\(String(format: "%.2f", $0.price)))" 
                            }
                        )
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Quantity:")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text("\(item.quantity)")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    HStack {
                        Text("Price:")
                            .font(.system(size: 16, weight: .semibold))
                        Spacer()
                        Text(String(format: "$%.2f", item.calculatedPrice))
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Button("Close") {
                onDismiss()
            }
            .foregroundColor(.white)
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

// MARK: - Rounded Corner Shape
struct RoundedCornerShape: Shape {
    enum Corners {
        case allCorners
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    let corners: Corners
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch corners {
        case .allCorners:
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: radius, height: radius))
        default:
            path.addRect(rect)
        }
        
        return path
    }
}
