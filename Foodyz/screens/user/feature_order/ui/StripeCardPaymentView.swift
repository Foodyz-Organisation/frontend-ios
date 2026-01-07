import SwiftUI
#if canImport(Stripe)
import Stripe
#endif

// MARK: - Stripe Card Payment View
struct StripeCardPaymentView: View {
    @ObservedObject var cartViewModel: CartViewModel
    let orderResponse: CreateOrderResponse
    let totalPrice: Double
    let onPaymentSuccess: () -> Void
    let onPaymentError: (String) -> Void
    let onCancel: () -> Void
    
    @State private var cardNumber: String = ""
    @State private var selectedMonth: Int = 1 // 1-12
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date()) // Current year
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isProcessing = false
    @State private var selectedTestCard: TestCard? = nil
    
    // Month options (1-12)
    let months: [Int] = Array(1...12)
    let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    // Year options (current year to 10 years ahead)
    var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 10))
    }
    
    // Stripe Test Cards
    struct TestCard {
        let name: String
        let number: String
        let month: Int // 1-12
        let year: Int // Full year (e.g., 2034)
        let cvv: String
        let description: String
    }
    
    let testCards: [TestCard] = [
                                    TestCard(
                                        name: "Visa Success",
                                        number: "4242424242424242",
                                        month: 12,
                                        year: 2034,
                                        cvv: "123",
                                        description: "Succeeds immediately"
                                    ),
                                    TestCard(
                                        name: "Visa Decline",
                                        number: "4000000000000002",
                                        month: 12,
                                        year: 2034,
                                        cvv: "123",
                                        description: "Declines immediately"
                                    ),
                                    TestCard(
                                        name: "Visa 3D Secure",
                                        number: "4000002500003155",
                                        month: 12,
                                        year: 2034,
                                        cvv: "123",
                                        description: "Requires authentication"
                                    ),
                                    TestCard(
                                        name: "Mastercard Success",
                                        number: "5555555555554444",
                                        month: 12,
                                        year: 2034,
                                        cvv: "123",
                                        description: "Succeeds immediately"
                                    )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Order Summary
                    PaymentOrderSummaryCard(total: totalPrice)
                    
                    // Payment Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(Color(hex: 0xFF8B5CF6))
                            Text("Card Payment")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                        }
                        
                        Text("Enter your card details to complete the payment")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Divider()
                        
                        // Test Cards Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("🧪 Test Cards (Tap to fill)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                            
                            ForEach(testCards.indices, id: \.self) { index in
                                TestCardButton(
                                    card: testCards[index],
                                    isSelected: selectedTestCard?.name == testCards[index].name,
                                    onTap: {
                                        selectedTestCard = testCards[index]
                                        cardNumber = testCards[index].number
                                        selectedMonth = testCards[index].month
                                        selectedYear = testCards[index].year
                                        cvv = testCards[index].cvv
                                        cardholderName = "Test User"
                                    }
                                )
                            }
                        }
                        
                        Divider()
                        
                        // Card Details Form
                        VStack(spacing: 16) {
                            // Cardholder Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cardholder Name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: 0xFF1F2A37))
                                TextField("John Doe", text: $cardholderName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            // Card Number
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Card Number")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: 0xFF1F2A37))
                                TextField("1234 5678 9012 3456", text: $cardNumber)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)
                                    .onChange(of: cardNumber) { newValue in
                                        // Format card number with spaces
                                        let formatted = formatCardNumber(newValue)
                                        if formatted != newValue {
                                            cardNumber = formatted
                                        }
                                    }
                            }
                            
                            HStack(spacing: 12) {
                                // Expiry Month Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Month")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: 0xFF1F2A37))
                                    Menu {
                                        Picker("Month", selection: $selectedMonth) {
                                            ForEach(months, id: \.self) { month in
                                                Text(String(format: "%02d - %@", month, monthNames[month - 1]))
                                                    .tag(month)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(String(format: "%02d - %@", selectedMonth, monthNames[selectedMonth - 1]))
                                                .foregroundColor(Color(hex: 0xFF1F2A37))
                                                .font(.system(size: 15))
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 11))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: 0xFFF3F4F6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                // Expiry Year Picker
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Year")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: 0xFF1F2A37))
                                    Menu {
                                        Picker("Year", selection: $selectedYear) {
                                            ForEach(years, id: \.self) { year in
                                                Text("\(year)")
                                                    .tag(year)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text("\(selectedYear)")
                                                .foregroundColor(Color(hex: 0xFF1F2A37))
                                                .font(.system(size: 15))
                                            Spacer()
                                            Image(systemName: "chevron.down")
                                                .foregroundColor(.gray)
                                                .font(.system(size: 11))
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: 0xFFF3F4F6))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                // CVV
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("CVV")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: 0xFF1F2A37))
                                    TextField("123", text: $cvv)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .keyboardType(.numberPad)
                                        .onChange(of: cvv) { newValue in
                                            // Limit CVV to 3-4 digits
                                            if newValue.count > 4 {
                                                cvv = String(newValue.prefix(4))
                                            }
                                        }
                                }
                            }
                        }
                        
                        // Payment Info
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(Color(hex: 0xFF3B82F6))
                                Text("Payment Intent ID")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            Text(orderResponse.paymentIntentId ?? "N/A")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(Color(hex: 0xFF1F2A37))
                                .padding(8)
                                .background(Color(hex: 0xFFE5E7EB))
                                .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                }
                .padding(16)
            }
            
            // Bottom Bar
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
                
                Button(action: processPayment) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    } else {
                        Text("Pay \(String(format: "%.2f", totalPrice)) DT")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: 0xFF1F2A37))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isFormValid ? Color(hex: 0xFFFFC107) : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                }
                .disabled(!isFormValid || isProcessing)
            }
            .padding(16)
            .background(Color.white)
        }
    }
    
    private var isFormValid: Bool {
        !cardNumber.replacingOccurrences(of: " ", with: "").isEmpty &&
        cardNumber.replacingOccurrences(of: " ", with: "").count >= 13 &&
        selectedMonth >= 1 && selectedMonth <= 12 &&
        selectedYear >= Calendar.current.component(.year, from: Date()) &&
        !cvv.isEmpty &&
        cvv.count >= 3 &&
        !cardholderName.isEmpty
    }
    
    private func formatCardNumber(_ number: String) -> String {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        let chunks = cleaned.chunked(into: 4)
        return chunks.joined(separator: " ")
    }
    
    private func processPayment() {
        guard let paymentIntentId = orderResponse.paymentIntentId else {
            onPaymentError("Payment Intent ID is missing")
            return
        }
        
        isProcessing = true
        
        // Validate card details
        let cleanedCardNumber = cardNumber.replacingOccurrences(of: " ", with: "")
        if cleanedCardNumber.count < 13 {
            isProcessing = false
            onPaymentError("Invalid card number")
            return
        }
        
        print("💳 Processing payment with PaymentIntent: \(paymentIntentId)")
        print("💳 Card: \(cleanedCardNumber.prefix(4))****\(cleanedCardNumber.suffix(4))")
        print("💳 Expiry: \(selectedMonth)/\(selectedYear)")
        print("💳 CVV: ***")
        
        // Create PaymentMethod using Stripe SDK
        createPaymentMethod(
            cardNumber: cleanedCardNumber,
            expiryMonth: selectedMonth,
            expiryYear: selectedYear,
            cvv: cvv,
            cardholderName: cardholderName.isEmpty ? nil : cardholderName,
            paymentIntentId: paymentIntentId
        )
    }
    
    private func createPaymentMethod(
        cardNumber: String,
        expiryMonth: Int,
        expiryYear: Int,
        cvv: String,
        cardholderName: String?,
        paymentIntentId: String
    ) {
        // ⚠️ IMPORTANT: Use Stripe SDK to create PaymentMethod CLIENT-SIDE
        // DO NOT send raw card details to backend - Stripe blocks this and causes 400/500 errors!
        
        // 🧪 TEST MODE: Use mock PaymentMethod ID for testing (bypasses Stripe SDK)
        // Set to false when Stripe SDK is integrated
        let useTestMode = true // TODO: Set to false when Stripe SDK is ready
        
        if useTestMode {
            // Generate a fake PaymentMethod ID for testing
            // Format: pm_ followed by random characters (Stripe format)
            let testPaymentMethodId = "pm_test_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))"
            
            print("🧪 TEST MODE: Using mock PaymentMethod ID")
            print("💳 Card: \(cardNumber.prefix(4))****\(cardNumber.suffix(4))")
            print("💳 Expiry: \(expiryMonth)/\(expiryYear)")
            print("🧪 Mock PaymentMethod ID: \(testPaymentMethodId)")
            print("⚠️ TEST MODE: Simulating payment success (NOT calling backend)")
            print("✅ Payment will be simulated locally without backend call")
            
            // TEST MODE: Simulate success directly without calling backend
            // Backend would fail because test PaymentMethod IDs don't exist in Stripe
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isProcessing = false
                print("✅ TEST MODE: Payment simulated successfully")
                print("⚠️ NOTE: This is a TEST. Real payments require valid Stripe keys.")
                self.cartViewModel.clearCart()
                self.onPaymentSuccess()
            }
            return
        }
        
        // Check if Stripe SDK is available
        #if canImport(Stripe)
        // Configure Stripe with your publishable key
        // Get this from: https://dashboard.stripe.com/apikeys
        // For testing, use: pk_test_...
        // TODO: Replace with your actual Stripe publishable key
        STPAPIClient.shared.publishableKey = "pk_test_YOUR_PUBLISHABLE_KEY_HERE"
        
        print("💳 Creating PaymentMethod using Stripe SDK (client-side)...")
        print("💳 Card: \(cardNumber.prefix(4))****\(cardNumber.suffix(4))")
        print("💳 Expiry: \(expiryMonth)/\(expiryYear)")
        
        // Create card parameters
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardNumber // Already cleaned (no spaces)
        cardParams.expMonth = NSNumber(value: expiryMonth) // Number 1-12
        cardParams.expYear = NSNumber(value: expiryYear) // Full year (e.g., 2034, not 34)
        cardParams.cvc = cvv
        
        // Create billing details
        let billingDetails = STPPaymentMethodBillingDetails()
        if let name = cardholderName, !name.isEmpty {
            billingDetails.name = name
        }
        
        // Create payment method parameters
        let paymentMethodParams = STPPaymentMethodParams(
            card: cardParams,
            billingDetails: billingDetails,
            metadata: nil
        )
        
        // Create PaymentMethod using Stripe SDK (CLIENT-SIDE)
        // This is the CORRECT way - Stripe SDK handles card details securely
        STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { paymentMethod, error in
            DispatchQueue.main.async {
                if let error = error {
                    isProcessing = false
                    let errorMessage = "Failed to create payment method: \(error.localizedDescription)"
                    print("❌ \(errorMessage)")
                    onPaymentError(errorMessage)
                    return
                }
                
                guard let paymentMethodId = paymentMethod?.stripeId else {
                    isProcessing = false
                    let errorMessage = "Failed to get payment method ID from Stripe"
                    print("❌ \(errorMessage)")
                    onPaymentError(errorMessage)
                    return
                }
                
                print("✅ PaymentMethod created successfully: \(paymentMethodId)")
                print("📤 Sending paymentMethodId to backend (NOT card details!)")
                
                // Now send ONLY paymentMethodId to backend (not card details!)
                // Backend expects: { paymentIntentId, paymentMethodId }
                self.confirmPaymentWithMethodId(
                    paymentIntentId: paymentIntentId,
                    paymentMethodId: paymentMethodId
                )
            }
        }
        
        #else
        // Stripe SDK not integrated - show clear error
        isProcessing = false
        let errorMessage = """
        ⚠️ Stripe SDK is not integrated.
        
        To fix this:
        1. Add Stripe iOS SDK via Swift Package Manager:
           - File → Add Packages...
           - URL: https://github.com/stripe/stripe-ios
        2. Add 'import Stripe' at the top of this file
        3. Configure your Stripe publishable key
        
        See STRIPE_INTEGRATION_GUIDE.md for detailed instructions.
        
        ⚠️ DO NOT send raw card details to backend - Stripe blocks this!
        """
        print("❌ \(errorMessage)")
        onPaymentError("Stripe SDK required. Please integrate Stripe SDK first. See STRIPE_INTEGRATION_GUIDE.md")
        #endif
    }
    
    private func confirmPaymentWithMethodId(paymentIntentId: String, paymentMethodId: String) {
        // Detect if we're in test mode (mock PaymentMethod IDs generated locally)
        // Test PaymentMethod IDs start with "pm_test_" and are generated by our mock code
        // We check only paymentMethodId because paymentIntentId might come from backend
        let isTestMode = paymentMethodId.hasPrefix("pm_test_")
        
        if isTestMode {
            // TEST MODE: Simulate success without calling backend
            // Backend would fail because test PaymentMethod IDs don't exist in Stripe
            print("🧪 TEST MODE DETECTED: Simulating payment success")
            print("💳 PaymentIntent ID: \(paymentIntentId)")
            print("💳 PaymentMethod ID: \(paymentMethodId)")
            print("⚠️ NOT calling backend - test PaymentMethod IDs are not valid in Stripe")
            print("✅ Simulating successful payment confirmation...")
            
            // Simulate network delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isProcessing = false
                print("✅ TEST MODE: Payment simulated successfully")
                print("⚠️ NOTE: This is a TEST. Real payments require valid Stripe keys.")
                cartViewModel.clearCart()
                onPaymentSuccess()
            }
            return
        }
        
        // REAL MODE: Call backend to confirm payment with Stripe
        let repository = OrderRepository.shared
        repository.confirmPayment(
            paymentIntentId: paymentIntentId,
            paymentMethodId: paymentMethodId
        ) { result in
            DispatchQueue.main.async {
                isProcessing = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        print("✅ Payment confirmed successfully")
                        cartViewModel.clearCart()
                        onPaymentSuccess()
                    } else {
                        onPaymentError("Payment confirmation failed")
                    }
                    
                case .failure(let error):
                    let errorMessage = error.localizedDescription
                    print("❌ Payment confirmation error: \(errorMessage)")
                    
                    // Check if error is related to test mode IDs
                    if errorMessage.contains("No such PaymentMethod") && paymentMethodId.hasPrefix("pm_test_") {
                        onPaymentError("""
                        ⚠️ Test Mode Error
                        
                        The backend tried to confirm a test PaymentMethod ID, but Stripe doesn't recognize it.
                        
                        To fix:
                        1. Set useTestMode = false in StripeCardPaymentView.swift
                        2. Integrate Stripe SDK (see STRIPE_INTEGRATION_GUIDE.md)
                        3. Use real Stripe keys in backend .env
                        
                        Or continue testing UI only (payment will be simulated).
                        """)
                    } else {
                        onPaymentError(errorMessage)
                    }
                }
            }
        }
    }
}

// MARK: - Test Card Button
struct TestCardButton: View {
    let card: StripeCardPaymentView.TestCard
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0xFF1F2A37))
                    Text(card.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(card.number)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: 0xFF10B981))
                }
            }
            .padding(12)
            .background(isSelected ? Color(hex: 0xFF10B981).opacity(0.1) : Color(hex: 0xFFF3F4F6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: 0xFF10B981) : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - String Extension for Chunking
extension String {
    func chunked(into size: Int) -> [String] {
        var chunks: [String] = []
        var index = startIndex
        
        while index < endIndex {
            let endIndex = self.index(index, offsetBy: size, limitedBy: self.endIndex) ?? self.endIndex
            chunks.append(String(self[index..<endIndex]))
            index = endIndex
        }
        
        return chunks
    }
}

