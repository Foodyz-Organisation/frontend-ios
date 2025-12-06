import SwiftUI

// MARK: - Order History Screen
struct OrderHistoryScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OrderViewModel()
    
    let userId: String
    let onOrderClick: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            OrderHistoryTopBar(onBackClick: { dismiss() })
            
            // Content
            if viewModel.isLoading {
                LoadingOrdersView()
            } else if viewModel.orders.isEmpty {
                EmptyOrdersView()
            } else {
                OrdersList(orders: viewModel.orders, onOrderClick: onOrderClick)
            }
        }
        .background(Color(hex: 0xFFF9FAFB))
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(orders) { order in
                    OrderItemCard(order: order, onClick: onOrderClick)
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
                
                // Date
                Text(order.createdAt.prefix(10))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0xFF9CA3AF))
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
