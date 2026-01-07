import SwiftUI

// MARK: - Order History Screen
struct OrderHistoryScreen: View {
    @StateObject private var viewModel = OrderViewModel()
    
    let userId: String
    let onOrderClick: (String) -> Void
    var onReclamationClick: ((String) -> Void)? = nil // Callback for reclamation navigation
    
    // Navigation callbacks
    var onHomeClick: (() -> Void)? = nil
    var onMessagesClick: (() -> Void)? = nil
    var onOrdersClick: (() -> Void)? = nil
    var onProfileClick: (() -> Void)? = nil
    var onSearchClick: (() -> Void)? = nil
    var onAddPostClick: (() -> Void)? = nil
    var onOpenDrawer: (() -> Void)? = nil // Kept for backward compat if needed, or remove?
    var onNavigateDrawer: ((String) -> Void)? = nil // NEW
    @State private var showingDrawer = false
    @State private var showNotifications = false
    @State private var selectedTab = "orders"

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // TopAppBar
                // MARK: - Custom Top Bar
                HStack {
                    // Logo (Cursive text)
                    Text("foodyz")
                        .font(.custom("Snell Roundhand", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#F59E0B")) // Yellow/Orange
                    
                    Spacer()
                    
                    // Menu Button
                    Button(action: {
                        withAnimation { showingDrawer = true }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(hex: "#333333")) // HomeColors.darkGray equivalent
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .background(Color.white)
                
                // Content
                if viewModel.isLoading {
                    LoadingOrdersView()
                } else if viewModel.orders.isEmpty {
                    EmptyOrdersView()
                } else {
                    OrdersList(
                        orders: viewModel.orders,
                        onOrderClick: onOrderClick,
                        onReclamationClick: onReclamationClick
                    )
                }
            }
            // Add padding to bottom to avoid content being hidden by bottom bar
            .padding(.bottom, 80)
            
            // MARK: - Floating Bottom Bar
            VStack {
                Spacer()
                UserBottomBar(
                    selectedTab: $selectedTab,
                    onTabSelect: { tab in
                        if tab == "home" {
                            onHomeClick?()
                        }
                    },
                    onReels: { /* Navigate to Reels */ },
                    onTrending: { /* Navigate to Trending */ },
                    onChat: { onMessagesClick?() },
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
                        withAnimation { showingDrawer = false }
                        onNavigateDrawer?(route)
                    },
                    currentRoute: "order_history"
                )
                .transition(.move(edge: .trailing))
                .animation(.easeInOut, value: showingDrawer)
            }
        }
        .background(Color(hex: 0xFFF9FAFB))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadOrdersByUser(userId: userId)
        }
    }
}

// MARK: - Order History Top Bar
struct OrderHistoryTopBar: View {
    let onBackClick: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBackClick) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.backward")
                    Text("Back")
                }
                .foregroundColor(Color(hex: 0xFF1F2A37))
            }
            
            Spacer()
            
            Text("Order History")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Spacer()
            
            // Invisible spacer for centering
            HStack(spacing: 8) {
                Image(systemName: "arrow.backward")
                Text("Back")
            }
            .opacity(0)
        }
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Loading View
struct LoadingOrdersView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading orders...")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .padding(.top, 16)
            Spacer()
        }
    }
}

// MARK: - Empty Orders View
struct EmptyOrdersView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: 0xFFD1D5DB))
            
            Text("No past orders")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Text("You haven't placed any orders yet.\nStart exploring delicious food!")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Orders List
struct OrdersList: View {
    let orders: [OrderResponse]
    let onOrderClick: (String) -> Void
    let onReclamationClick: ((String) -> Void)?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(orders) { order in
                    OrderItemCard(
                        order: order,
                        onClick: onOrderClick,
                        onReclamationClick: onReclamationClick
                    )
                }
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Order Item Card
struct OrderItemCard: View {
    let order: OrderResponse
    let onClick: (String) -> Void
    let onReclamationClick: ((String) -> Void)?
    
    var itemsSummary: String {
        let firstItems = order.items.prefix(2).map { "\($0.name) x\($0.quantity)" }.joined(separator: ", ")
        let moreCount = order.items.count > 2 ? ", +\(order.items.count - 2) more" : ""
        return firstItems + moreCount
    }
    
    var imageUrl: String {
        if let image = order.items.first?.image, !image.isEmpty {
            return "http://127.0.0.1:3000/\(image)"
        }
        return ""
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 12) {
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
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Order Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(itemsSummary)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                        .lineLimit(2)
                    
                    // Order Type Badge
                    HStack(spacing: 4) {
                        Text(order.orderType.emoji)
                            .font(.system(size: 12))
                        Text(order.orderType.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: order.orderType.color))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: order.orderType.color).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                Spacer()
                
                // Date and Reclamation Icon
                VStack(alignment: .trailing, spacing: 8) {
                    Text(order.createdAt.prefix(10))
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: 0xFF9CA3AF))
                    
                    // Reclamation Icon Button
                    if let onReclamationClick = onReclamationClick {
                        Button(action: {
                            onReclamationClick(order.id)
                        }) {
                            // Triangle warning icon from icons folder (24pt asset)
                            // If the asset isn't found, it will show a placeholder
                            Image("24pt")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(red: 1.0, green: 0.65, blue: 0.0)) // Orange color
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 12)
            
            // Footer
            HStack {
                Text(String(format: "%.2f DT", order.totalPrice))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                
                Spacer()
                
                // Status Badge
                Text(order.status.displayName.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: order.status.color))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: order.status.color).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .padding(.horizontal, 16)
        .onTapGesture {
            onClick(order.id)
        }
    }
}
