import Foundation
import Combine

enum DealsUiState {
    case loading
    case success([Deal])
    case error(String)
}

enum DealDetailUiState {
    case loading
    case success(Deal)
    case error(String)
}

@MainActor
class DealsViewModel: ObservableObject {
    @Published var dealsState: DealsUiState = .loading
    @Published var dealDetailState: DealDetailUiState = .loading
    @Published var operationResult: Result<String, Error>?
    @Published var menuGroups: [String: [MenuItemResponse]] = [:]
    
    private let repository = DealsRepository()
    private let menuRepository = MenuItemRepository()
    
    init() {
        print("🎬 DealsViewModel initialisé")
        loadDeals()
    }
    
    func loadDeals() {
        print("📋 loadDeals() appelée")
        dealsState = .loading
        
        Task {
            let result = await repository.getAllDeals()
            
            switch result {
            case .success(let deals):
                print("✅ \(deals.count) deals chargés depuis l'API")
                
                // Filtrer les deals: doivent être actifs ET non expirés
                let activeDeals = deals.filter { deal in
                    // D'abord vérifier le flag isActive
                    guard deal.isActive else {
                        print("⚠️ Deal '\(deal.restaurantName)' filtré: isActive = false")
                        return false
                    }
                    
                    // Ensuite vérifier si le deal est expiré
                    if isDealExpired(deal) {
                        print("⚠️ Deal '\(deal.restaurantName)' filtré: expiré (endDate: \(deal.endDate))")
                        // Ne pas supprimer automatiquement - laisser le backend gérer
                        // Task {
                        //     await deleteExpiredDeal(deal)
                        // }
                        return false
                    }
                    
                    return true
                }
                
                print("✅ \(activeDeals.count) deals actifs affichés (sur \(deals.count) total)")
                dealsState = .success(activeDeals)
                
            case .failure(let error):
                print("❌ Erreur: \(error.localizedDescription)")
                dealsState = .error(error.localizedDescription)
            }
        }
    }
    
    // Vérifier si un deal est expiré
    private func isDealExpired(_ deal: Deal) -> Bool {
        // Essayer plusieurs formats de date pour compatibilité
        var endDate: Date? = nil
        
        // Essayer ISO8601 avec fractional seconds
        let isoFormatter1 = ISO8601DateFormatter()
        isoFormatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter1.date(from: deal.endDate) {
            endDate = date
        }
        
        // Essayer ISO8601 sans fractional seconds
        if endDate == nil {
            let isoFormatter2 = ISO8601DateFormatter()
            isoFormatter2.formatOptions = [.withInternetDateTime]
            if let date = isoFormatter2.date(from: deal.endDate) {
                endDate = date
            }
        }
        
        // Essayer DateFormatter avec différents formats
        if endDate == nil {
            let dateFormatter1 = DateFormatter()
            dateFormatter1.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            dateFormatter1.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter1.date(from: deal.endDate) {
                endDate = date
            }
        }
        
        if endDate == nil {
            let dateFormatter2 = DateFormatter()
            dateFormatter2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            dateFormatter2.timeZone = TimeZone(secondsFromGMT: 0)
            if let date = dateFormatter2.date(from: deal.endDate) {
                endDate = date
            }
        }
        
        guard let parsedEndDate = endDate else {
            print("⚠️ Impossible de parser la date endDate: '\(deal.endDate)' pour le deal '\(deal.restaurantName)' - on garde le deal")
            return false // Si on ne peut pas parser la date, on garde le deal (ne pas filtrer)
        }
        
        let isExpired = parsedEndDate < Date()
        if isExpired {
            print("📅 Deal '\(deal.restaurantName)' expiré: \(parsedEndDate) < \(Date())")
        }
        return isExpired
    }
    
    // Supprimer automatiquement un deal expiré
    private func deleteExpiredDeal(_ deal: Deal) async {
        print("🗑️ Suppression automatique du deal expiré: \(deal.restaurantName)")
        let result = await repository.deleteDeal(deal._id)
        
        switch result {
        case .success:
            print("✅ Deal expiré supprimé automatiquement: \(deal._id)")
        case .failure(let error):
            print("⚠️ Erreur lors de la suppression automatique: \(error.localizedDescription)")
        }
    }
    
    func loadDealById(_ id: String) {
        print("🔍 loadDealById(\(id))")
        dealDetailState = .loading
        
        Task {
            let result = await repository.getDealById(id)
            
            switch result {
            case .success(let deal):
                print("✅ Deal chargé: \(deal.restaurantName)")
                dealDetailState = .success(deal)
            case .failure(let error):
                print("❌ Erreur: \(error.localizedDescription)")
                dealDetailState = .error(error.localizedDescription)
            }
        }
    }
    
    func createDeal(_ dto: CreateDealDto) {
        print("➕ createDeal: \(dto.restaurantName)")
        
        Task {
            let result = await repository.createDeal(dto)
            
            switch result {
            case .success:
                print("✅ Deal créé avec succès")
                operationResult = .success("Deal créé avec succès")
                loadDeals()
            case .failure(let error):
                print("❌ Erreur création: \(error.localizedDescription)")
                operationResult = .failure(error)
            }
        }
    }
    
    func updateDeal(_ id: String, dto: UpdateDealDto) {
        print("✏️ updateDeal: \(id)")
        
        Task {
            let result = await repository.updateDeal(id, dto: dto)
            
            switch result {
            case .success:
                print("✅ Deal mis à jour")
                operationResult = .success("Deal mis à jour")
                loadDeals()
            case .failure(let error):
                print("❌ Erreur MAJ: \(error.localizedDescription)")
                operationResult = .failure(error)
            }
        }
    }
    
    func deleteDeal(_ id: String) {
        print("🗑️ deleteDeal: \(id)")
        
        Task {
            let result = await repository.deleteDeal(id)
            
            switch result {
            case .success:
                print("✅ Deal supprimé")
                operationResult = .success("Deal supprimé")
                loadDeals()
            case .failure(let error):
                print("❌ Erreur suppression: \(error.localizedDescription)")
                operationResult = .failure(error)
            }
        }
    }
    
    func clearOperationResult() {
        print("🧹 Nettoyage operationResult")
        operationResult = nil
    }
    
    // Charger le menu pour la sélection d'items/catégories
    func loadMenu() {
        print("🍽️ Chargement du menu pour les deals")
        
        guard let professionalId = SessionManager.shared.userId,
              let token = SessionManager.shared.accessToken else {
            print("❌ Impossible de charger le menu: Utilisateur non connecté")
            return
        }
        
        menuRepository.getGroupedMenu(professionalId: professionalId, token: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let grouped):
                    print("✅ Menu chargé avec succès: \(grouped.keys.count) catégories")
                    self?.menuGroups = grouped
                case .failure(let error):
                    print("❌ Erreur chargement menu: \(error.localizedDescription)")
                }
            }
        }
    }
}
