import Foundation

// MARK: - Loyalty Points Response DTO (correspond au PointsBalance du backend)
struct LoyaltyPointsResponseDTO: Codable {
    let loyaltyPoints: Int
    let validReclamations: Int
    let invalidReclamations: Int
    let reliabilityScore: Int
    let history: [PointsTransactionDTO]
    let availableRewards: [RewardDTO]? // Optionnel car peut venir d'un autre endpoint
    
    // Support pour différents formats de réponse du backend
    enum CodingKeys: String, CodingKey {
        case loyaltyPoints
        case validReclamations
        case invalidReclamations
        case reliabilityScore
        case history
        case availableRewards
        // Variantes possibles des noms de champs
        case validReclamationsCount
        case invalidReclamationsCount
        case pointsHistory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // loyaltyPoints (toujours le même nom)
        loyaltyPoints = try container.decode(Int.self, forKey: .loyaltyPoints)
        
        // validReclamations - accepter les deux formats
        if let valid = try? container.decode(Int.self, forKey: .validReclamations) {
            validReclamations = valid
        } else if let valid = try? container.decode(Int.self, forKey: .validReclamationsCount) {
            validReclamations = valid
        } else {
            validReclamations = 0
        }
        
        // invalidReclamations - accepter les deux formats
        if let invalid = try? container.decode(Int.self, forKey: .invalidReclamations) {
            invalidReclamations = invalid
        } else if let invalid = try? container.decode(Int.self, forKey: .invalidReclamationsCount) {
            invalidReclamations = invalid
        } else {
            invalidReclamations = 0
        }
        
        // reliabilityScore
        reliabilityScore = (try? container.decode(Int.self, forKey: .reliabilityScore)) ?? 0
        
        // history - accepter "history" ou "pointsHistory"
        if let hist = try? container.decode([PointsTransactionDTO].self, forKey: .history) {
            history = hist
        } else if let hist = try? container.decode([PointsTransactionDTO].self, forKey: .pointsHistory) {
            history = hist
        } else {
            history = []
        }
        
        // availableRewards (optionnel)
        availableRewards = try? container.decode([RewardDTO].self, forKey: .availableRewards)
    }
    
    // Initializer manuel pour le fallback
    init(loyaltyPoints: Int, validReclamations: Int, invalidReclamations: Int, reliabilityScore: Int, history: [PointsTransactionDTO], availableRewards: [RewardDTO]?) {
        self.loyaltyPoints = loyaltyPoints
        self.validReclamations = validReclamations
        self.invalidReclamations = invalidReclamations
        self.reliabilityScore = reliabilityScore
        self.history = history
        self.availableRewards = availableRewards
    }
    
    // MARK: - Encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(loyaltyPoints, forKey: .loyaltyPoints)
        try container.encode(validReclamations, forKey: .validReclamations)
        try container.encode(invalidReclamations, forKey: .invalidReclamations)
        try container.encode(reliabilityScore, forKey: .reliabilityScore)
        try container.encode(history, forKey: .history)
        try container.encodeIfPresent(availableRewards, forKey: .availableRewards)
    }
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
        guard let accessToken = TokenManager.shared.getAccessToken() else {
            print("❌ Pas de token d'authentification")
            completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Vous devez être connecté"
            ])))
            return
        }
        
        guard let userId = TokenManager.shared.getUserId() else {
            print("❌ Pas d'ID utilisateur disponible")
            completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "ID utilisateur non disponible"
            ])))
            return
        }
        
        print("👤 Récupération des points pour l'utilisateur: \(userId)")
        
        // Liste des endpoints possibles avec et sans userId
        // Le service LoyaltyService a getPointsBalance(userId) - cherchons le contrôleur
        // Note: Ne pas utiliser d'endpoints commençant par /reclamation/ car le backend les interprète comme /reclamation/:id
        let possibleEndpoints = [
            "\(baseURL)/users/\(userId)",                      // Récupérer l'utilisateur complet avec loyaltyPoints
            "\(baseURL)/loyalty/balance/\(userId)",           // Endpoint avec userId dans l'URL
            "\(baseURL)/loyalty/points-balance/\(userId)",    // Alternative avec userId
            "\(baseURL)/users/\(userId)/loyalty/balance",      // Si c'est dans le contrôleur users
            AppAPIConstants.Loyalty.balance,                  // Endpoint défini dans AppAPIConstants (sans userId)
            "\(baseURL)/loyalty/balance",                     // Endpoint sans userId (backend extrait du token)
            "\(baseURL)/loyalty/my-points"                     // Ancien endpoint
            // Endpoints retirés car interprétés comme /reclamation/:id par le backend:
            // - "/reclamation/loyalty/balance/{userId}"
            // - "/reclamation/loyalty-points"
        ]
        
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
                print("📥 Longueur de la réponse: \(responseString.count) caractères")
            }
            
            do {
                let decoder = JSONDecoder()
                
                // Essayer de décoder d'abord comme LoyaltyPointsResponseDTO
                do {
                let loyaltyData = try decoder.decode(LoyaltyPointsResponseDTO.self, from: data)
                print("✅ Points de fidélité récupérés depuis \(urlString): \(loyaltyData.loyaltyPoints)")
                print("✅ Réclamations valides: \(loyaltyData.validReclamations)")
                    print("✅ Réclamations invalides: \(loyaltyData.invalidReclamations)")
                print("✅ Score de fiabilité: \(loyaltyData.reliabilityScore)%")
                    print("✅ Historique: \(loyaltyData.history.count) transaction(s)")
                    completion(.success(loyaltyData))
                    return
                } catch let decodeError {
                    print("⚠️ Erreur de décodage avec LoyaltyPointsResponseDTO: \(decodeError.localizedDescription)")
                    
                    // Essayer de décoder comme un objet User complet (si le backend retourne l'utilisateur)
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        print("📋 Structure JSON reçue:")
                        print("   Clés disponibles: \(jsonObject.keys.joined(separator: ", "))")
                        
                        // Chercher loyaltyPoints dans l'objet (peut être directement ou dans un sous-objet)
                        var points: Int? = nil
                        if let directPoints = jsonObject["loyaltyPoints"] as? Int {
                            points = directPoints
                            print("   ✅ loyaltyPoints trouvé directement: \(directPoints)")
                        } else if let pointsString = jsonObject["loyaltyPoints"] as? String, let parsedPoints = Int(pointsString) {
                            points = parsedPoints
                            print("   ✅ loyaltyPoints trouvé (string converti): \(parsedPoints)")
                        }
                        
                        if let points = points {
                            print("   ✅ Points de fidélité extraits: \(points)")
                            
                            let validCount = jsonObject["validReclamationsCount"] as? Int ?? jsonObject["validReclamations"] as? Int ?? 0
                            let invalidCount = jsonObject["invalidReclamationsCount"] as? Int ?? jsonObject["invalidReclamations"] as? Int ?? 0
                            let score = jsonObject["reliabilityScore"] as? Int ?? 0
                            
                            print("   📊 Statistiques extraites:")
                            print("      - Points: \(points)")
                            print("      - Réclamations valides: \(validCount)")
                            print("      - Réclamations invalides: \(invalidCount)")
                            print("      - Score de fiabilité: \(score)%")
                            
                            // Essayer de récupérer l'historique
                            var history: [PointsTransactionDTO] = []
                            if let historyArray = jsonObject["pointsHistory"] as? [[String: Any]] {
                                for item in historyArray {
                                    if let points = item["points"] as? Int,
                                       let reason = item["reason"] as? String,
                                       let reclamationId = item["reclamationId"] as? String,
                                       let date = item["date"] as? String {
                                        history.append(PointsTransactionDTO(
                                            points: points,
                                            reason: reason,
                                            reclamationId: reclamationId,
                                            date: date
                                        ))
                                    }
                                }
                            } else if let historyArray = jsonObject["history"] as? [[String: Any]] {
                                for item in historyArray {
                                    if let points = item["points"] as? Int,
                                       let reason = item["reason"] as? String,
                                       let reclamationId = item["reclamationId"] as? String,
                                       let date = item["date"] as? String {
                                        history.append(PointsTransactionDTO(
                                            points: points,
                                            reason: reason,
                                            reclamationId: reclamationId,
                                            date: date
                                        ))
                                    }
                                }
                            }
                            
                            let loyaltyData = LoyaltyPointsResponseDTO(
                                loyaltyPoints: points,
                                validReclamations: validCount,
                                invalidReclamations: invalidCount,
                                reliabilityScore: score,
                                history: history,
                                availableRewards: nil
                            )
                            
                            print("✅ Points de fidélité extraits depuis l'objet User: \(points)")
                            print("✅ Réclamations valides: \(validCount)")
                            print("✅ Réclamations invalides: \(invalidCount)")
                completion(.success(loyaltyData))
                            return
                        }
                    }
                    
                    // Si on arrive ici, le format n'est pas reconnu
                    throw decodeError
                }
            } catch {
                print("❌ Erreur de décodage finale pour \(urlString): \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📥 JSON reçu (premiers 1000 caractères): \(String(jsonString.prefix(1000)))")
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

