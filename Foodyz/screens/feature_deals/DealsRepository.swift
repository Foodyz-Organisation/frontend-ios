//
//  DealsRepository.swift
//  Foodyz
//
//  Created by Apple on 3/12/2025.
//

import Foundation

class DealsRepository {
    private let apiService = DealsAPIService.shared
    
    func getAllDeals() async -> Result<[Deal], Error> {
        do {
            let deals = try await apiService.getAllDeals()
            print("✅ \(deals.count) deals récupérés")
            return .success(deals)
        } catch {
            print("❌ Erreur getAllDeals: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func getDealById(_ id: String) async -> Result<Deal, Error> {
        do {
            let deal = try await apiService.getDealById(id)
            print("✅ Deal récupéré: \(deal.restaurantName)")
            return .success(deal)
        } catch {
            print("❌ Erreur getDealById: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func createDeal(_ dto: CreateDealDto) async -> Result<Deal, Error> {
        do {
            let deal = try await apiService.createDeal(dto)
            print("✅ Deal créé: \(deal.restaurantName)")
            return .success(deal)
        } catch {
            print("❌ Erreur createDeal: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func updateDeal(_ id: String, dto: UpdateDealDto) async -> Result<Deal, Error> {
        do {
            let deal = try await apiService.updateDeal(id, dto: dto)
            print("✅ Deal mis à jour: \(deal.restaurantName)")
            return .success(deal)
        } catch {
            print("❌ Erreur updateDeal: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func deleteDeal(_ id: String) async -> Result<Deal, Error> {
        do {
            let deal = try await apiService.deleteDeal(id)
            print("✅ Deal supprimé: \(deal._id)")
            return .success(deal)
        } catch {
            print("❌ Erreur deleteDeal: \(error.localizedDescription)")
            return .failure(error)
        }
    }
}
