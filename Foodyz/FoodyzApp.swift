import SwiftUI
import Combine
import UIKit

@main
@MainActor
struct FoodyzApp: App {
    init() {
        // Configure navigation bar appearance globally
        let navBgColor = UIColor(red: 1.0, green: 0.984, blue: 0.918, alpha: 1.0) // #FFFBEA for app screens
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = navBgColor
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .environmentObject(SessionManager.shared)
                .background(WindowBackgroundView())
                .ignoresSafeArea(.all, edges: .all)
        }
    }
}

// MARK: - Window Background View
struct WindowBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        
        // Set window background - only in actual app, not preview
        DispatchQueue.main.async {
            setWindowBackground()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.backgroundColor = .white
        
        // Set window background - only in actual app, not preview
        DispatchQueue.main.async {
            setWindowBackground()
        }
    }
    
    private func setWindowBackground() {
        // Skip in preview environment
        guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == nil else {
            return
        }
        
        let bgColor = UIColor.white
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.backgroundColor = bgColor
                if let rootVC = window.rootViewController {
                    rootVC.view.backgroundColor = bgColor
                    rootVC.view.isOpaque = true
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @StateObject private var eventManager = EventManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab Home
            HomeContentView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // Tab Événements
            EventListView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Événements")
                }
                .tag(1)
            
            // Tab Liste Réclamations
            ReclamationListNavigationView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Réclamations")
                }
                .tag(2)
            
            // Tab Nouvelle Réclamation
            ReclamationView(
                restaurantNames: ["Restaurant A", "Restaurant B", "Restaurant C"],
                complaintTypes: ["Late delivery", "Missing item", "Quality issue", "Other"],
                commandeConcernees: ["Commande #1", "Commande #2", "Commande #3"]
            ) { restaurant, type, description, photos in
                print("Réclamation soumise : \(type) pour \(restaurant)")
            }
            .tabItem {
                Image(systemName: "exclamationmark.bubble")
                Text("Reclamation")
            }
            .tag(3)
            
            // Tab Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .environmentObject(eventManager)
    }
}

// MARK: - Home Content View
struct HomeContentView: View {
    @Binding var selectedTab: Int
    @State private var showCreateEvent = false
    @EnvironmentObject private var eventManager: EventManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome Back!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(HomeColors.darkGray)
                    
                    Text("Discover amazing food events and restaurants")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Categories Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Categories")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(HomeColors.darkGray)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Card Events - Cliquable
                        Button(action: {
                            selectedTab = 1 // Naviguer vers le tab événements
                        }) {
                            CategoryCard(
                                icon: "calendar.badge.clock",
                                title: "Events",
                                subtitle: "Browse food events",
                                backgroundColor: .orange.opacity(0.1),
                                iconColor: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        CategoryCard(
                            icon: "fork.knife",
                            title: "Restaurants",
                            subtitle: "Find places to eat",
                            backgroundColor: .red.opacity(0.1),
                            iconColor: .red
                        )
                        
                        CategoryCard(
                            icon: "star.fill",
                            title: "Reviews",
                            subtitle: "Share your experience",
                            backgroundColor: .yellow.opacity(0.1),
                            iconColor: .yellow
                        )
                        
                        // Card Complaints - Cliquable
                        Button(action: {
                            selectedTab = 2 // Naviguer vers le tab réclamations
                        }) {
                            CategoryCard(
                                icon: "exclamationmark.bubble.fill",
                                title: "Complaints",
                                subtitle: "Report issues",
                                backgroundColor: .blue.opacity(0.1),
                                iconColor: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                Button(action: {
                    showCreateEvent = true
                }) {
                    QuickActionButton(
                        icon: "plus.circle.fill",
                        title: "Nouvel Événement",
                        color: .orange
                    )
                }
                .sheet(isPresented: $showCreateEvent) {
                    NavigationView {
                        CreateEventView { newEvent in
                            eventManager.addEvent(newEvent)
                        }
                    }
                }

                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Actions")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(HomeColors.darkGray)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            selectedTab = 1 // Naviguer vers événements
                        }) {
                            QuickActionButton(
                                icon: "calendar.badge.plus",
                                title: "View All Events",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            selectedTab = 3 // Naviguer vers nouvelle réclamation
                        }) {
                            QuickActionButton(
                                icon: "plus.circle.fill",
                                title: "New Complaint",
                                color: .red
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            selectedTab = 2 // Naviguer vers liste réclamations
                        }) {
                            QuickActionButton(
                                icon: "list.bullet.rectangle",
                                title: "My Complaints",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
        }
        .background(HomeColors.background.ignoresSafeArea())
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(HomeColors.darkGray)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(HomeColors.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Reclamation List Navigation View
struct ReclamationListNavigationView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = ReclamationListViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.navigationBar.tintColor = UIColor(ReclamationBrandColors.textPrimary)
        
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
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
    
    func addEvent(_ event: Event, completion: @escaping (Result<Event, Error>) -> Void = { _ in }) {
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
        
        EventAPI.shared.createEvent(eventDTO) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let createdDTO):
                    print("✅ Événement créé avec succès sur le backend")
                    self?.errorMessage = nil
                    
                    // Convertir le DTO en Event
                    if let createdEvent = createdDTO.toEvent() {
                        // Ajouter l'événement à la liste localement
                        self?.events.insert(createdEvent, at: 0)
                        print("✅ Événement ajouté à la liste locale")
                        
                        // Recharger depuis le backend pour avoir la version complète
                        self?.loadEvents()
                        
                        // Appeler le completion avec succès
                        completion(.success(createdEvent))
                    } else {
                        // Si la conversion échoue, recharger depuis le backend
                        self?.loadEvents()
                        completion(.success(event))
                    }
                case .failure(let error):
                    let errorMsg = error.localizedDescription
                    self?.errorMessage = "Erreur lors de la création: \(errorMsg)"
                    print("❌ Erreur lors de la création: \(errorMsg)")
                    completion(.failure(error))
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
