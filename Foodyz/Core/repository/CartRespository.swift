import Foundation

// MARK: - Cart Repository
class CartRepository {
    static let shared = CartRepository()
    private let api = CartApi.shared
    
    private init() {}
    
    // MARK: - Get User Cart
    func getUserCart(
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        api.getUserCart(userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Add Item to Cart
    func addItemToCart(
        request: AddToCartRequest,
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        api.addItemToCart(request: request, userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Update Item Quantity
    func updateItemQuantity(
        itemIndex: Int,
        quantity: Int,
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        let request = UpdateQuantityRequest(quantity: quantity)
        api.updateItemQuantity(itemIndex: itemIndex, request: request, userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Remove Item
    func removeItem(
        itemIndex: Int,
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        api.removeItem(itemIndex: itemIndex, userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Clear Cart
    func clearCart(
        userId: String,
        token: String,
        completion: @escaping (Result<CartResponse, APIError>) -> Void
    ) {
        api.clearCart(userId: userId, token: token, completion: completion)
    }
}
