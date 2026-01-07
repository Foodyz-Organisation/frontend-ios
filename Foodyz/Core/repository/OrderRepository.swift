import Foundation

// MARK: - Order Repository
class OrderRepository {
    static let shared = OrderRepository()
    private let api = OrderApi.shared
    
    private init() {}
    
    // MARK: - Create Order
    // Returns CreateOrderResponse which handles both CASH (order only) and CARD (order + clientSecret + paymentIntentId)
    func createOrder(
        request: CreateOrderRequest,
        completion: @escaping (Result<CreateOrderResponse, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.createOrder(body: request, token: token, completion: completion)
    }
    
    // MARK: - Confirm Payment
    // Backend expects ONLY paymentIntentId and paymentMethodId
    // DO NOT send raw card details - Stripe blocks this!
    func confirmPayment(
        paymentIntentId: String,
        paymentMethodId: String,
        completion: @escaping (Result<ConfirmPaymentResponse, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        let request = ConfirmPaymentRequest(
            paymentIntentId: paymentIntentId,
            paymentMethodId: paymentMethodId
        )
        api.confirmPayment(body: request, token: token, completion: completion)
    }
    
    // MARK: - Get Orders by User
    func getOrdersByUser(
        userId: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.getOrdersByUser(userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Get Orders by Professional
    func getProfessionalOrders(
        professionalId: String,
        token: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        api.getOrdersByProfessional(professionalId: professionalId, token: token, completion: completion)
    }
    
    // MARK: - Get Pending Orders
    func getPendingOrders(
        professionalId: String,
        token: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        api.getPendingOrders(professionalId: professionalId, token: token, completion: completion)
    }
    
    // MARK: - Get Single Order
    func getOrderById(
        orderId: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.getOrderById(orderId: orderId, token: token, completion: completion)
    }
    
    // MARK: - Update Order Status
    func updateOrderStatus(
        orderId: String,
        status: OrderStatus,
        token: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        let request = UpdateOrderStatusRequest(status: status)
        api.updateOrderStatus(orderId: orderId, body: request, token: token, completion: completion)
    }
    
    // MARK: - Convenience Methods
    
    /// Confirm a pending order
    func confirmOrder(
        orderId: String,
        token: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        updateOrderStatus(orderId: orderId, status: .confirmed, token: token, completion: completion)
    }
    
    /// Complete an order
    func completeOrder(
        orderId: String,
        token: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        updateOrderStatus(orderId: orderId, status: .completed, token: token, completion: completion)
    }
    
    /// Cancel an order
    func cancelOrder(
        orderId: String,
        token: String,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        updateOrderStatus(orderId: orderId, status: .cancelled, token: token, completion: completion)
    }
    
    // MARK: - Delete Order
    func deleteOrder(
        orderId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        api.deleteOrder(orderId: orderId, token: token, completion: completion)
    }
    
    // MARK: - Delete All Orders by Professional
    func deleteAllOrdersByProfessional(
        professionalId: String,
        token: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        api.deleteAllOrdersByProfessional(professionalId: professionalId, token: token, completion: completion)
    }
}
