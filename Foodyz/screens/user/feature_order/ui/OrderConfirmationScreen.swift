import SwiftUI

// MARK: - Order Confirmation Screen
struct OrderConfirmationScreen: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var cartViewModel: CartViewModel
    
    @State private var selectedOrderType: OrderType?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let professionalId: String
    let onOrderSuccess: () -> Void
    
    var cartItems: [CartItemResponse] {
        cartViewModel.cartItems
    }
    
    var orderTotal: Double {
        cartViewModel.totalPrice
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            OrderConfirmationTopBar(onBackClick: { dismiss() })
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Cart Summary
                    CartSummaryCard(items: cartItems, total: orderTotal)
                    
                    // Order Type Selection
                    OrderTypeSelection(
                        selectedType: $selectedOrderType
                    )
                }
                .padding(16)
            }
            
            // Bottom Bar
            ConfirmationBottomBar(
                onCancel: { dismiss() },
                onConfirm: {
                    guard let orderType = selectedOrderType else { return }
                    cartViewModel.checkout(
                        professionalId: professionalId,
                        orderType: orderType,
                        onSuccess: { order in
                            alertMessage = "Order placed successfully!"
                            showingAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                onOrderSuccess()
                            }
                        },
                        onError: { error in
                            alertMessage = error
                            showingAlert = true
                        }
                    )
                },
                isConfirmEnabled: selectedOrderType != nil
            )
        }
        .background(Color(hex: 0xFFF9FAFB))
        .alert("Order Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Order Confirmation Top Bar
struct OrderConfirmationTopBar: View {
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
            
            Text("Your Order")
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

// MARK: - Cart Summary Card
struct CartSummaryCard: View {
    let items: [CartItemResponse]
    let total: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: 0xFFE5E7EB))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "bag.fill")
                            .foregroundColor(Color(hex: 0xFF9CA3AF))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order Summary")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    
                    Text("\(items.count) items")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f DT", total))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF8B5CF6))
                }
            }
            
            // Show first few items
            ForEach(items.prefix(3)) { item in
                HStack {
                    Text("• \(item.name)")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    Spacer()
                    Text("x\(item.quantity)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            if items.count > 3 {
                Text("+ \(items.count - 3) more items")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Order Type Selection
struct OrderTypeSelection: View {
    @Binding var selectedType: OrderType?
    
    let orderTypes: [(OrderType, String)] = [
        (.takeaway, "Takeaway"),
        (.eatIn, "Dine-in"),
        (.delivery, "Delivery")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Order Type")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
                .padding(.horizontal, 4)
            
            ForEach(orderTypes, id: \.0) { type, label in
                OrderTypeOption(
                    type: type,
                    label: label,
                    isSelected: selectedType == type,
                    onTap: { selectedType = type }
                )
            }
        }
    }
}

// MARK: - Order Type Option
struct OrderTypeOption: View {
    let type: OrderType
    let label: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(type.emoji)
                .font(.system(size: 24))
            
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xFF1F2A37))
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(isSelected ? Color(hex: 0xFFEF4444) : Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Circle()
                        .fill(Color(hex: 0xFFEF4444))
                        .frame(width: 12, height: 12)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Confirmation Bottom Bar
struct ConfirmationBottomBar: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    let isConfirmEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: 0xFFE5E7EB), lineWidth: 2)
                    )
            }
            
            Button(action: onConfirm) {
                Text("Confirm Order")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xFF1F2A37))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(isConfirmEnabled ? Color(hex: 0xFFFFC107) : Color.gray.opacity(0.3))
                    .cornerRadius(12)
            }
            .disabled(!isConfirmEnabled)
        }
        .padding(16)
        .background(Color.white)
    }
}
