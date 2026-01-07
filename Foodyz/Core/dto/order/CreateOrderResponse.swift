import Foundation

// MARK: - Create Order Response
// Backend returns different formats:
// - CASH: returns OrderResponse directly (just the order object)
// - CARD: returns { order: OrderResponse, clientSecret: string, paymentIntentId: string }
struct CreateOrderResponse: Codable {
    let order: OrderResponse
    let clientSecret: String?
    let paymentIntentId: String?
    
    // Custom decoder to handle both response formats
    init(from decoder: Decoder) throws {
        // First, try to decode as CARD response (object with order, clientSecret, paymentIntentId)
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           let orderObj = try? container.decode(OrderResponse.self, forKey: .order) {
            // This is a CARD response
            order = orderObj
            clientSecret = try? container.decode(String.self, forKey: .clientSecret)
            paymentIntentId = try? container.decode(String.self, forKey: .paymentIntentId)
        } else {
            // This is a CASH response - decode as OrderResponse directly
            order = try OrderResponse(from: decoder)
            clientSecret = nil
            paymentIntentId = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case order
        case clientSecret
        case paymentIntentId
    }
    
    // Encoder for completeness (though we may not need it)
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(order, forKey: .order)
        try container.encodeIfPresent(clientSecret, forKey: .clientSecret)
        try container.encodeIfPresent(paymentIntentId, forKey: .paymentIntentId)
    }
    
    // Manual initializer for creating test/mock responses
    init(order: OrderResponse, clientSecret: String?, paymentIntentId: String?) {
        self.order = order
        self.clientSecret = clientSecret
        self.paymentIntentId = paymentIntentId
    }
}

// MARK: - Confirm Payment Request
// Backend expects ONLY paymentIntentId and paymentMethodId
// DO NOT send raw card details - Stripe blocks this!
struct ConfirmPaymentRequest: Codable {
    let paymentIntentId: String
    let paymentMethodId: String // PaymentMethod ID created by Stripe SDK (client-side)
}

// MARK: - Confirm Payment Response
struct ConfirmPaymentResponse: Codable {
    let success: Bool
    let order: OrderResponse?
}

