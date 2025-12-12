import Foundation

// MARK: - Order Repository
class OrderRepository {
    static let shared = OrderRepository()
    private let api = OrderApi.shared
    
    private init() {}
    
    // MARK: - Create Order
    func createOrder(
        request: CreateOrderRequest,
        completion: @escaping (Result<OrderResponse, APIError>) -> Void
    ) {
        let token = "mock_token" // TODO: Get from auth service
        api.createOrder(body: request, token: token, completion: completion)
    }
    
    // MARK: - Get Orders by User
    func getOrdersByUser(
        userId: String,
        completion: @escaping (Result<[OrderResponse], APIError>) -> Void
    ) {
        let token = "mock_token" // TODO: Get from auth service
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
        let token = "mock_token" // TODO: Get from auth service
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
}
