import SwiftUI

private let PrimaryColor = Color(hex: 0xFFFFC107)
private let BackgroundLight = Color(hex: 0xFFF9FAFB)
private let CardBackground = Color.white
private let DarkText = Color(hex: 0xFF1F2937)
private let LightGrayText = Color(hex: 0xFF9CA3AF)
private let ErrorColor = Color(hex: 0xFFEF4444)
private let SuccessColor = Color(hex: 0xFF10B981)
private let WarningColor = Color(hex: 0xFFF59E0B)
private let InfoColor = Color(hex: 0xFF3B82F6)

// MARK: - Order Details Screen
struct OrderDetailsScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OrderViewModel()
    
    let orderId: String
    let userId: String
    
    @State private var showDeleteDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            OrderDetailsTopBar(
                showDeleteButton: isProfessionalView && currentOrder != nil && (currentOrder?.status == .confirmed || currentOrder?.status == .pending),
                onBackClick: { dismiss() },
                onDeleteClick: { showDeleteDialog = true }
            )
            
            // Content
            if viewModel.isLoading {
                LoadingOrderDetailsView()
            } else if let order = currentOrder {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Header Section
                        OrderHeaderCard(order: order)
                        
                        // Status Update Section (For Professionals Only)
                        if isProfessionalView {
                            OrderStatusUpdateCard(
                                order: order,
                                onStatusChange: { newStatus in
                                    viewModel.updateOrderStatus(orderId: order._id, status: newStatus) { success in
                                        // singleOrder will be updated automatically in ViewModel
                                    }
                                }
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // Items Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Items")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(DarkText)
                                .padding(.horizontal, 16)
                            
                            ForEach(order.items, id: \.id) { item in
                                OrderItemDetailCard(item: item)
                                    .padding(.horizontal, 16)
                            }
                        }
                        
                        // Summary Section
                        OrderSummaryCard(order: order)
                            .padding(.horizontal, 16)
                        
                        Spacer()
                            .frame(height: 16)
                    }
                    .padding(.vertical, 16)
                }
                .background(BackgroundLight)
            } else {
                ErrorOrderDetailsView(message: "Order not found")
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(BackgroundLight)
        .onAppear {
            // Load order by ID instead of loading all user orders
            // This works for both users and professionals
            viewModel.loadOrderById(orderId: orderId)
        }
        .alert("Delete Order", isPresented: $showDeleteDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let order = currentOrder {
                    viewModel.deleteOrder(
                        orderId: order._id,
                        onSuccess: {
                            dismiss()
                        },
                        onError: { error in
                            // Error will be shown via ViewModel
                        }
                    )
                }
            }
        } message: {
            if let order = currentOrder {
                Text("Are you sure you want to delete order #\(String(order._id.suffix(8)))? This action cannot be undone.")
            }
        }
    }
    
    private var currentOrder: OrderResponse? {
        // Use singleOrder instead of filtering from orders array
        viewModel.singleOrder
    }
    
    // Check if current user is a professional
    private var isProfessionalView: Bool {
        TokenManager.shared.getUserRole() == "professional"
    }
}

// MARK: - Order Details Top Bar
struct OrderDetailsTopBar: View {
    let showDeleteButton: Bool
    let onBackClick: () -> Void
    let onDeleteClick: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBackClick) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.backward")
                    Text("Back")
                }
                .foregroundColor(DarkText)
            }
            
            Spacer()
            
            Text("Order Details")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(DarkText)
            
            Spacer()
            
            if showDeleteButton {
                Button(action: onDeleteClick) {
                    Image(systemName: "trash")
                        .foregroundColor(ErrorColor)
                }
            } else {
                // Invisible spacer for centering
                HStack(spacing: 8) {
                    Image(systemName: "arrow.backward")
                    Text("Back")
                }
                .opacity(0)
            }
        }
        .padding(16)
        .background(CardBackground)
    }
}

// MARK: - Order Header Card
struct OrderHeaderCard: View {
    let order: OrderResponse
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Order #\(String(order._id.suffix(8)))")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(DarkText)
                    
                    // Date & Time
                    HStack(spacing: 4) {
                        Text("📅")
                        Text(formatDate(order.createdAt))
                            .font(.system(size: 14))
                            .foregroundColor(LightGrayText)
                    }
                    
                    // Order Type
                    HStack(spacing: 4) {
                        Text(orderTypeEmoji(order.orderType))
                        Text(orderTypeText(order.orderType))
                            .font(.system(size: 14))
                            .foregroundColor(LightGrayText)
                    }
                }
                
                Spacer()
                
                // Status Badge
                OrderStatusBadge(status: order.status)
            }
        }
        .padding(16)
        .background(CardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM dd, yyyy • hh:mm a"
        displayFormatter.locale = Locale(identifier: "en_US")
        
        return displayFormatter.string(from: date)
    }
    
    private func orderTypeEmoji(_ type: OrderType) -> String {
        switch type {
        case .delivery: return "🚚"
        case .takeaway: return "🛍️"
        case .eatIn: return "🍽️"
        }
    }
    
    private func orderTypeText(_ type: OrderType) -> String {
        switch type {
        case .delivery: return "Delivery"
        case .takeaway: return "Takeaway"
        case .eatIn: return "Dine-in"
        }
    }
}

// MARK: - Order Status Badge
struct OrderStatusBadge: View {
    let status: OrderStatus
    
    var body: some View {
        let (backgroundColor, textColor) = statusColors(status)
        
        Text(status.rawValue.uppercased())
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor.opacity(0.15))
            .cornerRadius(8)
    }
    
    private func statusColors(_ status: OrderStatus) -> (Color, Color) {
        switch status {
        case .completed:
            return (SuccessColor, SuccessColor)
        case .cancelled, .refused:
            return (ErrorColor, ErrorColor)
        case .pending:
            return (WarningColor, WarningColor)
        case .confirmed:
            return (InfoColor, InfoColor)
        }
    }
}

// MARK: - Order Item Detail Card
struct OrderItemDetailCard: View {
    let item: OrderItemResponse
    
    var body: some View {
        HStack(spacing: 12) {
            // Item Image
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
            
            // Item Details
            VStack(alignment: .leading, spacing: 8) {
                // Name and Quantity
                HStack {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DarkText)
                    
                    Spacer()
                    
                    Text("x\(item.quantity)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(LightGrayText)
                }
                
                // Ingredients with Intensity Display
                if let ingredients = item.chosenIngredients, !ingredients.isEmpty {
                    OrderIngredientsListWithIntensity(ingredients: ingredients)
                }
                
                // Options
                if let options = item.chosenOptions, !options.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Options:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DarkText)
                        
                        ForEach(options, id: \.name) { option in
                            Text("  + \(option.name) (+\(String(format: "%.2f", option.price)) TND)")
                                .font(.system(size: 11))
                                .foregroundColor(PrimaryColor)
                        }
                    }
                }
                
                // Item Price
                Text("\(String(format: "%.2f", item.calculatedPrice * Double(item.quantity))) TND")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(PrimaryColor)
            }
        }
        .padding(12)
        .background(CardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
    
    private var imageUrl: String {
        guard let image = item.image, !image.isEmpty else { return "" }
        return BaseUrlProvider.shared.getFullImageUrl(image) ?? ""
    }
}

// MARK: - Order Ingredients List With Intensity
struct OrderIngredientsListWithIntensity: View {
    let ingredients: [ChosenIngredientResponse]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Ingredients:")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DarkText)
                .padding(.bottom, 4)
            
            ForEach(ingredients, id: \.name) { ingredient in
                if ingredient.intensityType != nil {
                    // Ingredient with intensity slider
                    OrderIngredientIntensityCard(ingredient: ingredient)
                } else {
                    // Regular ingredient without intensity
                    HStack(spacing: 4) {
                        Text("  \(ingredient.isDefault ? "✓" : "+") \(ingredient.name)")
                            .font(.system(size: 11))
                            .foregroundColor(LightGrayText)
                    }
                    .padding(.leading, 8)
                }
            }
        }
    }
}

// MARK: - Order Ingredient Intensity Card
struct OrderIngredientIntensityCard: View {
    let ingredient: ChosenIngredientResponse
    
    var intensityValue: Float {
        Float(ingredient.intensityValue ?? 0.5)
    }
    
    var intensityColor: Color {
        getIntensityColorForOrder(
            type: ingredient.intensityType,
            hexColor: ingredient.intensityColor,
            value: intensityValue
        )
    }
    
    var emoji: String {
        getEmojiForIntensityType(type: ingredient.intensityType)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Ingredient name
            HStack {
                Circle()
                    .fill(PrimaryColor)
                    .frame(width: 6, height: 6)
                
                Text(ingredient.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DarkText)
                
                if ingredient.isDefault {
                    Text("(Default)")
                        .font(.system(size: 10))
                        .foregroundColor(LightGrayText)
                }
                
                Spacer()
            }
            
            // Intensity slider (read-only)
            HStack(spacing: 12) {
                OrderIntensitySlider(
                    value: intensityValue,
                    activeColor: intensityColor,
                    inactiveColor: intensityColor.opacity(0.3)
                )
                
                // Intensity icons on the right
                HStack(spacing: 4) {
                    if intensityValue >= 0.8 {
                        OrderBouncingIcon(emoji: emoji, fontSize: 16, delay: 0)
                        if ingredient.intensityType == .harissa || ingredient.intensityType == .chili {
                            OrderBouncingIcon(emoji: "🔥", fontSize: 16, delay: 100)
                        }
                    } else if intensityValue >= 0.3 {
                        OrderBouncingIcon(emoji: emoji, fontSize: 14, delay: 0)
                        OrderBouncingIcon(emoji: emoji, fontSize: 14, delay: 150)
                    } else {
                        OrderBouncingIcon(emoji: emoji, fontSize: 14, delay: 0)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0xFFF9FAFB))
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
}

// MARK: - Order Intensity Slider (Read-only)
struct OrderIntensitySlider: View {
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

// MARK: - Order Bouncing Icon
struct OrderBouncingIcon: View {
    let emoji: String
    let fontSize: CGFloat
    let delay: Int
    
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        Text(emoji)
            .font(.system(size: fontSize))
            .offset(y: bounceOffset)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.7)
                        .repeatForever(autoreverses: true)
                        .delay(Double(delay) / 1000.0)
                ) {
                    bounceOffset = -8
                }
            }
    }
}

// MARK: - Order Status Update Card (For Professionals)
struct OrderStatusUpdateCard: View {
    let order: OrderResponse
    let onStatusChange: (OrderStatus) -> Void
    
    private var validTransitions: [OrderStatus] {
        switch order.status {
        case .pending:
            return [.confirmed, .refused, .cancelled]
        case .confirmed:
            return [.completed, .cancelled]
        case .completed, .cancelled, .refused:
            return [] // Final states - no transitions
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Order Status:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DarkText)
                
                Spacer()
                
                // Status Dropdown
                if !validTransitions.isEmpty {
                    Menu {
                        ForEach(validTransitions, id: \.self) { status in
                            Button(status.displayName) {
                                onStatusChange(status)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(order.status.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(order.status == .pending ? Color(hex: 0xFFC107) : getStatusColor(order.status))
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: 0xFFF8E1)) // Light yellow background
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0xFFC107), lineWidth: 1) // Yellow border
                        )
                        .cornerRadius(8)
                    }
                } else {
                    // Show current status if no transitions available
                    Text(order.status.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(getStatusColor(order.status))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(getStatusColor(order.status).opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(CardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Helper function to get valid status transitions
    private func getValidStatusTransitions(from currentStatus: OrderStatus) -> [OrderStatus] {
        switch currentStatus {
        case .pending:
            return [.confirmed, .refused, .cancelled]
        case .confirmed:
            return [.completed, .cancelled]
        case .completed, .cancelled, .refused:
            return [] // Final states - no transitions
        }
    }
    
    // Helper function to get status color
    private func getStatusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .pending:
            return Color(hex: 0xFFC107) // Amber
        case .confirmed:
            return Color(hex: 0x10B981) // Green
        case .completed:
            return Color(hex: 0x2196F3) // Blue
        case .cancelled:
            return Color.gray
        case .refused:
            return Color(hex: 0xEF4444) // Red
        }
    }
}

// MARK: - Order Summary Card
struct OrderSummaryCard: View {
    let order: OrderResponse
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Order Summary")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(DarkText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Subtotal
            HStack {
                Text("Subtotal")
                    .font(.system(size: 14))
                    .foregroundColor(LightGrayText)
                
                Spacer()
                
                Text("\(String(format: "%.2f", order.totalPrice)) TND")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DarkText)
            }
            
            Divider()
            
            // Total
            HStack {
                Text("Total")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DarkText)
                
                Spacer()
                
                Text("\(String(format: "%.2f", order.totalPrice)) TND")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(PrimaryColor)
            }
        }
        .padding(16)
        .background(CardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Loading View
struct LoadingOrderDetailsView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: PrimaryColor))
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundLight)
    }
}

// MARK: - Error View
struct ErrorOrderDetailsView: View {
    let message: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BackgroundLight)
    }
}

// MARK: - Helper Functions
func getEmojiForIntensityType(type: IntensityType?) -> String {
    guard let type = type else { return "⭐" }
    
    switch type {
    case .coffee: return "☕"
    case .harissa: return "🌶️"
    case .sauce: return "🍯"
    case .spice: return "🌿"
    case .sugar: return "🍬"
    case .salt: return "🧂"
    case .pepper: return "🫚"
    case .chili: return "🌶️"
    case .garlic: return "🧄"
    case .lemon: return "🍋"
    case .custom: return "⭐"
    }
}

func getIntensityColorForOrder(type: IntensityType?, hexColor: String?, value: Float) -> Color {
    // If hex color provided, parse and adjust by intensity
    if let hex = hexColor {
        let hexSanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexSanitized.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            let color = Color(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue: Double(b) / 255,
                opacity: Double(a) / 255
            )
            return color.opacity(Double(0.5 + value * 0.5))
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            let color = Color(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue: Double(b) / 255,
                opacity: Double(a) / 255
            )
            return color.opacity(Double(0.5 + value * 0.5))
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            let color = Color(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue: Double(b) / 255,
                opacity: Double(a) / 255
            )
            return color.opacity(Double(0.5 + value * 0.5))
        default:
            // Fall through to default colors
            break
        }
    }
    
    // Default colors based on type
    guard let type = type else {
        return Color(
            red: Double(0.6 + value * 0.2),
            green: Double(0.6 + value * 0.2),
            blue: Double(0.6 + value * 0.2)
        )
    }
    
    switch type {
    case .coffee:
        return Color(
            red: Double(0.2 + value * 0.2),
            green: Double(0.15 + value * 0.1),
            blue: Double(0.1 + value * 0.1)
        )
    case .harissa, .chili:
        return Color(
            red: Double(0.6 + value * 0.4),
            green: Double(max(0, 0.2 - value * 0.2)),
            blue: Double(max(0, 0.2 - value * 0.2))
        )
    case .sauce:
        return Color(
            red: Double(0.9 + value * 0.1),
            green: Double(0.6 + value * 0.2),
            blue: Double(max(0, 0.2 - value * 0.1))
        )
    case .spice:
        return Color(
            red: Double(0.8 + value * 0.2),
            green: Double(0.5 + value * 0.2),
            blue: Double(max(0, 0.2 - value * 0.1))
        )
    case .sugar:
        return Color(
            red: Double(0.95 + value * 0.05),
            green: Double(0.9 + value * 0.1),
            blue: Double(0.7 + value * 0.2)
        )
    case .salt:
        return Color(
            red: Double(0.85 + value * 0.1),
            green: Double(0.85 + value * 0.1),
            blue: Double(0.9 + value * 0.1)
        )
    case .pepper:
        return Color(
            red: Double(0.2 + value * 0.2),
            green: Double(0.2 + value * 0.2),
            blue: Double(0.2 + value * 0.2)
        )
    case .garlic:
        return Color(
            red: Double(0.95 + value * 0.05),
            green: Double(0.95 + value * 0.05),
            blue: Double(0.9 + value * 0.1)
        )
    case .lemon:
        return Color(
            red: Double(0.95 + value * 0.05),
            green: Double(0.9 + value * 0.1),
            blue: Double(max(0, 0.4 - value * 0.2))
        )
    case .custom:
        return Color(
            red: Double(0.6 + value * 0.2),
            green: Double(0.6 + value * 0.2),
            blue: Double(0.6 + value * 0.2)
        )
    }
}
