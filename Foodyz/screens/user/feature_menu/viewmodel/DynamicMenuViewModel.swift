import Foundation
import Combine

// MARK: - Dynamic Menu ViewModel
class DynamicMenuViewModel: ObservableObject {
    @Published var menuItems: [MenuItemResponse] = []
    @Published var isLoading = true // Start with loading = true so we show loading view immediately
    @Published var errorMessage: String?
    @Published var selectedCategory: Category?
    @Published var activeDeals: [Deal] = []
    
    private let repository = MenuItemRepository()
    private let dealsService = DealsAPIService.shared
    private let professionalId: String
    private let authToken: String
    
    init(professionalId: String, authToken: String = "mock_token") {
        self.professionalId = professionalId
        self.authToken = authToken
        fetchMenu()
        fetchDeals()
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
        print("📋 [DynamicMenuViewModel] fetchMenu() called")
        print("📋 [DynamicMenuViewModel] professionalId: \(professionalId)")
        print("📋 [DynamicMenuViewModel] authToken: \(authToken.isEmpty ? "EMPTY" : String(authToken.prefix(20)) + "...")")
        
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
                    
                    print("✅ [DynamicMenuViewModel] Menu loaded successfully")
                    print("✅ [DynamicMenuViewModel] Total items: \(allItems.count)")
                    print("✅ [DynamicMenuViewModel] Categories: \(groupedMenu.keys.joined(separator: ", "))")
                    
                    // Debug first item details
                    if let firstItem = allItems.first {
                        print("✅ [DynamicMenuViewModel] First item: \(firstItem.name)")
                        print("✅ [DynamicMenuViewModel]   - Ingredients: \(firstItem.ingredients.count)")
                        print("✅ [DynamicMenuViewModel]   - Options: \(firstItem.options.count)")
                        print("✅ [DynamicMenuViewModel]   - Price: \(firstItem.price)")
                    }
                    
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("❌ [DynamicMenuViewModel] Error loading menu: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Category Selection
    func selectCategory(_ category: Category?) {
        selectedCategory = category
    }
    
    // MARK: - Fetch Deals
    func fetchDeals() {
        Task {
            do {
                let allDeals = try await dealsService.getAllDeals()
                // Filter deals for this professional that are active and not expired
                let now = Date()
                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                let filteredDeals = allDeals.filter { deal in
                    // Must be active
                    guard deal.isActive else { return false }
                    
                    // Must belong to this professional
                    guard deal.professionalId == professionalId else { return false }
                    
                    // Check start date
                    if let startDate = isoFormatter.date(from: deal.startDate) {
                        guard startDate <= now else { return false }
                    }
                    
                    // Must not be expired
                    if let endDate = isoFormatter.date(from: deal.endDate) {
                        guard endDate >= now else { return false }
                    }
                    
                    return true
                }
                
                await MainActor.run {
                    self.activeDeals = filteredDeals
                    print("✅ [DynamicMenuViewModel] Loaded \(filteredDeals.count) active deals for professional \(professionalId)")
                }
            } catch {
                print("⚠️ [DynamicMenuViewModel] Error fetching deals: \(error.localizedDescription)")
                // Don't set error state - deals are optional
            }
        }
    }
    
    // MARK: - Find Applicable Deal for Menu Item
    func getApplicableDeal(for menuItem: MenuItemResponse) -> Deal? {
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return activeDeals.first { deal in
            // Check if deal has started
            if let startDate = isoFormatter.date(from: deal.startDate) {
                guard startDate <= now else { return false }
            }
            
            // Check if deal is still valid (not expired)
            if let endDate = isoFormatter.date(from: deal.endDate) {
                guard endDate >= now else { return false }
            }
            
            // Check deal scope
            switch deal.scope {
            case "ALL":
                return true
            case "CATEGORY":
                if let applicableCategory = deal.applicableCategory {
                    return menuItem.category.rawValue == applicableCategory
                }
                return false
            case "ITEMS":
                if let applicableItems = deal.applicableItems {
                    return applicableItems.contains(menuItem.id)
                }
                return false
            default:
                return false
            }
        }
    }
}
