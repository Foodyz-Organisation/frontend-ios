import Foundation
import Combine

// MARK: - Cart UI State
enum CartUiState {
    case loading
    case success(CartResponse)
    case error(String)
    case empty
}

// MARK: - Cart ViewModel
class CartViewModel: ObservableObject {
    @Published var uiState: CartUiState = .loading
    
    private let repository = CartRepository.shared
    private var userId: String
    private let token: String = "mock_token" // TODO: Get from auth service
    
    init(userId: String) {
        self.userId = userId
    }
    
    // MARK: - Load Cart
    func loadCart() {
        uiState = .loading
        
        repository.getUserCart(userId: userId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    print("✅ Cart loaded successfully: \(cart.items.count) items")
                    if cart.items.isEmpty {
                        self?.uiState = .empty
                    } else {
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    print("❌ Cart load failed: \(error)")
                    print("❌ Error description: \(error.localizedDescription)")
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Add Item to Cart
    func addItem(request: AddToCartRequest) {
        repository.addItemToCart(
            request: request,
            userId: userId,
            token: token
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    if cart.items.isEmpty {
                        self?.uiState = .empty
                    } else {
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Update Quantity
    func updateQuantity(index: Int, newQuantity: Int) {
        repository.updateItemQuantity(
            itemIndex: index,
            quantity: newQuantity,
            userId: userId,
            token: token
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    if cart.items.isEmpty {
                        self?.uiState = .empty
                    } else {
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Remove Item
    func removeItem(index: Int) {
        repository.removeItem(
            itemIndex: index,
            userId: userId,
            token: token
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    if cart.items.isEmpty {
                        self?.uiState = .empty
                    } else {
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Clear Cart
    func clearCart() {
        repository.clearCart(userId: userId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    if cart.items.isEmpty {
                        self?.uiState = .empty
                    } else {
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Get Cart Items
    var cartItems: [CartItemResponse] {
        if case .success(let cart) = uiState {
            return cart.items
        }
        return []
    }
    
    // MARK: - Get Total Price
    var totalPrice: Double {
        if case .success(let cart) = uiState {
            return cart.totalAmount
        }
        return 0.0
    }
    
    // MARK: - Get Item Count
    var itemCount: Int {
        if case .success(let cart) = uiState {
            return cart.itemCount
        }
        return 0
    }
    
    // MARK: - Update User ID
    func updateUserId(_ newUserId: String) {
        self.userId = newUserId
        // Reload cart with new userId
        loadCart()
    }
    
    // MARK: - Checkout - Convert Cart to Order
    func checkout(
        professionalId: String,
        orderType: OrderType,
        deliveryAddress: String? = nil,
        notes: String? = nil,
        onSuccess: @escaping (OrderResponse) -> Void,
        onError: @escaping (String) -> Void
    ) {
        // Validate cart has items
        guard case .success(let cart) = uiState, !cart.items.isEmpty else {
            onError("Cart is empty")
            return
        }
        
        // Validate delivery address for delivery orders
        if orderType == .delivery && (deliveryAddress == nil || deliveryAddress!.isEmpty) {
            onError("Delivery address is required for delivery orders")
            return
        }
        
        // Convert cart items to order items
        let orderItems = cart.items.map { cartItem in
            OrderItemRequest(
                menuItemId: cartItem.menuItemId,
                name: cartItem.name,
                quantity: cartItem.quantity,
                chosenIngredients: cartItem.chosenIngredients.map {
                    ChosenIngredientRequest(name: $0.name, isDefault: $0.isDefault)
                },
                chosenOptions: cartItem.chosenOptions.map {
                    ChosenOptionRequest(name: $0.name, price: $0.price)
                },
                calculatedPrice: cartItem.calculatedPrice
            )
        }
        
        // Calculate total price
        let totalPrice = cart.totalAmount
        
        // Create order request
        let orderRequest = CreateOrderRequest(
            userId: userId,
            professionalId: professionalId,
            orderType: orderType,
            scheduledTime: nil,
            items: orderItems,
            totalPrice: totalPrice,
            deliveryAddress: deliveryAddress,
            notes: notes
        )
        
        // Create order via repository
        let orderRepository = OrderRepository.shared
        orderRepository.createOrder(request: orderRequest, completion: { [weak self] (result: Result<OrderResponse, APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let order):
                    // Clear cart after successful order
                    self?.clearCart()
                    onSuccess(order)
                    
                case .failure(let error):
                    onError(error.localizedDescription)
                }
            }
        })
    }
}
