import Foundation
import UIKit
import Combine

// MARK: - UI States
enum MenuListUiState {
    case idle
    case loading
    case success(GroupedMenuResponse)
    case error(String)
}

enum ItemDetailsUiState {
    case idle
    case loading
    case success(MenuItemResponse)
    case error(String)
}

enum MenuItemUiState {
    case idle
    case loading
    case success(MenuItemResponse)
    case error(String)
}

// MARK: - ViewModel
class MenuViewModel: ObservableObject {
    
    private let repository: MenuItemRepository
    
    // Published properties to bind with SwiftUI Views
    @Published var menuListUiState: MenuListUiState = .idle
    @Published var itemDetailsUiState: ItemDetailsUiState = .idle
    @Published var uiState: MenuItemUiState = .idle
    
    init(repository: MenuItemRepository = MenuItemRepository()) {
        self.repository = repository
    }
    
    // --- Fetch grouped menu ---
    func fetchGroupedMenu(professionalId: String, token: String) {
        self.menuListUiState = .loading
        repository.getGroupedMenu(professionalId: professionalId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let grouped):
                    self?.menuListUiState = .success(grouped)
                case .failure(let error):
                    self?.menuListUiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // --- Fetch single item ---
    func fetchMenuItemDetails(id: String, token: String) {
        self.itemDetailsUiState = .loading
        repository.getMenuItemDetails(id: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self?.itemDetailsUiState = .success(item)
                case .failure(let error):
                    self?.itemDetailsUiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // --- Create item ---
    func createMenuItem(payload: CreateMenuItemDto, image: UIImage?, token: String) {
        self.uiState = .loading
        repository.createMenuItem(payload: payload, image: image, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self?.uiState = .success(item)
                    self?.fetchGroupedMenu(professionalId: payload.professionalId, token: token)
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // --- Update item ---
    func updateMenuItem(id: String, payload: UpdateMenuItemDto, professionalId: String, token: String) {
        self.uiState = .loading
        repository.updateMenuItem(id: id, payload: payload, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self?.uiState = .success(item)
                    self?.fetchGroupedMenu(professionalId: professionalId, token: token)
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // --- Delete item ---
    func deleteMenuItem(id: String, professionalId: String, token: String) {
        self.uiState = .loading
        repository.deleteMenuItem(id: id, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let item):
                    self?.uiState = .success(item)
                    self?.fetchGroupedMenu(professionalId: professionalId, token: token)
                case .failure(let error):
                    self?.uiState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // Reset UI state
    func resetUiState() {
        self.uiState = .idle
    }
}
