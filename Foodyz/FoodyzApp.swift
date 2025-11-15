//
//  FoodyzApp.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 4/11/2025.
//

import SwiftUI
import Combine

@main
struct FoodyzApp: App {
    var body: some Scene {
        WindowGroup {
            // Utiliser AppNavigation au lieu de MainTabView
            AppNavigation()
        }
    }
}

// MARK: - Main Tab View
// Ce view sera maintenant utilisé dans HomeUserScreen ou HomeProfessionalView
struct MainTabView: View {
    @StateObject private var eventManager = EventManager()
    
    var body: some View {
        TabView {
            // Tab Événements
            NavigationView {
                EventListView()
            }
            .tabItem {
                Image(systemName: "calendar")
                Text("Événements")
            }
            
            // Tab Liste Réclamations
            NavigationView {
                ReclamationListView()
            }
            .tabItem {
                Image(systemName: "list.bullet")
                Text("Réclamations")
            }
            .tag("reclamation")
            
            // Tab Nouvelle Réclamation
            ReclamationView(
                restaurantNames: ["Restaurant A", "Restaurant B", "Restaurant C"],
                complaintTypes: ["Late delivery", "Missing item", "Quality issue", "Other"],
                commandeConcernees: ["Commande #1", "Commande #2", "Commande #3"]
            ) { restaurant, type, description, photos in
                // Gérer la soumission
                print("Réclamation soumise : \(type) pour \(restaurant)")
            }
            .tabItem {
                Image(systemName: "exclamationmark.bubble")
                Text("Reclamation")
            }
            
            // Tab Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .environmentObject(eventManager)
    }
}

// MARK: - Event Manager
class EventManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadEvents()
    }
    
    func loadEvents(completion: (() -> Void)? = nil) {
        // Prevent multiple simultaneous loads
        guard !isLoading else {
            completion?()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        EventAPI.shared.getEvents { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let eventDTOs):
                    // Convert DTOs to Events
                    self?.events = eventDTOs.compactMap { $0.toEvent() }
                    print("✅ \(self?.events.count ?? 0) événement(s) chargé(s)")
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    print("❌ Erreur lors du chargement des événements: \(error.localizedDescription)")
                    if self?.events.isEmpty ?? true {
                        print("⚠️ Affichage des données d'exemple en cas d'erreur réseau")
                    }
                }
                completion?()
            }
        }
    }
    
    func addEvent(_ event: Event) {
        // Convert Event to DTO
        let eventDTO = EventDTO(
            nom: event.nom,
            description: event.description,
            dateDebut: event.dateDebut,
            dateFin: event.dateFin,
            image: event.image,
            lieu: event.lieu,
            categorie: event.categorie,
            statut: event.statut.rawValue
        )
        
        print("📤 Envoi de l'événement au backend...")
        print("   Nom: \(event.nom)")
        print("   Description: \(event.description)")
        print("   Date début: \(event.dateDebut)")
        print("   Date fin: \(event.dateFin)")
        print("   Lieu: \(event.lieu)")
        print("   Catégorie: \(event.categorie)")
        print("   Statut: \(event.statut.rawValue)")
        
        EventAPI.shared.createEvent(eventDTO) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Événement créé avec succès sur le backend")
                    self?.errorMessage = nil
                    self?.loadEvents()
                case .failure(let error):
                    let errorMsg = error.localizedDescription
                    self?.errorMessage = "Erreur lors de la création: \(errorMsg)"
                    print("❌ Erreur lors de la création: \(errorMsg)")
                }
            }
        }
    }
    
    func deleteEvent(_ event: Event) {
        isLoading = true
        errorMessage = nil
        
        print("🗑️ Suppression de l'événement: \(event.nom) (ID: \(event.id))")
        
        EventAPI.shared.deleteEvent(event.id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    print("✅ Événement supprimé avec succès")
                    self?.errorMessage = nil
                    self?.loadEvents()
                case .failure(let error):
                    let errorMsg = error.localizedDescription
                    self?.errorMessage = "Erreur lors de la suppression: \(errorMsg)"
                    print("❌ Erreur lors de la suppression: \(errorMsg)")
                }
            }
        }
    }
    
    func updateEvent(_ event: Event) {
        isLoading = true
        errorMessage = nil
        
        // Convert Event to DTO
        let eventDTO = EventDTO(
            id: event.id,
            nom: event.nom,
            description: event.description,
            dateDebut: event.dateDebut,
            dateFin: event.dateFin,
            image: event.image,
            lieu: event.lieu,
            categorie: event.categorie,
            statut: event.statut.rawValue
        )
        
        print("📝 Mise à jour de l'événement: \(event.nom) (ID: \(event.id))")
        
        EventAPI.shared.updateEvent(event.id, event: eventDTO) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success:
                    print("✅ Événement mis à jour avec succès")
                    self?.errorMessage = nil
                    self?.loadEvents()
                case .failure(let error):
                    let errorMsg = error.localizedDescription
                    self?.errorMessage = "Erreur lors de la mise à jour: \(errorMsg)"
                    print("❌ Erreur lors de la mise à jour: \(errorMsg)")
                }
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
                    .padding()
                
                Text("Profil Utilisateur")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .navigationTitle("Mon Profil")
        }
    }
}
