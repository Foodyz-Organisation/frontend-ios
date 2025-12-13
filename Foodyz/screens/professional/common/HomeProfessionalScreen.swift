import Foundation
import SwiftUI

// MARK: - Custom Colors (No change)

extension Color {
    static let foodyzOrange = Color(red: 0.99, green: 0.69, blue: 0.16)
    static let foodyzBackground = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let acceptedGreen = Color(red: 0.23, green: 0.76, blue: 0.38)
    static let refusedRed = Color(red: 1.0, green: 0.25, blue: 0.25)
    static let iconGray = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let iconBgOrange = Color(red: 1.0, green: 0.89, blue: 0.75)
    static let locationPurple = Color(red: 0.6, green: 0.4, blue: 0.8)
    static let iconBgPurple = Color(red: 0.96, green: 0.94, blue: 1.0)
    static let mediumGray = Color(white: 0.4)
}

// MARK: - Main View (HomeProfessionalView)

struct HomeProfessionalView: View {
    // Navigation binding from parent (AppNavigation)
    @Binding var path: NavigationPath
    let professionalId: String
    
    // Order management
    @StateObject private var orderViewModel = OrderViewModel()
    @State private var selectedOrderType: OrderType = .takeaway  // Changed from .delivery to .takeaway
    @State private var showingDrawer = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Background
            Color.foodyzBackground
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                
                // --- 1. Custom Top Bar (Now uses path binding) ---
                FoodyzTopBar(path: $path, onMenuClick: { withAnimation { showingDrawer = true } })
                
                // --- 2. Content Area ---
                if orderViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading orders...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top)
                    Spacer()
                } else if let errorMessage = orderViewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button("Retry") {
                            orderViewModel.loadPendingOrders(professionalId: professionalId)
                        }
                        .padding()
                        .background(Color.foodyzOrange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            
                            // --- Tab Icons Row ---
                            TabIconRow(path: $path)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                            
                            // Filter orders by selectedOrderType
                            let filteredOrders = orderViewModel.orders.filter { $0.orderType == selectedOrderType && $0.status == .pending }
                            
                            // --- Pending Orders Section ---
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pending Orders")
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(.black)
                                Text("\(filteredOrders.count) \(selectedOrderType.displayName) orders waiting for confirmation")
                                    .font(.subheadline)
                                    .foregroundColor(.mediumGray)
                            }
                            .padding(.horizontal, 20)
                            
                            // --- Dynamic Order Cards ---
                            if filteredOrders.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    Text("No pending \(selectedOrderType.displayName) orders")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                VStack(spacing: 15) {
                                    ForEach(filteredOrders) { order in
                                        OrderCardView(
                                            order: order,
                                            onAccept: {
                                                orderViewModel.acceptOrder(orderId: order._id) { success in
                                                    if success {
                                                        // Refresh orders
                                                        orderViewModel.loadPendingOrders(professionalId: professionalId)
                                                    }
                                                }
                                            },
                                            onRefuse: {
                                                orderViewModel.refuseOrder(orderId: order._id) { success in
                                                    if success {
                                                        // Refresh orders
                                                        orderViewModel.loadPendingOrders(professionalId: professionalId)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 120) // Space for bottom bar
                    }
                    .edgesIgnoringSafeArea(.bottom)
                }
            }
            
            // --- 3. Custom Bottom Bar ---
            FoodyzBottomBar(selectedOrderType: $selectedOrderType)
            
            // --- 4. Drawer Overlay (inside ZStack) ---
            if showingDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showingDrawer = false } }
                
                HStack(spacing: 0) {
                    ProfessionalDrawer(
                        onCloseDrawer: { withAnimation { showingDrawer = false } },
                        navigateTo: { route in
                            withAnimation { showingDrawer = false }
                            // Handle navigation based on route
                            switch route {
                            case "menu":
                                path.append(Screen.menu)
                            case "reclamations":
                                path.append(Screen.reclamationList)
                            // Add other routes as needed
                            default:
                                break
                            }
                        }
                    )
                    Spacer()
                }
                .transition(.move(edge: .leading))
                .animation(.easeInOut, value: showingDrawer)
            }
        }
        .zIndex(showingDrawer ? 1 : 0)
        // Hide system back button
        .navigationBarBackButtonHidden(true)
        // 🛑 REMOVED REDUNDANT .navigationDestination BLOCK
        // The .navigationDestination must only exist in AppNavigation.
        .onAppear {
            // DEBUG: Print all relevant information
            print("🏠 ═══════════════════════════════════════════════════")
            print("🏠 HomeProfessionalView appeared")
            print("🏠 Professional ID: \(professionalId)")
            print("🏠 Session userId: \(SessionManager.shared.userId ?? "nil")")
            print("🏠 Session token exists: \(SessionManager.shared.accessToken != nil)")
            if let token = SessionManager.shared.accessToken {
                print("🏠 Token preview: \(String(token.prefix(20)))...")
            }
            print("🏠 Current order count: \(orderViewModel.orders.count)")
            print("🏠 Is loading: \(orderViewModel.isLoading)")
            print("🏠 Error message: \(orderViewModel.errorMessage ?? "none")")
            print("🏠 ═══════════════════════════════════════════════════")
            
            // Load pending orders when view appears
            orderViewModel.loadPendingOrders(professionalId: professionalId)
        }
        .onChange(of: orderViewModel.orders) { newOrders in
            print("📦 ═══════════════════════════════════════════════════")
            print("📦 Orders changed! New count: \(newOrders.count)")
            for (index, order) in newOrders.enumerated() {
                print("📦 Order \(index + 1): ID=\(order._id.suffix(6)), Status=\(order.status), Type=\(order.orderType)")
            }
            print("📦 ═══════════════════════════════════════════════════")
        }
        .onChange(of: orderViewModel.errorMessage) { errorMsg in
            if let error = errorMsg {
                print("❌ ═══════════════════════════════════════════════════")
                print("❌ OrderViewModel Error: \(error)")
                print("❌ ═══════════════════════════════════════════════════")
            }
        }
    }
    
    
    
    // MARK: - Component 1: FoodyzTopBar
    
    struct FoodyzTopBar: View {
        // 🟢 CHANGED: Use path binding directly instead of optional closure
        @Binding var path: NavigationPath
        var onMenuClick: () -> Void
        
        var body: some View {
            HStack {
                // Avatar
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 35, height: 35)
                    .foregroundColor(.iconGray)
                
                Text("Foodyz Pro")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.leading, 4)
                
                Spacer()
                
                // Search Icon
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.black)
                    .padding(10)
                
                // Menu Icon (Navigation Trigger)
                Button(action: onMenuClick) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            .padding(.bottom, 15)
            .background(Color.white)
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 5)
        }
    }
    
    // MARK: - Component 2: Tab Icon Row
    
    struct TabIconRow: View {
        @Binding var path: NavigationPath
        
        let icons: [(systemName: String, isSelected: Bool, badge: Int)] = [
            ("house.fill", true, 0),
            ("plus.square.fill", false, 0),
            ("list.bullet.rectangle.fill", false, 0), // Menu/Order List
            ("bubble.left.fill", false, 1),
            ("bell.fill", false, 3)
        ]
        
        var body: some View {
            HStack(spacing: 0) {
                ForEach(icons.indices, id: \.self) { index in
                    let icon = icons[index]
                    
                    Button(action: {
                        if icon.systemName == "list.bullet.rectangle.fill" {
                            // 🟢 FIX: Navigate using the correct Screen enum
                            path.append(Screen.menu)
                        } else {
                            print("Tapped on \(icon.systemName)")
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Group {
                                if icon.isSelected {
                                    ZStack {
                                        Circle()
                                            .fill(Color.iconBgOrange)
                                            .frame(width: 50, height: 50)
                                        Image(systemName: icon.systemName)
                                            .foregroundColor(.foodyzOrange)
                                            .font(.title3)
                                            .fontWeight(.medium)
                                    }
                                } else {
                                    Image(systemName: icon.systemName)
                                        .font(.title2)
                                        .foregroundColor(.black.opacity(0.7))
                                        .frame(width: 50, height: 50)
                                }
                            }
                            
                            if icon.badge == 1 {
                                Circle()
                                    .fill(Color.refusedRed)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 5, y: 5)
                            } else if icon.badge > 1 {
                                Text("\(icon.badge)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(Color.refusedRed))
                                    .offset(x: 10, y: 0)
                            }
                        }
                    }
                    
                    if index < icons.count - 1 {
                        Spacer()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Component 3: Order Card View
    
    struct OrderCardView: View {
        let order: OrderResponse
        let onAccept: () -> Void
        let onRefuse: () -> Void
        
        // Helper to format order items
        private var orderSummary: String {
            order.items.map { "\($0.name) (x\($0.quantity))" }.joined(separator: ", ")
        }
        
        // Helper for time display
        private var timeAgo: String {
            // Simple relative time - you can improve this with actual date formatting
            "Received recently"
        }
        
        var body: some View {
            VStack(spacing: 15) {
                HStack(alignment: .top) {
                    // Avatar (Placeholder - could show user image if available)
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .foregroundColor(.iconGray)
                        .overlay(Circle().stroke(Color.foodyzBackground, lineWidth: 2))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order #\(order._id.suffix(6))")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text(orderSummary)
                            .font(.subheadline)
                            .foregroundColor(.mediumGray)
                            .lineLimit(2)
                        
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Order Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(String(format: "%.2f DT", order.totalPrice))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.acceptedGreen)
                    }
                }
                
                // Divider
                Divider()
                    .padding(.horizontal, -15)
                
                // Location (if delivery)
                if let address = order.deliveryAddress, !address.isEmpty {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.locationPurple)
                        Text(address)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.locationPurple)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color.iconBgPurple)
                    .cornerRadius(8)
                }
                
                // Action Buttons
                HStack(spacing: 10) {
                    // Accept Button
                    ActionButton(
                        label: "Accept",
                        iconName: "checkmark.circle.fill",
                        color: .acceptedGreen,
                        action: onAccept
                    )
                    
                    // Refuse Button
                    ActionButton(
                        label: "Refuse",
                        iconName: "xmark.circle.fill",
                        color: .refusedRed,
                        action: onRefuse
                    )
                    
                    // Notes/Chat Button (Smaller)
                    if order.notes != nil {
                        Button(action: {}) {
                            Image(systemName: "text.bubble.fill")
                                .font(.title3)
                                .foregroundColor(.mediumGray)
                                .frame(width: 50, height: 50)
                                .background(Color.foodyzBackground)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
        }
    }
    
    // Helper for Action Buttons
    struct ActionButton: View {
        let label: String
        let iconName: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack {
                    Image(systemName: iconName)
                    Text(label)
                        .lineLimit(1)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .cornerRadius(10)
            }
        }
    }
    
    
    // MARK: - Component 4: FoodyzBottomBar (Mode Selector)
    
    struct FoodyzBottomBar: View {
        @Binding var selectedOrderType: OrderType
        
        var body: some View {
            HStack(spacing: 10) {
                // Pick-up
                BottomBarItem(
                    iconName: "cube.box.fill",
                    label: "Pick-up",
                    isSelected: selectedOrderType == .takeaway,
                    onTap: { selectedOrderType = .takeaway }
                )
                
                // Dine-in
                BottomBarItem(
                    iconName: "fork.knife",
                    label: "Dine-in",
                    isSelected: selectedOrderType == .eatIn,
                    onTap: { selectedOrderType = .eatIn }
                )
                
                // Delivery (Selected/Primary)
                BottomBarItem(
                    iconName: "bag.fill",
                    label: "Delivery",
                    isSelected: selectedOrderType == .delivery,
                    onTap: { selectedOrderType = .delivery }
                )
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: -5)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
    }
    
    struct BottomBarItem: View {
        let iconName: String
        let label: String
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 4) {
                    Image(systemName: iconName)
                        .font(.body)
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(isSelected ? .white : .mediumGray)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.foodyzOrange : Color.white)
                .cornerRadius(20)
                .scaleEffect(isSelected ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        }
    }
    
    // MARK: - Navigation Host & Preview (No change)
    
    // Host view to contain the NavigationStack and manage the path
    struct HomeProfessionalHostView: View {
        @State private var path = NavigationPath()
        @State private var professionalId: String = "" // Store dynamic ID from login
        
        var body: some View {
            NavigationStack(path: $path) {
                HomeProfessionalView(path: $path, professionalId: professionalId)
                    .navigationBarHidden(true)
            }
        }
    }
    
    
    #Preview {
        HomeProfessionalHostView()
    }
}
