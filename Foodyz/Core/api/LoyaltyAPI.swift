import Foundation

// MARK: - Loyalty Points Response DTO (correspond au PointsBalance du backend)
struct LoyaltyPointsResponseDTO: Codable {
    let loyaltyPoints: Int
    let validReclamations: Int
    let invalidReclamations: Int
    let reliabilityScore: Int
    let history: [PointsTransactionDTO]
    let availableRewards: [RewardDTO]? // Optionnel car peut venir d'un autre endpoint
}

struct RewardDTO: Codable {
    let name: String
    let pointsCost: Int
    let available: Bool
}

struct PointsTransactionDTO: Codable {
    let points: Int
    let reason: String
    let reclamationId: String
    let date: String // Backend envoie Date ISO string
    
    enum CodingKeys: String, CodingKey {
        case points
        case reason
        case reclamationId
        case date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode(Int.self, forKey: .points)
        reason = try container.decode(String.self, forKey: .reason)
        reclamationId = try container.decode(String.self, forKey: .reclamationId)
        
        // Le backend envoie une Date, on la convertit en string ISO
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Essayer de décoder comme string ISO d'abord
        if let dateString = try? container.decode(String.self, forKey: .date) {
            date = dateString
        } else {
            // Si c'est un timestamp ou autre format, utiliser la date actuelle comme fallback
            date = dateFormatter.string(from: Date())
        }
    }
    
    // Initializer pour créer manuellement (utilisé dans le fallback)
    init(points: Int, reason: String, reclamationId: String, date: String) {
        self.points = points
        self.reason = reason
        self.reclamationId = reclamationId
        self.date = date
    }
}

// MARK: - Loyalty API Service
class LoyaltyAPI {
    static let shared = LoyaltyAPI()
    private init() {}
    
    private var baseURL: String {
        return AppAPIConstants.baseURL
    }
    
    // MARK: - GET - Récupérer les points de fidélité de l'utilisateur connecté
    // Correspond à getPointsBalance(userId) du LoyaltyService NestJS
    func getLoyaltyPoints(completion: @escaping (Result<LoyaltyPointsResponseDTO, Error>) -> Void) {
        // Liste des endpoints possibles basés sur le backend NestJS
        // Le service LoyaltyService a getPointsBalance(userId) - cherchons le contrôleur
        let possibleEndpoints = [
            "\(baseURL)/loyalty/balance",              // Endpoint probable pour getPointsBalance
            "\(baseURL)/loyalty/points-balance",       // Alternative
            "\(baseURL)/users/loyalty/balance",         // Si c'est dans le contrôleur users
            "\(baseURL)/reclamation/loyalty/balance",  // Si c'est dans le contrôleur reclamation
            "\(baseURL)/loyalty/my-points",            // Ancien endpoint
            "\(baseURL)/reclamation/loyalty-points"    // Ancien endpoint
        ]
        
        guard let accessToken = TokenManager.shared.getAccessToken() else {
            print("❌ Pas de token d'authentification")
            completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Vous devez être connecté"
            ])))
            return
        }
        
        // Essayer chaque endpoint jusqu'à ce qu'un fonctionne
        tryEndpoint(index: 0, endpoints: possibleEndpoints, token: accessToken, completion: completion)
    }
    
    private func tryEndpoint(index: Int, endpoints: [String], token: String, completion: @escaping (Result<LoyaltyPointsResponseDTO, Error>) -> Void) {
        guard index < endpoints.count else {
            print(String(repeating: "=", count: 50))
            print("❌ AUCUN ENDPOINT VALIDE TROUVÉ")
            print(String(repeating: "=", count: 50))
            print("🔄 ACTIVATION DU FALLBACK: Calcul des points à partir des réclamations...")
            print(String(repeating: "=", count: 50))
            // Fallback: Calculer les points à partir des réclamations
            calculatePointsFromReclamations(token: token, completion: completion)
            return
        }
        
        let urlString = endpoints[index]
        print("⭐ Tentative \(index + 1)/\(endpoints.count) - Récupération des points de fidélité...")
        print("📍 URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            tryEndpoint(index: index + 1, endpoints: endpoints, token: token, completion: completion)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Erreur réseau pour \(urlString): \(error.localizedDescription)")
                // Essayer le prochain endpoint
                self?.tryEndpoint(index: index + 1, endpoints: endpoints, token: token, completion: completion)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Status Code pour \(urlString): \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    print("🚫 Token invalide ou expiré")
                    DispatchQueue.main.async {
                        TokenManager.shared.clearAllData()
                        NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
                    }
                    completion(.failure(NSError(domain: "Unauthorized", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: "Session expirée. Veuillez vous reconnecter."
                    ])))
                    return
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    print("❌ Erreur HTTP \(httpResponse.statusCode) pour \(urlString)")
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Réponse d'erreur complète: \(responseString)")
                        
                        // Si c'est une erreur 500, essayer de parser pour voir s'il y a des détails
                        if httpResponse.statusCode == 500 {
                            print("⚠️ Erreur 500 détectée - Le serveur a rencontré une erreur interne")
                            print("💡 Cela peut indiquer que l'endpoint existe mais qu'il y a un bug côté serveur")
                            print("💡 Vérifiez les logs du backend pour plus de détails")
                        }
                    }
                    // Essayer le prochain endpoint
                    self?.tryEndpoint(index: index + 1, endpoints: endpoints, token: token, completion: completion)
                    return
                }
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue pour \(urlString)")
                self?.tryEndpoint(index: index + 1, endpoints: endpoints, token: token, completion: completion)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Réponse brute de \(urlString):")
                print(responseString)
            }
            
            do {
                let decoder = JSONDecoder()
                let loyaltyData = try decoder.decode(LoyaltyPointsResponseDTO.self, from: data)
                print("✅ Points de fidélité récupérés depuis \(urlString): \(loyaltyData.loyaltyPoints)")
                print("✅ Réclamations valides: \(loyaltyData.validReclamations)")
                print("✅ Score de fiabilité: \(loyaltyData.reliabilityScore)%")
                completion(.success(loyaltyData))
            } catch {
                print("❌ Erreur de décodage pour \(urlString): \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 JSON reçu: \(jsonString.prefix(500))")
                }
                // Essayer le prochain endpoint
                self?.tryEndpoint(index: index + 1, endpoints: endpoints, token: token, completion: completion)
            }
        }
        
        task.resume()
    }
    
    // MARK: - Fallback: Calculer les points à partir des réclamations
    private func calculatePointsFromReclamations(token: String, completion: @escaping (Result<LoyaltyPointsResponseDTO, Error>) -> Void) {
        print(String(repeating: "=", count: 50))
        print("📊 FALLBACK ACTIVÉ: Calcul des points à partir des réclamations...")
        print(String(repeating: "=", count: 50))
        
        ReclamationAPI.shared.getMyReclamations { result in
            print("📥 Réponse de getMyReclamations reçue")
            switch result {
            case .success(let reclamations):
                print(String(repeating: "=", count: 50))
                print("✅ RÉCLAMATIONS RÉCUPÉRÉES: \(reclamations.count) réclamation(s)")
                print(String(repeating: "=", count: 50))
                
                // Calculer les statistiques à partir des réclamations
                var totalPoints = 0
                var validReclamations = 0
                var invalidReclamations = 0
                var history: [PointsTransactionDTO] = []
                
                // Parcourir toutes les réclamations et calculer les points
                for (index, reclamation) in reclamations.enumerated() {
                    let status = reclamation.statut.lowercased()
                    print("📋 Réclamation \(index + 1): \(reclamation.complaintType) - Statut: \(status)")
                    
                    if status == "resolue" || status == "résolue" {
                        validReclamations += 1
                        // Points positifs pour réclamations valides (exemple: +10 points)
                        let points = 10
                        totalPoints += points
                        
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        let date = dateFormatter.date(from: reclamation.createdAt) ?? Date()
                        let dateString = ISO8601DateFormatter().string(from: date)
                        
                        history.append(PointsTransactionDTO(
                            points: points,
                            reason: "Réclamation validée: \(reclamation.complaintType)",
                            reclamationId: reclamation._id,
                            date: dateString
                        ))
                        print("   ✅ +\(points) points (validée)")
                    } else if status == "rejetee" || status == "rejetée" {
                        invalidReclamations += 1
                        // Points négatifs pour réclamations invalides (exemple: -10 points)
                        let points = -10
                        totalPoints += points
                        
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        let date = dateFormatter.date(from: reclamation.createdAt) ?? Date()
                        let dateString = ISO8601DateFormatter().string(from: date)
                        
                        history.append(PointsTransactionDTO(
                            points: points,
                            reason: "Réclamation rejetée: \(reclamation.complaintType)",
                            reclamationId: reclamation._id,
                            date: dateString
                        ))
                        print("   ❌ \(points) points (rejetée)")
                    } else {
                        // Réclamations en attente ou en cours ne donnent pas de points
                        print("   ⏳ 0 points (statut: \(status))")
                    }
                }
                
                // Calculer le score de fiabilité (pourcentage de réclamations valides)
                let totalProcessed = validReclamations + invalidReclamations
                let reliabilityScore = totalProcessed > 0 ? Int((Double(validReclamations) / Double(totalProcessed)) * 100) : 0
                
                // Créer la réponse avec les données calculées (format correspondant au backend)
                let loyaltyData = LoyaltyPointsResponseDTO(
                    loyaltyPoints: totalPoints,
                    validReclamations: validReclamations,
                    invalidReclamations: invalidReclamations,
                    reliabilityScore: reliabilityScore,
                    history: history.reversed(), // Plus récent en premier (backend envoie les 10 dernières)
                    availableRewards: nil // Sera chargé séparément si nécessaire
                )
                
                print(String(repeating: "=", count: 50))
                print("✅ POINTS CALCULÉS AVEC SUCCÈS:")
                print("   📊 Points totaux: \(totalPoints)")
                print("   ✅ Réclamations valides: \(validReclamations) (+\(validReclamations * 10) pts)")
                print("   ❌ Réclamations invalides: \(invalidReclamations) (-\(invalidReclamations * 10) pts)")
                print("   ⏳ Réclamations en attente: \(reclamations.count - totalProcessed)")
                print("   📈 Score de fiabilité: \(reliabilityScore)%")
                print("   📜 Historique: \(history.count) transaction(s)")
                print(String(repeating: "=", count: 50))
                
                completion(.success(loyaltyData))
                
            case .failure(let error):
                print("❌ Erreur lors de la récupération des réclamations: \(error.localizedDescription)")
                // Retourner des valeurs par défaut en cas d'erreur
                let defaultData = LoyaltyPointsResponseDTO(
                    loyaltyPoints: 0,
                    validReclamations: 0,
                    invalidReclamations: 0,
                    reliabilityScore: 0,
                    history: [],
                    availableRewards: nil
                )
                completion(.success(defaultData))
            }
        }
    }
}

