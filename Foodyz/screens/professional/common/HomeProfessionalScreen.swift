import Foundation
import SwiftUI
import UIKit // Needed for corner radius helper if unrelated to previous fix

// MARK: - Custom Colors

extension Color {
    static let foodyzOrange = Color(red: 0.99, green: 0.69, blue: 0.16)
    static let foodyzBackground = Color(red: 0.98, green: 0.96, blue: 0.92) // Cream/White background
    static let acceptedGreen = Color(red: 0.23, green: 0.76, blue: 0.38)
    static let refusedRed = Color(red: 1.0, green: 0.25, blue: 0.25)
    static let iconGray = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let orangeText = Color(hex: 0xD97706) // Darker orange/brown for text
    static let statusYellowBg = Color(hex: 0xFFF8E1) // Light yellow for pending status
    static let statusYellowBorder = Color(hex: 0xFFC107) // Border for status
    static let purpleBg = Color(hex: 0xF3E5F5)
    static let purpleText = Color(hex: 0x7B1FA2)
    
    // Restored colors
    static let mediumGray = Color(white: 0.4)
    static let iconBgOrange = Color(red: 1.0, green: 0.89, blue: 0.75)
    static let locationPurple = Color(red: 0.6, green: 0.4, blue: 0.8)
    static let iconBgPurple = Color(red: 0.96, green: 0.94, blue: 1.0)
}

// MARK: - Helper Functions (Keep existing)

func getValidStatusTransitions(from currentStatus: OrderStatus) -> [OrderStatus] {
    switch currentStatus {
    case .pending:
        return [.confirmed, .refused, .cancelled]
    case .confirmed:
        return [.completed, .cancelled]
    case .completed, .cancelled, .refused:
        return [] // Final states - no transitions
    }
}

func getStatusColor(_ status: OrderStatus) -> Color {
    switch status {
    case .pending:
        return Color(hex: 0xFFC107) // Amber
    case .confirmed:
        return Color.acceptedGreen
    case .completed:
        return Color(hex: 0x2196F3) // Blue
    case .cancelled:
        return Color.gray
    case .refused:
        return Color.refusedRed
    }
}

func formatTimeAgo(from dateString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    guard let date = formatter.date(from: dateString) else {
        return "Received recently"
    }
    
    let interval = Date().timeIntervalSince(date)
    let minutes = Int(interval / 60)
    
    if minutes < 1 {
        return "Received just now"
    } else if minutes < 60 {
        return "Received \(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
    } else {
        let hours = minutes / 60
        return "Received \(hours) \(hours == 1 ? "hour" : "hours") ago"
    }
}

// MARK: - Main View

struct HomeProfessionalView: View {
    @Binding var path: NavigationPath
    let professionalId: String
    @State private var showingDrawer = false
    var onNavigateDrawer: ((String) -> Void)? = nil
    
    @StateObject private var orderViewModel = OrderViewModel()
    
    // Filter States
    @State private var selectedStatusFilter: OrderStatus? = nil
    @State private var selectedTypeFilter: OrderType? = nil
    
    @State private var showDeleteAllDialog = false
    @State private var showingStatusDropdown: String? = nil // Order ID
    @State private var showNotifications = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea() // Main background
            
            VStack(spacing: 0) {
                // 1. Top Bar
                FoodyzTopBar(
                    path: $path,
                    professionalId: professionalId,
                    openDrawer: { withAnimation { showingDrawer = true } },
                    onProfileClick: { 
                        print("DEBUG: Navigating to profile for id: \(professionalId)")
                        path.append(Screen.professionalProfile(professionalId)) 
                    },
                    onLocationClick: {
                        // Navigate to All Users Tracking screen (same as Android map pin)
                        path.append(Screen.allUsersTracking)
                    }
                )
                
                // 2. Filters Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Showing \(filteredOrders.count) of \(orderViewModel.orders.count) orders")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 20)
                    
                    HStack(spacing: 15) {
                        // Status Filter
                        FilterDropdown(
                            label: "Status",
                            currentValue: selectedStatusFilter?.displayName ?? "All Statuses",
                            icon: nil
                        ) {
                             Menu {
                                 Button("All Statuses") { selectedStatusFilter = nil }
                                 ForEach(OrderStatus.allCases, id: \.self) { status in
                                     Button(status.displayName) { selectedStatusFilter = status }
                                 }
                             } label: {
                                 EmptyView()
                             }
                        }
                        
                        // Type Filter
                        FilterDropdown(
                            label: "Type",
                            currentValue: selectedTypeFilter?.rawValue.capitalized ?? "All Types",
                            icon: nil
                        ) {
                            Menu {
                                Button("All Types") { selectedTypeFilter = nil }
                                ForEach(OrderType.allCases, id: \.self) { type in
                                    Button(type.rawValue.capitalized) { selectedTypeFilter = type }
                                }
                            } label: {
                                EmptyView()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
                
                // 3. Orders ScrollView
                ScrollView {
                    VStack(spacing: 20) {
                        if orderViewModel.isLoading {
                            ProgressView().padding(.top, 50)
                        } else if filteredOrders.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "tray")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No orders found")
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 50)
                        } else {
                            ForEach(filteredOrders, id: \.id) { order in
                                OrderCardNew(
                                    order: order,
                                    isDropdownExpanded: showingStatusDropdown == order._id,
                                    onDropdownToggle: {
                                        withAnimation {
                                            if showingStatusDropdown == order._id {
                                                showingStatusDropdown = nil
                                            } else {
                                                showingStatusDropdown = order._id
                                            }
                                        }
                                    },
                                    onStatusChange: { newStatus in
                                        orderViewModel.updateOrderStatus(orderId: order._id, status: newStatus) { success in
                                            if success {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                    orderViewModel.loadOrdersByProfessional(professionalId: professionalId)
                                                }
                                            }
                                        }
                                    },
                                    onTap: { path.append(Screen.orderDetail(order._id)) }
                                )
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.bottom, 100) // Space for bottom bar
                }
            } // End Main VStack
            
            // 4. Custom Bottom Navigation
            ProfessionalBottomBar(path: $path, openDrawer: { withAnimation { showingDrawer = true } })
            
            // Drawer Overlay
            if showingDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showingDrawer = false } }
                
                ProfessionalDrawer(
                    onCloseDrawer: { withAnimation { showingDrawer = false } },
                    navigateTo: { route in
                        // Use the navigation handler from AppNavigation if provided
                        if let handler = onNavigateDrawer {
                            handler(route)
                        } else {
                            // Fallback to local navigation
                            if route == "logout" {
                                path.removeLast(path.count)
                                path.append(Screen.login)
                                TokenManager.shared.clearAllData()
                            } else if route == "menu" {
                                path.append(Screen.menu)
                            } else if route == "deals_management" {
                                path.append(Screen.proDealsManagement)
                            } else if route == "notifications" {
                                path.append(Screen.professionalNotifications)
                            } else if route == "profile" {
                                path.append(Screen.professionalProfile(professionalId))
                            } else if route == "events" {
                                path.append(Screen.eventList)
                            } else if route == "reclamations" {
                                path.append(Screen.reclamationList)
                            }
                        }
                        withAnimation { showingDrawer = false }
                    }
                )
                .transition(.move(edge: .trailing))
                .animation(.easeInOut, value: showingDrawer)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            orderViewModel.loadOrdersByProfessional(professionalId: professionalId)
        }
    }
    
    var filteredOrders: [OrderResponse] {
        orderViewModel.orders.filter { order in
            let matchesStatus = selectedStatusFilter == nil || order.status == selectedStatusFilter
            let matchesType = selectedTypeFilter == nil || order.orderType == selectedTypeFilter
            return matchesStatus && matchesType
        }
    }
}

// MARK: - Components

struct FilterDropdown<Content: View>: View {
    let label: String
    let currentValue: String
    let icon: String?
    @ViewBuilder let menuContent: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
             // Label cutout effect logic is complex in SwiftUI without custom shapes, 
             // so we'll simulate the "Label on border" look or just put it inside for simplicity 
             // as per generic Material Design guidelines or the image. 
             // The image shows the label "Status" breaking the border.
             
            ZStack(alignment: .topLeading) {
                // The Box
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(currentValue)
                        .foregroundColor(.black)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.caption)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
                .background(Color.white) // to cover content behind
                
                // The Label (Floating)
                Text(" \(label) ")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .offset(x: 10, y: -7)
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(
            menuContent.opacity(0.01) // Invisible hit target for the menu
        )
    }
}

struct OrderCardNew: View {
    let order: OrderResponse
    let isDropdownExpanded: Bool
    let onDropdownToggle: () -> Void
    let onStatusChange: (OrderStatus) -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // Header Row
            HStack(alignment: .top) {
                // Avatar
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 45, height: 45)
                    .foregroundColor(.gray.opacity(0.5))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.userUsername ?? "Customer")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // Item summary
                    Text(itemsSummary)
                         .font(.system(size: 13))
                         .foregroundColor(.gray)
                    
                    // Time Ago
                    Text(formatTimeAgo(from: order.createdAt))
                        .font(.system(size: 13))
                        .foregroundColor(Color.foodyzOrange)
                }
                
                Spacer()
                
                // Price
                Text(String(format: "%.2f TND", order.totalPrice))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color.acceptedGreen)
            }
            
            // Address Pill
            if let address = order.deliveryAddress, !address.isEmpty {
                HStack {
                    Image(systemName: "mappin.fill")
                        .font(.caption)
                        .foregroundColor(Color.purpleText)
                    Text(address)
                        .font(.caption)
                        .foregroundColor(Color.purpleText)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.purpleBg)
                .cornerRadius(8)
            } else {
                 HStack {
                    Image(systemName: "mappin.fill")
                        .font(.caption)
                        .foregroundColor(Color.purpleText)
                    Text("No address")
                        .font(.caption)
                        .foregroundColor(Color.purpleText)
                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.purpleBg)
                .cornerRadius(8)
            }
            
            // Status Section
            HStack {
                Text("Order Status:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Custom Status Dropdown
                let validTransitions = getValidStatusTransitions(from: order.status)
                
                Menu {
                    ForEach(validTransitions, id: \.self) { status in
                         Button(status.displayName) { onStatusChange(status) }
                    }
                } label: {
                    HStack {
                        Text(order.status.displayName)
                            .fontWeight(.medium)
                            // Use specific color for "Pending" as in design (Orange/Yellow text)
                            .foregroundColor(order.status == .pending ? Color.foodyzOrange : getStatusColor(order.status))
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(Color.black)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.statusYellowBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.statusYellowBorder, lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .disabled(validTransitions.isEmpty)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
        .onTapGesture { onTap() }
    }
    
    var itemsSummary: String {
        let firstItems = order.items.prefix(2).map { "\($0.name) (x\($0.quantity))" }.joined(separator: ", ")
        let moreCount = order.items.count > 2 ? ", +\(order.items.count - 2) more" : ""
        return firstItems + moreCount
    }
}

// MARK: - Bottom Bar

// MARK: - Bottom Bar

struct ProfessionalBottomBar: View {
    @Binding var path: NavigationPath
    var selectedTab: String = "home" // default to "home"
    var openDrawer: () -> Void
    
    var body: some View {
        HStack {
             BottomBarButton(
                 icon: "house.fill",
                 label: "Home",
                 isSelected: selectedTab == "home"
             ) {
                 if selectedTab != "home" {
                    // Navigate back to home if not already there, or reset stack
                    // Assuming this bar is used in screens that are navigated TO.
                    // If we are in ChatListView, we might want to pop back to home.
                    onHomeClick()
                 }
             }
             Spacer()
             BottomBarButton(
                 icon: "message.fill",
                 label: "Chat",
                 isSelected: selectedTab == "chat"
             ) {
                 if selectedTab != "chat" {
                     path.append(Screen.chatList(role: AppUserRole.professional))
                 }
             }
             Spacer()
             BottomBarButton(
                 icon: "plus",
                 label: "Add",
                 isSelected: selectedTab == "add"
             ) {
                 path.append(Screen.professionalAddContent)
             }
             Spacer()
             BottomBarButton(
                 icon: "bell.fill",
                 label: "Notifications",
                 isSelected: selectedTab == "notifications"
             ) {
                 if selectedTab != "notifications" {
                     path.append(Screen.professionalNotifications)
                 }
             }
             Spacer()
             BottomBarButton(
                 icon: "book.fill",
                 label: "Menu",
                 isSelected: selectedTab == "menu"
             ) {
                 path.append(Screen.menu)
             }
        }
        .padding(.horizontal, 25)
        .padding(.top, 15)
        .padding(.bottom, 10) // Adapt for home bar
        .background(Color.white)
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
    }
    
    private func onHomeClick() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
}

struct BottomBarButton: View {
    let icon: String
    let label: String
    var isSelected: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                 if isSelected {
                     Circle()
                         .stroke(Color.foodyzOrange, lineWidth: 2)
                         .frame(width: 40, height: 40)
                         .overlay(
                             Image(systemName: icon)
                                .foregroundColor(Color.foodyzOrange)
                         )
                     Text(label)
                         .font(.caption2)
                         .foregroundColor(Color.foodyzOrange)
                 } else {
                     Image(systemName: icon)
                         .font(.system(size: 20))
                         .foregroundColor(.gray)
                         .frame(width: 40, height: 40)
                     Text(label)
                         .font(.caption2)
                         .foregroundColor(.gray)
                 }
            }
        }
    }
}

// Re-add RoundedCorner if needed (it was fixed in LoginView, but might be needed here or accessible globally)
// If it's global, we don't need to redeclare. If it's private in LoginView, we need it here.
// Assuming it's in a shared utility or I should add it just in case if not global.
// Checking previous turn: I removed it from LoginView because it WAS global or in PostsScreen.
// So I will assume it is available. If not, I will fix.

struct HomeProfessionalHostView: View {
    @State private var path = NavigationPath()
    @State private var professionalId: String = ""

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
