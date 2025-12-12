import Foundation
import Combine

// MARK: - Dynamic Menu ViewModel
class DynamicMenuViewModel: ObservableObject {
    @Published var menuItems: [MenuItemResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCategory: Category?
    
    private let repository = MenuItemRepository()
    private let professionalId: String
    private let authToken: String
    
    init(professionalId: String, authToken: String = "mock_token") {
        self.professionalId = professionalId
        self.authToken = authToken
        fetchMenu()
    }
    
    // Filtered items based on selected category
    var filteredMenuItems: [MenuItemResponse] {
        guard let category = selectedCategory else {
            return menuItems
        }
        return menuItems.filter { $0.category == category }
    }
    
    // Get available categories from menu items
    var availableCategories: [Category] {
        let categories = Set(menuItems.map { $0.category })
        return Array(categories).sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Fetch Menu
    func fetchMenu() {
        isLoading = true
        errorMessage = nil
        
        repository.getGroupedMenu(professionalId: professionalId, token: authToken) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let groupedMenu):
                    // Flatten all categories into a single list
                    let allItems = groupedMenu.values.flatMap { $0 }
                    self?.menuItems = allItems
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Category Selection
    func selectCategory(_ category: Category?) {
        selectedCategory = category
    }
}
