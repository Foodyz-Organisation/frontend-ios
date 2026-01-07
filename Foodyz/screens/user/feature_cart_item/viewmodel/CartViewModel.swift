import Foundation
import Combine

// MARK: - Cart UI State
enum CartUiState: Equatable {
    case loading
    case success(CartResponse)
    case error(String)
    case empty
}

// MARK: - Cart ViewModel
class CartViewModel: ObservableObject {
    @Published var uiState: CartUiState = .loading
    
    private let repository = CartRepository.shared
    var userId: String // Made internal so AppNavigation can check it
    private var currentProfessionalId: String? // Track which professional's items are in the cart
    
    init(userId: String) {
        self.userId = userId
    }
    
    private var token: String {
        TokenManager.shared.getAccessToken() ?? ""
    }
    
    // MARK: - Load Cart
    func loadCart(professionalId: String? = nil) {
        print("🔄 [CartViewModel] loadCart() called")
        print("🔄 [CartViewModel] userId: \(userId)")
        print("🔄 [CartViewModel] token: \(token.isEmpty ? "EMPTY" : String(token.prefix(20)) + "...")")
        uiState = .loading
        
        repository.getUserCart(userId: userId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    print("✅ [CartViewModel] Cart loaded successfully: \(cart.items.count) items")
                    cart.items.enumerated().forEach { index, item in
                        print("✅ [CartViewModel]   Item \(index): \(item.name) (qty=\(item.quantity), price=\(item.calculatedPrice))")
                    }
                    print("✅ [CartViewModel] Total amount: \(cart.totalAmount)")
                    
                    // If a professionalId is provided and cart has items, check if they match
                    if let professionalId = professionalId, !cart.items.isEmpty {
                        if let existingProfessionalId = self?.currentProfessionalId, existingProfessionalId != professionalId {
                            print("⚠️ [CartViewModel] Cart contains items from different professional (\(existingProfessionalId) vs \(professionalId)). Clearing cart...")
                            self?.clearCart()
                            return
                        }
                        // Update current professional ID if cart has items
                        if !cart.items.isEmpty {
                            self?.currentProfessionalId = professionalId
                        }
                    }
                    
                    if cart.items.isEmpty {
                        print("⚠️ [CartViewModel] Cart is empty, setting state to .empty")
                        self?.uiState = .empty
                        self?.currentProfessionalId = nil
                    } else {
                        print("✅ [CartViewModel] Cart has items, setting state to .success")
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    print("❌ [CartViewModel] Cart load failed: \(error)")
                    print("❌ [CartViewModel] Error description: \(error.localizedDescription)")
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Check and Clear Cart for Different Professional
    func checkAndClearCartIfNeeded(for professionalId: String) {
        // If cart has items and we're switching to a different professional, clear the cart
        if let existingProfessionalId = currentProfessionalId, existingProfessionalId != professionalId {
            if case .success(let cart) = uiState, !cart.items.isEmpty {
                print("⚠️ [CartViewModel] Switching from professional \(existingProfessionalId) to \(professionalId). Clearing cart...")
                clearCart()
            }
        }
        // Update current professional ID
        currentProfessionalId = professionalId
    }
    
    // MARK: - Add Item to Cart
    func addItem(request: AddToCartRequest, professionalId: String) {
        print("🛒 [CartViewModel] ========== addItem() called ==========")
        print("🛒 [CartViewModel] menuItemId: \(request.menuItemId)")
        print("🛒 [CartViewModel] name: \(request.name)")
        print("🛒 [CartViewModel] quantity: \(request.quantity)")
        print("🛒 [CartViewModel] calculatedPrice: \(request.calculatedPrice)")
        print("🛒 [CartViewModel] professionalId: \(professionalId)")
        print("🛒 [CartViewModel] chosenIngredients count: \(request.chosenIngredients.count)")
        request.chosenIngredients.enumerated().forEach { index, ingredient in
            print("🛒 [CartViewModel]   Ingredient \(index): \(ingredient.name) (default: \(ingredient.isDefault), intensity: \(ingredient.intensityValue?.description ?? "nil"))")
        }
        print("🛒 [CartViewModel] chosenOptions count: \(request.chosenOptions.count)")
        request.chosenOptions.enumerated().forEach { index, option in
            print("🛒 [CartViewModel]   Option \(index): \(option.name) (price: \(option.price))")
        }
        print("🛒 [CartViewModel] userId: \(userId)")
        print("🛒 [CartViewModel] token: \(token.isEmpty ? "EMPTY ⚠️" : String(token.prefix(20)) + "...")")
        print("🛒 [CartViewModel] Current UI state before add: \(String(describing: uiState))")
        
        // Check if cart has items from a different professional
        if let existingProfessionalId = currentProfessionalId, existingProfessionalId != professionalId {
            print("⚠️ [CartViewModel] Cart contains items from different professional (\(existingProfessionalId) vs \(professionalId)). Clearing cart...")
            clearCart { [weak self] in
                // After clearing, add the new item
                self?.addItemAfterClear(request: request, professionalId: professionalId)
            }
            return
        }
        
        // Update current professional ID
        currentProfessionalId = professionalId
        
        repository.addItemToCart(
            request: request,
            userId: userId,
            token: token
        ) { [weak self] result in
            DispatchQueue.main.async {
                print("🛒 [CartViewModel] ========== addItem response received ==========")
                switch result {
                case .success(let cart):
                    print("✅ [CartViewModel] Item added successfully. Cart has \(cart.items.count) items")
                    cart.items.enumerated().forEach { index, item in
                        print("✅ [CartViewModel]   Item \(index): \(item.name) (qty=\(item.quantity), price=\(item.calculatedPrice))")
                    }
                    print("✅ [CartViewModel] Cart total amount: \(cart.totalAmount)")
                    if cart.items.isEmpty {
                        print("⚠️ [CartViewModel] Cart is empty after add, setting state to .empty")
                        self?.uiState = .empty
                        self?.currentProfessionalId = nil
                    } else {
                        print("✅ [CartViewModel] Setting UI state to .success with \(cart.items.count) items")
                        self?.uiState = .success(cart)
                    }
                case .failure(let error):
                    print("❌ [CartViewModel] ========== FAILED TO ADD ITEM ==========")
                    print("❌ [CartViewModel] Error: \(error)")
                    print("❌ [CartViewModel] Error description: \(error.localizedDescription)")
                    if case .networkError(let underlyingError) = error {
                        print("❌ [CartViewModel] Network error: \(underlyingError)")
                        if let urlError = underlyingError as? URLError {
                            print("❌ [CartViewModel] URLError code: \(urlError.code.rawValue)")
                        }
                    }
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // Helper method to add item after clearing cart
    private func addItemAfterClear(request: AddToCartRequest, professionalId: String) {
        currentProfessionalId = professionalId
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
                        self?.currentProfessionalId = nil
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
    func clearCart(completion: (() -> Void)? = nil) {
        repository.clearCart(userId: userId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let cart):
                    if cart.items.isEmpty {
                        self?.uiState = .empty
                        self?.currentProfessionalId = nil
                    } else {
                        self?.uiState = .success(cart)
                    }
                    completion?()
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                    completion?()
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
        paymentMethod: PaymentMethod,
        onSuccess: @escaping (CreateOrderResponse) -> Void,
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
        
        // Convert cart items to order items (including intensity data)
        let orderItems = cart.items.map { cartItem in
            print("🛒 [CartViewModel] Converting cart item: \(cartItem.name)")
            print("🛒 [CartViewModel]   Ingredients count: \(cartItem.chosenIngredients.count)")
            
            cartItem.chosenIngredients.forEach { ingredient in
                print("🛒 [CartViewModel]     - \(ingredient.name): intensityValue=\(ingredient.intensityValue?.description ?? "nil"), type=\(ingredient.intensityType?.rawValue ?? "nil"), color=\(ingredient.intensityColor ?? "nil")")
            }
            
            let orderItem = OrderItemRequest(
                menuItemId: cartItem.menuItemId,
                name: cartItem.name,
                quantity: cartItem.quantity,
                chosenIngredients: cartItem.chosenIngredients.map {
                    ChosenIngredientRequest(
                        name: $0.name,
                        isDefault: $0.isDefault,
                        intensityType: $0.intensityType,
                        intensityColor: $0.intensityColor,
                        intensityValue: $0.intensityValue
                    )
                },
                chosenOptions: cartItem.chosenOptions.map {
                    ChosenOptionRequest(name: $0.name, price: $0.price)
                },
                calculatedPrice: cartItem.calculatedPrice
            )
            
            print("🛒 [CartViewModel]   ✅ Created OrderItemRequest with \(orderItem.chosenIngredients?.count ?? 0) ingredients")
            return orderItem
        }
        
        // Calculate total price
        let totalPrice = cart.totalAmount
        
        // Create order request with payment method
        let orderRequest = CreateOrderRequest(
            userId: userId,
            professionalId: professionalId,
            orderType: orderType,
            scheduledTime: nil,
            items: orderItems,
            totalPrice: totalPrice,
            deliveryAddress: deliveryAddress,
            notes: notes,
            paymentMethod: paymentMethod
        )
        
        // Create order via repository
        let orderRepository = OrderRepository.shared
        orderRepository.createOrder(request: orderRequest, completion: { [weak self] (result: Result<CreateOrderResponse, APIError>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // For CASH payments, order is created and payment is already succeeded
                    // For CARD payments, order is created but payment needs confirmation
                    if paymentMethod == .cash {
                        // CASH: Payment already succeeded, clear cart and return response
                        self?.clearCart()
                        onSuccess(response)
                    } else if paymentMethod == .card {
                        // CARD: Order created with pending payment
                        // Return response with clientSecret and paymentIntentId for payment form
                        // Don't clear cart yet - wait for payment confirmation
                        onSuccess(response)
                    }
                    
                case .failure(let error):
                    onError(error.localizedDescription)
                }
            }
        })
    }
}
