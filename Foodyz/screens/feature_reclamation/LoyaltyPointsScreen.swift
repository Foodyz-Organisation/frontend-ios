import SwiftUI

// MARK: - Data Models
struct LoyaltyData {
    let loyaltyPoints: Int
    let validReclamations: Int
    let invalidReclamations: Int
    let reliabilityScore: Int
    let availableRewards: [Reward]
    let history: [PointsTransaction]
}

struct Reward: Identifiable {
    let id = UUID()
    let name: String
    let pointsCost: Int
    let available: Bool
}

struct PointsTransaction: Identifiable {
    let id = UUID()
    let points: Int
    let reason: String
    let date: String
    let reclamationId: String?
    
    init(points: Int, reason: String, date: String, reclamationId: String?) {
        self.points = points
        self.reason = reason
        self.date = date
        self.reclamationId = reclamationId
    }
}

// MARK: - Loyalty Points Screen
struct LoyaltyPointsScreen: View {
    var loyaltyData: LoyaltyData?
    var onBack: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var currentLoyaltyData: LoyaltyData?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showDebugInfo: Bool = false
    @State private var debugLogs: [String] = []

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Réessayer") {
                            loadLoyaltyData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if let data = currentLoyaltyData ?? loyaltyData {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 💰 Total Points Card
                            totalPointsCard(loyaltyPoints: data.loyaltyPoints)

                            // 📊 Stats Row
                            HStack(spacing: 12) {
                                statCard(title: "Réclamations\nValides", value: "\(data.validReclamations)", gradientColors: [Color.green, Color.green.opacity(0.7)], iconName: "checkmark.circle.fill")
                                statCard(title: "Score\nFiabilité", value: "\(data.reliabilityScore)%", gradientColors: [Color.blue, Color.blue.opacity(0.7)], iconName: "shield.fill")
                            }

                            // 🎁 Rewards Section
                            if !data.availableRewards.isEmpty {
                                Text("🎁 Récompenses Disponibles")
                                    .font(.title2)
                                    .bold()
                                    .padding(.top, 8)

                                ForEach(data.availableRewards) { reward in
                                    rewardCard(reward: reward)
                                }
                            }

                            // 📜 Transaction History
                            if !data.history.isEmpty {
                                Text("📜 Historique des Points")
                                    .font(.title2)
                                    .bold()
                                    .padding(.top, 16)

                                ForEach(data.history) { transaction in
                                    transactionCard(transaction: transaction)
                                }
                            } else {
                                emptyStateCard()
                            }
                        }
                        .padding(16)
                    }
                } else {
                    // État vide - Afficher quand pas de données
                    ScrollView {
                        VStack(spacing: 24) {
                            // Carte de points par défaut
                            totalPointsCard(loyaltyPoints: 0)
                            
                            // Message informatif
                            VStack(spacing: 12) {
                                Image(systemName: "star.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange.opacity(0.6))
                                
                                Text("Aucun point de fidélité")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("Commencez à utiliser l'application pour gagner des points de fidélité")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(32)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            // Stats vides
                            HStack(spacing: 12) {
                                statCard(title: "Réclamations\nValides", value: "0", gradientColors: [Color.green, Color.green.opacity(0.7)], iconName: "checkmark.circle.fill")
                                statCard(title: "Score\nFiabilité", value: "0%", gradientColors: [Color.blue, Color.blue.opacity(0.7)], iconName: "shield.fill")
                            }
                            
                            // Historique vide
                            emptyStateCard()
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Points de Fidélité")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    onBack()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showDebugInfo {
                DebugLoyaltyScreenView(
                    loyaltyData: currentLoyaltyData ?? loyaltyData,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    logs: debugLogs
                )
                .padding()
            }
        }
        .onAppear {
            if loyaltyData == nil {
                loadLoyaltyData()
            } else {
                currentLoyaltyData = loyaltyData
            }
        }
    }
    
    // MARK: - Load Loyalty Data
    private func loadLoyaltyData() {
        isLoading = true
        errorMessage = nil
        addDebugLog("🔄 Début du chargement des points de fidélité...")
        
        LoyaltyAPI.shared.getLoyaltyPoints { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let data):
                    addDebugLog("✅ Données reçues de l'API")
                    addDebugLog("   Points: \(data.loyaltyPoints)")
                    addDebugLog("   Valides: \(data.validReclamations)")
                    addDebugLog("   Invalides: \(data.invalidReclamations)")
                    addDebugLog("   Score: \(data.reliabilityScore)%")
                    
                    // Convertir DTO en LoyaltyData
                    let rewards = (data.availableRewards ?? []).map { rewardDTO in
                        Reward(
                            name: rewardDTO.name,
                            pointsCost: rewardDTO.pointsCost,
                            available: rewardDTO.available
                        )
                    }
                    
                    let transactions = (data.history ?? []).map { transactionDTO in
                        PointsTransaction(
                            points: transactionDTO.points,
                            reason: transactionDTO.reason,
                            date: transactionDTO.date,
                            reclamationId: transactionDTO.reclamationId
                        )
                    }
                    
                    addDebugLog("   Récompenses: \(rewards.count)")
                    addDebugLog("   Historique: \(transactions.count) transaction(s)")
                    
                    self.currentLoyaltyData = LoyaltyData(
                        loyaltyPoints: data.loyaltyPoints,
                        validReclamations: data.validReclamations,
                        invalidReclamations: data.invalidReclamations,
                        reliabilityScore: data.reliabilityScore,
                        availableRewards: rewards,
                        history: transactions
                    )
                    addDebugLog("✅ Données converties et affichées")
                    print("✅ Données de fidélité chargées: \(data.loyaltyPoints) points")
                case .failure(let error):
                    let errorMsg = "Impossible de charger les points de fidélité. \(error.localizedDescription)"
                    addDebugLog("❌ Erreur: \(error.localizedDescription)")
                    print("❌ Erreur lors du chargement des points: \(error.localizedDescription)")
                    self.errorMessage = errorMsg
                }
            }
        }
    }
    
    // MARK: - Add Debug Log
    private func addDebugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        debugLogs.append("[\(timestamp)] \(message)")
        // Garder seulement les 20 derniers logs
        if debugLogs.count > 20 {
            debugLogs.removeFirst()
        }
    }
}

// MARK: - Components

func totalPointsCard(loyaltyPoints: Int) -> some View {
    ZStack {
        LinearGradient(colors: [Color.orange, Color.yellow, Color.yellow.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .cornerRadius(24)
            .shadow(radius: 12)

        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                Image(systemName: "star.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.white)
            }

            Text("\(loyaltyPoints)")
                .font(.system(size: 56, weight: .heavy))
                .foregroundColor(.white)
                .onAppear {
                    print("📊 TotalPointsCard affichée avec \(loyaltyPoints) points")
                }

            Text("Points Fidélité")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(32)
    }
}

// Stat Card
func statCard(title: String, value: String, gradientColors: [Color], iconName: String) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 20)
            .fill(LinearGradient(colors: gradientColors.map { $0.opacity(0.1) }, startPoint: .topLeading, endPoint: .bottomTrailing))
            .shadow(radius: 8)
            .frame(height: 140)

        VStack {
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 36))
                    .foregroundColor(gradientColors[0])
                Spacer()
            }
            Spacer()
            VStack(alignment: .leading) {
                Text(value)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(gradientColors[0])
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.gray)
                    .lineSpacing(2)
            }
        }
        .padding(16)
    }
}

// Reward Card
func rewardCard(reward: Reward) -> some View {
    HStack {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 56, height: 56)
                Image(systemName: "gift.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.orange)
            }
            VStack(alignment: .leading) {
                Text(reward.name).bold()
                Text("\(reward.pointsCost) points").font(.caption).foregroundColor(.gray)
            }
        }
        Spacer()
        Button(action: {}) {
            Text(reward.available ? "Échanger" : "Indisponible")
                .padding()
                .background(reward.available ? Color.orange : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!reward.available)
    }
    .padding()
    .background(Color.white)
    .cornerRadius(16)
    .shadow(radius: 4)
}

// Transaction Card
func transactionCard(transaction: PointsTransaction) -> some View {
    let isPositive = transaction.points > 0

    return HStack {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((isPositive ? Color.green : Color.red).opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isPositive ? Color.green : Color.red)
            }
            VStack(alignment: .leading) {
                Text(transaction.reason).fontWeight(.semibold)
                Text(transaction.date).font(.caption).foregroundColor(.gray)
            }
        }
        Spacer()
        Text("\(isPositive ? "+" : "")\(transaction.points)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(isPositive ? .green : .red)
    }
    .padding()
    .background(isPositive ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
    .cornerRadius(12)
    .shadow(radius: 2)
}

// Empty State Card
func emptyStateCard() -> some View {
    VStack(spacing: 16) {
        Image(systemName: "clock.arrow.circlepath")
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .foregroundColor(Color.gray.opacity(0.3))

        Text("Aucun historique").font(.headline).foregroundColor(.gray)
        Text("Vos transactions apparaîtront ici").font(.subheadline).foregroundColor(Color.gray.opacity(0.6))
    }
    .padding(48)
    .background(Color.white)
    .cornerRadius(16)
    .shadow(radius: 4)
}

// MARK: - Debug Loyalty Screen View
struct DebugLoyaltyScreenView: View {
    let loyaltyData: LoyaltyData?
    let isLoading: Bool
    let errorMessage: String?
    let logs: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Debug Information")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Spacer()
            }
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // État actuel
                    VStack(alignment: .leading, spacing: 4) {
                        Text("État:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(isLoading ? "⏳ Chargement..." : (errorMessage != nil ? "❌ Erreur" : "✅ Chargé"))
                            .font(.caption)
                    }
                    
                    // Données
                    if let data = loyaltyData {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Données:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Points: \(data.loyaltyPoints)")
                            Text("Valides: \(data.validReclamations)")
                            Text("Invalides: \(data.invalidReclamations)")
                            Text("Score: \(data.reliabilityScore)%")
                            Text("Historique: \(data.history.count) transaction(s)")
                        }
                        .font(.caption)
                    } else {
                        Text("Aucune donnée disponible")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Erreur
                    if let error = errorMessage {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Erreur:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Logs
                    if !logs.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Logs (\(logs.count)):")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            ForEach(logs.suffix(10), id: \.self) { log in
                                Text(log)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
    }
}
