import SwiftUI

struct DrawerItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let route: String // Used to track selection or initiate external navigation
    let isLogout: Bool
}

struct DrawerView: View {
    let onCloseDrawer: () -> Void
    let navigateTo: (String) -> Void
    var currentRoute: String // Highlight the currently active route
    @EnvironmentObject private var session: SessionManager
    
    // Points de fidélité
    @State private var loyaltyPoints: Int = 0
    @State private var isLoadingPoints: Bool = false
    @State private var showDebugInfo: Bool = false
    @State private var debugMessage: String = ""
    @State private var debugDetails: [String] = []
    
    let menuItems: [DrawerItem] = [
        DrawerItem(icon: "house.fill", label: "Home", route: "home", isLogout: false),
        DrawerItem(icon: "bubble.left.and.bubble.right.fill", label: "Messages", route: "chat", isLogout: false),
        DrawerItem(icon: "calendar", label: "Événements", route: "events", isLogout: false),
        DrawerItem(icon: "exclamationmark.triangle.fill", label: "Reclamations", route: "reclamations", isLogout: false),
        DrawerItem(icon: "gearshape.fill", label: "Settings", route: "settings", isLogout: false),
        DrawerItem(icon: "heart.fill", label: "Favorites", route: "favorites", isLogout: false),
        DrawerItem(icon: "person.fill", label: "Profile", route: "profile", isLogout: false),
        DrawerItem(icon: "questionmark.circle.fill", label: "Help & Support", route: "help", isLogout: false),
        DrawerItem(icon: "person.badge.plus", label: "Signup as Professional", route: "signup_pro", isLogout: false)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Profile Header
            VStack(alignment: .leading, spacing: 8) {
                Circle()
                    .fill(HomeColors.primary.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(HomeColors.primary, lineWidth: 2))

                Text("John Doe")
                    .font(.headline).fontWeight(.bold)
                    .foregroundColor(HomeColors.darkGray)
                Text("john.doe@example.com")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.top, 40)
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
            
            // MARK: Loyalty Points Card
            VStack(spacing: 8) {
                LoyaltyPointsCard(points: loyaltyPoints) {
                    print("⭐ Clic sur Points de Fidélité - Navigation vers loyalty_points")
                    navigateTo("loyalty_points")
                    onCloseDrawer()
                }
                
                // Debug Tool - Long press to show/hide
                if showDebugInfo {
                    DebugLoyaltyPointsView(
                        points: loyaltyPoints,
                        isLoading: isLoadingPoints,
                        message: debugMessage,
                        details: debugDetails
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .onLongPressGesture(minimumDuration: 1.0) {
                showDebugInfo.toggle()
                if showDebugInfo {
                    updateDebugInfo()
                }
            }
            
            Divider()
            
            // MARK: Menu Items
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(menuItems) { item in
                        DrawerRow(item: item, isSelected: currentRoute == item.route)
                            .onTapGesture {
                                navigateTo(item.route)
                                onCloseDrawer()
                            }
                    }
                    
                    // MARK: Logout Item
                    DrawerRow(
                        item: DrawerItem(icon: "arrow.right.square.fill", label: "Logout", route: "logout", isLogout: true),
                        isSelected: currentRoute == "logout"
                    )
                    .onTapGesture {
                        Task {
                            do {
                                // Call your logout API
                                try await AuthAPI.shared.logout()
                                
                                // Close drawer
                                onCloseDrawer()
                                
                                // Navigate back to login
                                navigateTo("login")
                            } catch {
                                print("Logout failed: \(error.localizedDescription)")
                                // Optionally show alert to user
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
            
            Spacer()
        }
        .frame(width: 280)
        .background(AppColors.white)
        .edgesIgnoringSafeArea(.vertical)
        .onAppear {
            loadLoyaltyPoints()
        }
    }
    
    // MARK: - Load Loyalty Points
    private func loadLoyaltyPoints() {
        guard !isLoadingPoints else {
            print("⏳ Chargement des points déjà en cours...")
            updateDebugInfo(message: "⏳ Chargement déjà en cours...")
            return
        }
        isLoadingPoints = true
        print("🔄 Début du chargement des points de fidélité dans le drawer...")
        updateDebugInfo(message: "🔄 Chargement en cours...")
        
        LoyaltyAPI.shared.getLoyaltyPoints { result in
            DispatchQueue.main.async {
                self.isLoadingPoints = false
                switch result {
                case .success(let data):
                    self.loyaltyPoints = data.loyaltyPoints
                    print("✅ Points de fidélité chargés dans le drawer: \(data.loyaltyPoints)")
                    print("   Réclamations valides: \(data.validReclamations)")
                    print("   Réclamations invalides: \(data.invalidReclamations)")
                    print("   Score de fiabilité: \(data.reliabilityScore)%")
                    updateDebugInfo(
                        message: "✅ Points chargés: \(data.loyaltyPoints)",
                        details: [
                            "Réclamations valides: \(data.validReclamations)",
                            "Réclamations invalides: \(data.invalidReclamations)",
                            "Score de fiabilité: \(data.reliabilityScore)%",
                            "Historique: \(data.history.count) transaction(s)"
                        ]
                    )
                case .failure(let error):
                    print("❌ Erreur lors du chargement des points: \(error.localizedDescription)")
                    updateDebugInfo(
                        message: "❌ Erreur API: \(error.localizedDescription)",
                        details: ["Tentative de chargement depuis les réclamations..."]
                    )
                    // Essayer de charger depuis les réclamations directement
                    self.loadPointsFromReclamations()
                }
            }
        }
    }
    
    // MARK: - Fallback: Charger les points depuis les réclamations
    private func loadPointsFromReclamations() {
        print("🔄 Tentative de chargement des points depuis les réclamations...")
        updateDebugInfo(message: "🔄 Calcul depuis les réclamations...")
        
        ReclamationAPI.shared.getMyReclamations { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reclamations):
                    var totalPoints = 0
                    var validCount = 0
                    var invalidCount = 0
                    var pendingCount = 0
                    var details: [String] = []
                    
                    details.append("Total réclamations: \(reclamations.count)")
                    
                    for reclamation in reclamations {
                        let status = reclamation.statut.lowercased()
                        if status == "resolue" || status == "résolue" {
                            totalPoints += 10
                            validCount += 1
                        } else if status == "rejetee" || status == "rejetée" {
                            totalPoints -= 10
                            invalidCount += 1
                        } else {
                            pendingCount += 1
                        }
                    }
                    
                    self.loyaltyPoints = totalPoints
                    print("✅ Points calculés depuis les réclamations: \(totalPoints)")
                    
                    details.append("✅ Valides: \(validCount) (+\(validCount * 10) pts)")
                    details.append("❌ Invalides: \(invalidCount) (-\(invalidCount * 10) pts)")
                    details.append("⏳ En attente: \(pendingCount)")
                    details.append("📊 Total: \(totalPoints) points")
                    
                    updateDebugInfo(
                        message: "✅ Points calculés: \(totalPoints)",
                        details: details
                    )
                case .failure(let error):
                    print("❌ Erreur lors du chargement des réclamations: \(error.localizedDescription)")
                    self.loyaltyPoints = 0
                    updateDebugInfo(
                        message: "❌ Erreur réclamations: \(error.localizedDescription)",
                        details: ["Impossible de charger les réclamations"]
                    )
                }
            }
        }
    }
    
    // MARK: - Update Debug Info
    private func updateDebugInfo(message: String = "", details: [String] = []) {
        self.debugMessage = message.isEmpty ? "Aucune information" : message
        self.debugDetails = details
    }
}

// MARK: Drawer Row Sub-Component
struct DrawerRow: View {
    let item: DrawerItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: item.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .foregroundColor(item.isLogout ? .red : (isSelected ? AppColors.primary : AppColors.darkGray))
            
            Text(item.label)
                .font(.subheadline).fontWeight(.medium)
                .foregroundColor(item.isLogout ? .red : AppColors.darkGray)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(isSelected && !item.isLogout ? AppColors.primary.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
    }
}

// MARK: - Loyalty Points Card
struct LoyaltyPointsCard: View {
    let points: Int
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Star Icon
            Image(systemName: "star.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0)) // Yellow
                .frame(width: 40, height: 40)
            
            // Points Text
            VStack(alignment: .leading, spacing: 2) {
                Text("\(points) Points")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(points >= 0 ? Color(red: 0.5, green: 0.2, blue: 0.8) : Color.red) // Purple si positif, rouge si négatif
                
                Text("Points de Fidélité")
                    .font(.system(size: 12))
                    .foregroundColor(HomeColors.darkGray)
            }
            .onAppear {
                print("📊 LoyaltyPointsCard affichée avec \(points) points")
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color(red: 0.95, green: 0.9, blue: 1.0)) // Light purple background
        .cornerRadius(12)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Debug Loyalty Points View
struct DebugLoyaltyPointsView: View {
    let points: Int
    let isLoading: Bool
    let message: String
    let details: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Debug Info")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
                Text(isLoading ? "⏳" : "✅")
                    .font(.caption)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Points actuels: \(points)")
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text("État: \(isLoading ? "Chargement..." : "Chargé")")
                    .font(.caption)
                
                if !message.isEmpty {
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                if !details.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(details, id: \.self) { detail in
                            Text("• \(detail)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
