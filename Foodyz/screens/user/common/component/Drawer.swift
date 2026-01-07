import SwiftUI

struct DrawerItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let route: String
    let isLogout: Bool
    let isSpecial: Bool // For the orange signup button
    
    init(icon: String, label: String, route: String, isLogout: Bool = false, isSpecial: Bool = false) {
        self.icon = icon
        self.label = label
        self.route = route
        self.isLogout = isLogout
        self.isSpecial = isSpecial
    }
}

struct DrawerView: View {
    let onCloseDrawer: () -> Void
    let navigateTo: (String) -> Void
    var currentRoute: String
    @EnvironmentObject private var session: SessionManager
    
    // Points de fidélité
    @State private var loyaltyPoints: Int = 0
    @State private var isLoadingPoints: Bool = false
    @State private var showDebugInfo: Bool = false
    @State private var debugMessage: String = ""
    @State private var debugDetails: [String] = []
    
    let menuItems: [DrawerItem] = [
        DrawerItem(icon: "list.bullet", label: "Mes Réclamations", route: "reclamations"),
        DrawerItem(icon: "calendar", label: "Événements", route: "events"),
        DrawerItem(icon: "cart.fill", label: "Liste des Deals", route: "deals"),
        DrawerItem(icon: "doc.text.fill", label: "Orders History", route: "order_history"),
        DrawerItem(icon: "bookmark.fill", label: "Saved Posts", route: "saved_posts")
    ]
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color(red: 0.96, green: 0.96, blue: 0.96).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header with Logo and Close Button
                HStack {
                    Text("foodyz")
                        .font(.custom("Pacifico", size: 32))
                        .foregroundColor(Color.orange)
                        .italic()
                    
                    Spacer()
                    
                    Button(action: {
                        onCloseDrawer()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 20)
                
                // MARK: - User Profile Section (Clickable)
                Button(action: {
                    navigateTo("profile")
                    onCloseDrawer()
                }) {
                    HStack(spacing: 12) {
                        // Profile Image with AsyncImage fallback
                        if let avatarURL = session.avatarURL, let url = URL(string: avatarURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                case .failure(_), .empty:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 56, height: 56)
                                }
                            }
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.displayName ?? "Guest")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text(session.email ?? "No email")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
                .buttonStyle(PlainButtonStyle())
                
                // MARK: - Dark Loyalty Points Card
                VStack(spacing: 8) {
                    DarkLoyaltyPointsCard(points: loyaltyPoints) {
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
                .padding(.top, 16)
                .padding(.bottom, 16)
                .onLongPressGesture(minimumDuration: 1.0) {
                    showDebugInfo.toggle()
                    if showDebugInfo {
                        updateDebugInfo()
                    }
                }
                
                // MARK: - Menu Items (White Cards)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(menuItems) { item in
                            WhiteMenuCard(item: item, isSelected: currentRoute == item.route)
                                .onTapGesture {
                                    navigateTo(item.route)
                                    onCloseDrawer()
                                }
                        }
                        
                        // MARK: - Orange Signup Button
                        OrangeSignupButton {
                            navigateTo("signup_pro")
                            onCloseDrawer()
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Logout Button
                        Button(action: {
                            Task {
                                do {
                                    try await AuthAPI.shared.logout()
                                    onCloseDrawer()
                                    navigateTo("login")
                                } catch {
                                    print("Logout failed: \(error.localizedDescription)")
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.square.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.red)
                                
                                Text("Logout")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                Spacer()
            }
        }
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

// MARK: - Dark Loyalty Points Card (matching Android design)
struct DarkLoyaltyPointsCard: View {
    let points: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Star Icon with yellow background circle
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(points) Points")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Points de Fidélité")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.2, green: 0.25, blue: 0.35), Color(red: 0.15, green: 0.2, blue: 0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - White Menu Card (matching Android design)
struct WhiteMenuCard: View {
    let item: DrawerItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with yellow background circle
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.orange)
            }
            
            Text(item.label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Orange Signup Button (matching Android design)
struct OrangeSignupButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                Text("Signup as Professional")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange, Color(red: 1.0, green: 0.6, blue: 0.0)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
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
