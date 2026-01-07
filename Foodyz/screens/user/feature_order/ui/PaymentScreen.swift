import SwiftUI

// MARK: - Payment Screen
struct PaymentScreen: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var cartViewModel: CartViewModel
    
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var showCardPaymentForm = false
    @State private var orderResponse: CreateOrderResponse? = nil
    @State private var showShareLocation = false // Show location prompt after payment
    
    let professionalId: String
    let orderType: OrderType
    let deliveryAddress: String?
    let notes: String?
    let totalPrice: Double
    let onOrderSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            PaymentTopBar(onBackClick: { dismiss() })
            
            // Content
            if showCardPaymentForm, let orderResponse = orderResponse {
                // Show Stripe Card Payment Form
                StripeCardPaymentView(
                    cartViewModel: cartViewModel,
                    orderResponse: orderResponse,
                    totalPrice: totalPrice,
                    onPaymentSuccess: {
                        // Show location prompt after successful card payment
                        showCardPaymentForm = false
                        showShareLocation = true
                    },
                    onPaymentError: { error in
                        alertMessage = "Payment failed: \(error)"
                        showingAlert = true
                    },
                    onCancel: {
                        showCardPaymentForm = false
                        self.orderResponse = nil
                    }
                )
            } else {
                // Show Payment Method Selection
                ScrollView {
                    VStack(spacing: 24) {
                        // Order Summary
                        PaymentOrderSummaryCard(total: totalPrice)
                        
                        // Payment Method Selection
                        PaymentMethodSelection(
                            selectedMethod: $selectedPaymentMethod
                        )
                    }
                    .padding(16)
                }
                
                // Bottom Bar
                PaymentBottomBar(
                    onCancel: { dismiss() },
                    onConfirm: {
                        guard let paymentMethod = selectedPaymentMethod else { return }
                        processPayment(method: paymentMethod)
                    },
                    isConfirmEnabled: selectedPaymentMethod != nil,
                    isProcessing: isProcessing
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(Color(hex: 0xFFF9FAFB))
        .alert("Payment Status", isPresented: $showingAlert) {
            Button("OK") {
                // After dismissing alert, check if we should show location prompt
                if selectedPaymentMethod == .cash && !showShareLocation {
                    // For cash payment, show location prompt after alert
                    showShareLocation = true
                }
            }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showShareLocation) {
            ShareLocationScreen(
                onShare: {
                    showShareLocation = false
                    // Navigate to order history after sharing
                    onOrderSuccess()
                },
                onSkip: {
                    showShareLocation = false
                    // Navigate to order history even if skipped
                    onOrderSuccess()
                }
            )
        }
    }
    
    private func processPayment(method: PaymentMethod) {
        isProcessing = true
        
        cartViewModel.checkout(
            professionalId: professionalId,
            orderType: orderType,
            deliveryAddress: deliveryAddress,
            notes: notes,
            paymentMethod: method,
            onSuccess: { response in
                isProcessing = false
                
                if method == .cash {
                    // CASH: Show location prompt, then navigate to order history
                    alertMessage = "Order placed successfully!"
                    showingAlert = true
                    // Location prompt will be shown when alert is dismissed
                } else if method == .card {
                    // CARD: Show payment form
                    if let clientSecret = response.clientSecret, let paymentIntentId = response.paymentIntentId {
                        self.orderResponse = response
                        self.showCardPaymentForm = true
                    } else {
                        alertMessage = "Payment setup failed. Please try again."
                        showingAlert = true
                    }
                }
            },
            onError: { error in
                isProcessing = false
                
                // Check if error is related to Stripe key issue
                let lowercasedError = error.lowercased()
                if lowercasedError.contains("stripe") || lowercasedError.contains("500") || lowercasedError.contains("invalid api key") || lowercasedError.contains("authentication") {
                    // For testing: Allow showing card form even if backend fails
                    // This lets you test the card payment UI
                    if method == .card {
                        // Create a mock order response for testing
                        let dateFormatter = ISO8601DateFormatter()
                        let now = Date()
                        
                        let mockOrderResponse = CreateOrderResponse(
                            order: OrderResponse(
                                _id: "test_order_\(UUID().uuidString.prefix(8))",
                                userId: TokenManager.shared.getUserId() ?? "test_user",
                                professionalId: professionalId,
                                orderType: orderType,
                                status: .pending,
                                items: cartViewModel.cartItems.map { cartItem in
                                    OrderItemResponse(
                                        menuItemId: cartItem.menuItemId,
                                        name: cartItem.name,
                                        image: nil,
                                        quantity: cartItem.quantity,
                                        chosenIngredients: cartItem.chosenIngredients.map {
                                            ChosenIngredientResponse(
                                                name: $0.name,
                                                isDefault: $0.isDefault,
                                                intensityType: $0.intensityType,
                                                intensityColor: $0.intensityColor,
                                                intensityValue: $0.intensityValue
                                            )
                                        },
                                        chosenOptions: cartItem.chosenOptions.map {
                                            ChosenOptionResponse(name: $0.name, price: $0.price)
                                        },
                                        calculatedPrice: cartItem.calculatedPrice
                                    )
                                },
                                totalPrice: totalPrice,
                                scheduledTime: nil,
                                deliveryAddress: deliveryAddress,
                                notes: notes,
                                createdAt: dateFormatter.string(from: now),
                                updatedAt: dateFormatter.string(from: now)
                            ),
                            clientSecret: "pi_test_secret_\(UUID().uuidString.prefix(24))",
                            paymentIntentId: "pi_test_\(UUID().uuidString.prefix(24))"
                        )
                        
                        self.orderResponse = mockOrderResponse
                        self.showCardPaymentForm = true
                        
                        alertMessage = "⚠️ Backend Stripe error detected.\n\nUsing TEST MODE to show card form.\n\nTo fix: Update backend .env:\nSTRIPE_SECRET_KEY=sk_test_..."
                        showingAlert = true
                    } else {
                        alertMessage = "Payment failed: \(error)\n\n⚠️ Backend Stripe configuration error.\n\nSee: BACKEND_STRIPE_KEY_FIX.md"
                        showingAlert = true
                    }
                } else {
                    alertMessage = error
                    showingAlert = true
                }
            }
        )
    }
}

// MARK: - Payment Top Bar
struct PaymentTopBar: View {
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
            
            Text("Payment")
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

// MARK: - Payment Order Summary Card
struct PaymentOrderSummaryCard: View {
    let total: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color(hex: 0xFFE5E7EB))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(Color(hex: 0xFF9CA3AF))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Summary")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    
                    Text("Complete your payment")
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
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Payment Method Selection
struct PaymentMethodSelection: View {
    @Binding var selectedMethod: PaymentMethod?
    
    let paymentMethods: [(PaymentMethod, String, String)] = [
        (.cash, "Cash", "💵"),
        (.card, "Card", "💳")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Payment Method")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: 0xFF1F2A37))
                .padding(.horizontal, 4)
            
            ForEach(paymentMethods, id: \.0) { method, label, emoji in
                PaymentMethodOption(
                    method: method,
                    label: label,
                    emoji: emoji,
                    isSelected: selectedMethod == method,
                    onTap: { selectedMethod = method }
                )
            }
        }
    }
}

// MARK: - Payment Method Option
struct PaymentMethodOption: View {
    let method: PaymentMethod
    let label: String
    let emoji: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(emoji)
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

// MARK: - Payment Bottom Bar
struct PaymentBottomBar: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void
    let isConfirmEnabled: Bool
    let isProcessing: Bool
    
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
            .disabled(isProcessing)
            
            Button(action: onConfirm) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                } else {
                    Text("Pay Now")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isConfirmEnabled ? Color(hex: 0xFFFFC107) : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
            }
            .disabled(!isConfirmEnabled || isProcessing)
        }
        .padding(16)
        .background(Color.white)
    }
}

