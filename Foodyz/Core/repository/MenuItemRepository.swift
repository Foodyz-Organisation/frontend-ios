import Foundation
import UIKit

class MenuItemRepository {
    private let api = MenuItemApi.shared

    func getGroupedMenu(professionalId: String, token: String, completion: @escaping (Result<GroupedMenuResponse, APIError>) -> Void) {
        api.getGroupedMenu(professionalId: professionalId, token: token, completion: completion)
    }

    func getMenuItemDetails(id: String, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        api.getMenuItemDetails(id: id, token: token, completion: completion)
    }

    func createMenuItem(payload: CreateMenuItemDto, image: UIImage?, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        api.createMenuItem(payload: payload, image: image, token: token, completion: completion)
    }

    func updateMenuItem(id: String, payload: UpdateMenuItemDto, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        api.updateMenuItem(id: id, payload: payload, token: token, completion: completion)
    }

    func deleteMenuItem(id: String, token: String, completion: @escaping (Result<MenuItemResponse, APIError>) -> Void) {
        api.deleteMenuItem(id: id, token: token, completion: completion)
    }
}
