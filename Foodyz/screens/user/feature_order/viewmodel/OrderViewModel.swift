import Foundation
import Combine

// MARK: - Order ViewModel
class OrderViewModel: ObservableObject {
    @Published var orders: [OrderResponse] = []
    @Published var singleOrder: OrderResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository = OrderRepository.shared
    
    // MARK: - Create Order
    func createOrder(request: CreateOrderRequest, completion: @escaping (Result<OrderResponse, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        repository.createOrder(request: request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let order):
                    self?.singleOrder = order
                    completion(.success(order))
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Load Orders by User
    func loadOrdersByUser(userId: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getOrdersByUser(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let orders):
                    self?.orders = orders
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Load Order by ID
    func loadOrderById(orderId: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getOrderById(orderId: orderId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let order):
                    self?.singleOrder = order
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Load Orders by Professional
    func loadOrdersByProfessional(professionalId: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getProfessionalOrders(professionalId: professionalId, token: "mock_token") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let orders):
                    self?.orders = orders
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Load Pending Orders (for professionals)
    func loadPendingOrders(professionalId: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getPendingOrders(professionalId: professionalId, token: "mock_token") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let orders):
                    self?.orders = orders
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Update Order Status
    func updateOrderStatus(orderId: String, status: OrderStatus, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        repository.updateOrderStatus(orderId: orderId, status: status, token: "mock_token") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let updatedOrder):
                    // Update the order in the list
                    if let index = self?.orders.firstIndex(where: { $0._id == orderId }) {
                        self?.orders[index] = updatedOrder
                    }
                    completion(true)
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Convenience Methods for Accept/Refuse
    func acceptOrder(orderId: String, completion: @escaping (Bool) -> Void) {
        updateOrderStatus(orderId: orderId, status: .confirmed, completion: completion)
    }
    
    func refuseOrder(orderId: String, completion: @escaping (Bool) -> Void) {
        updateOrderStatus(orderId: orderId, status: .refused, completion: completion)
    }
}
