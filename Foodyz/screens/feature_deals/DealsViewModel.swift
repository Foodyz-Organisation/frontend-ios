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
    
    private let repository = DealsRepository()
    
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
                print("✅ \(deals.count) deals chargés")
                
                // Filtrer et supprimer automatiquement les deals expirés
                let now = Date()
                let activeDeals = deals.filter { deal in
                    if isDealExpired(deal) {
                        // Supprimer automatiquement le deal expiré
                        Task {
                            await deleteExpiredDeal(deal)
                        }
                        return false
                    }
                    return true
                }
                
                print("✅ \(activeDeals.count) deals actifs (après suppression des expirés)")
                dealsState = .success(activeDeals)
                
            case .failure(let error):
                print("❌ Erreur: \(error.localizedDescription)")
                dealsState = .error(error.localizedDescription)
            }
        }
    }
    
    // Vérifier si un deal est expiré
    private func isDealExpired(_ deal: Deal) -> Bool {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let endDate = isoFormatter.date(from: deal.endDate) else {
            return false // Si on ne peut pas parser la date, on garde le deal
        }
        
        return endDate < Date()
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
}
