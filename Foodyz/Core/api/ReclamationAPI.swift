import Foundation
import UIKit

// MARK: - DTO
struct ReclamationDTO: Codable {
    var commandeConcernee: String
    var complaintType: String
    var description: String
    var photos: [String]?  // Backend expects 'photos' as array, not 'image' as string
    // ✅ Plus besoin de nomClient et emailClient dans le DTO envoyé
    // Le backend les récupère automatiquement du token JWT
    
    // Custom encoding to exclude photos if empty
    enum CodingKeys: String, CodingKey {
        case commandeConcernee
        case complaintType
        case description
        case photos
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(commandeConcernee, forKey: .commandeConcernee)
        try container.encode(complaintType, forKey: .complaintType)
        try container.encode(description, forKey: .description)
        // Only encode photos if it's not nil and not empty
        if let photos = photos, !photos.isEmpty {
            try container.encode(photos, forKey: .photos)
        }
    }
}

// MARK: - API Response
struct ReclamationResponse: Codable {
    var message: String?
    var reclamation: ReclamationDTO?
    var success: Bool?
}

// MARK: - Full Reclamation Response from Backend
struct ReclamationResponseDTO: Codable {
    let _id: String
    let nomClient: String
    let emailClient: String
    let description: String
    let commandeConcernee: String
    let complaintType: String
    let statut: String  // "en_attente" | "en_cours" | "resolue" | "rejetee"
    let photos: [String]?
    let userId: String
    let restaurantEmail: String?
    let restaurantId: String?
    let responseMessage: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case _id
        case nomClient
        case emailClient
        case description
        case commandeConcernee
        case complaintType
        case statut
        case photos
        case userId
        case restaurantEmail
        case restaurantId
        case responseMessage
        case createdAt
        case updatedAt
    }
}

// MARK: - API Client
class ReclamationAPI {
    static let shared = ReclamationAPI()
    
    // Use centralized API constants
    // Backend uses /reclamation (singular) - see reclamation.controller.ts @Controller('reclamation')
    private var baseURL: String {
        let base = AppAPIConstants.baseURL
        return "\(base)/reclamation"  // Backend uses singular 'reclamation', not plural 'reclamations'
    }
    
    private init() {}
    
    // MARK: - POST - Créer une réclamation (avec authentification)
    func createReclamation(_ reclamation: ReclamationDTO, completion: @escaping (Result<ReclamationDTO, Error>) -> Void) {
        print("🔥🔥🔥 FONCTION createReclamation APPELÉE 🔥🔥🔥")
        print("📍 URL du backend: \(baseURL)")
        
        guard let url = URL(string: baseURL) else {
            print("❌ URL invalide: \(baseURL)")
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        // ✅ Récupérer le token d'authentification
        guard let accessToken = TokenManager.shared.getAccessToken() else {
            print("❌ Pas de token d'authentification trouvé")
            completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "Vous devez être connecté pour créer une réclamation"
            ])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        // ✅ Ajouter le token JWT dans le header Authorization
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60 // Increased timeout for better reliability
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("🔑 Token utilisé (30 premiers caractères): \(String(accessToken.prefix(30)))...")
        
        // Encoder les données avec debug détaillé
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(reclamation)
            request.httpBody = jsonData
            
            // 🔍 DEBUG DÉTAILLÉ
            print("🔍 ========== DEBUG REQUEST ==========")
            print("🔍 URL: \(url.absoluteString)")
            print("🔍 Method: POST")
            print("🔍 Headers:")
            print("   Content-Type: application/json")
            print("   Authorization: Bearer \(String(accessToken.prefix(20)))...")
            print("🔍 Body:")
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
            }
            print("🔍 Body size: \(jsonData.count) bytes")
            print("🔍 ====================================")
        } catch {
            print("❌ Erreur d'encodage: \(error.localizedDescription)")
            print("❌ Détails de l'erreur: \(error)")
            completion(.failure(error))
            return
        }
        
        // Create URLSession with custom configuration for better timeout handling
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        
        // Envoyer la requête
        let task = session.dataTask(with: request) { data, response, error in
            // 🔍 DEBUG RESPONSE
            print("🔍 ========== DEBUG RESPONSE ==========")
            
            if let error = error {
                let nsError = error as NSError
                print("❌ Erreur réseau: \(error.localizedDescription)")
                print("   Code d'erreur: \(nsError.code)")
                print("   Domaine: \(nsError.domain)")
                print("   UserInfo: \(nsError.userInfo)")
                
                // Provide more specific error messages
                if nsError.code == NSURLErrorTimedOut {
                    print("⏱️ Timeout: Le serveur n'a pas répondu à temps")
                    completion(.failure(NSError(domain: "Timeout", code: NSURLErrorTimedOut, userInfo: [
                        NSLocalizedDescriptionKey: "La requête a expiré. Vérifiez votre connexion réseau et que le serveur est en cours d'exécution."
                    ])))
                } else if nsError.code == NSURLErrorCannotConnectToHost {
                    print("🔌 Impossible de se connecter au serveur")
                    completion(.failure(NSError(domain: "Connection Error", code: NSURLErrorCannotConnectToHost, userInfo: [
                        NSLocalizedDescriptionKey: "Impossible de se connecter au serveur. Vérifiez que le serveur est en cours d'exécution sur \(self.baseURL)"
                    ])))
                } else {
                    completion(.failure(error))
                }
                print("🔍 ====================================")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Status Code: \(httpResponse.statusCode)")
                print("📥 Response Headers:")
                for (key, value) in httpResponse.allHeaderFields {
                    print("   \(key): \(value)")
                }
                
                // Gérer le cas où le token est invalide ou expiré
                if httpResponse.statusCode == 401 {
                    print("🚫 Token invalide ou expiré")
                    DispatchQueue.main.async {
                        // Rediriger vers la page de login
                        TokenManager.shared.clearAllData()
                        NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
                    }
                    completion(.failure(NSError(domain: "Unauthorized", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: "Session expirée. Veuillez vous reconnecter."
                    ])))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "Erreur HTTP: \(httpResponse.statusCode)"
                    print("❌ \(errorMessage)")
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Réponse du serveur (RAW):")
                        print(responseString)
                        
                        // Try to parse error message
                        if let jsonData = responseString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                            print("📥 Réponse parsée:")
                            if let message = json["message"] {
                                print("   Message: \(message)")
                            }
                            if let error = json["error"] {
                                print("   Error: \(error)")
                            }
                        }
                    } else {
                        print("📥 Aucune donnée dans la réponse d'erreur")
                    }
                    
                    print("🔍 ====================================")
                    completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Erreur HTTP \(httpResponse.statusCode)"
                    ])))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue du serveur")
                print("🔍 ====================================")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            print("📥 Taille des données reçues: \(data.count) bytes")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Réponse brute du serveur:")
                print(responseString)
            }
            print("🔍 ====================================")
            
            do {
                let decoder = JSONDecoder()
                
                if let createdReclamation = try? decoder.decode(ReclamationDTO.self, from: data) {
                    print("✅ Réclamation créée avec succès!")
                    completion(.success(createdReclamation))
                    return
                }
                
                if let response = try? decoder.decode(ReclamationResponse.self, from: data) {
                    if let createdReclamation = response.reclamation {
                        print("✅ Réclamation créée avec succès!")
                        completion(.success(createdReclamation))
                    } else {
                        print("✅ Succès mais pas de réclamation retournée")
                        completion(.success(reclamation))
                    }
                    return
                }
                
                print("✅ Requête réussie (pas de décodage nécessaire)")
                completion(.success(reclamation))
                
            } catch {
                print("❌ Erreur de décodage: \(error.localizedDescription)")
                completion(.success(reclamation))
            }
        }
        
        task.resume()
    }
    // MARK: - ✅ NOUVELLE MÉTHODE - GET - Récupérer MES réclamations
        func getMyReclamations(completion: @escaping (Result<[ReclamationResponseDTO], Error>) -> Void) {
            // ✅ Utiliser le nouvel endpoint
            let urlString = "\(baseURL)/my-reclamations"
            
            print("🔍 Récupération des réclamations de l'utilisateur...")
            print("📍 URL: \(urlString)")
            
            guard let url = URL(string: urlString) else {
                print("❌ URL invalide: \(urlString)")
                completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
                return
            }
            
            guard let accessToken = TokenManager.shared.getAccessToken() else {
                print("❌ Pas de token d'authentification")
                completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: [
                    NSLocalizedDescriptionKey: "Vous devez être connecté"
                ])))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 30
            request.cachePolicy = .reloadIgnoringLocalCacheData
            
            print("🔑 Token utilisé (30 premiers caractères): \(String(accessToken.prefix(30)))...")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Erreur réseau GET: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📥 GET Status Code: \(httpResponse.statusCode)")
                    
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
                    
                    guard (200...299).contains(httpResponse.statusCode) else {
                        print("❌ Erreur HTTP: \(httpResponse.statusCode)")
                        completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ Aucune donnée reçue")
                    completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                    return
                }
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 GET Réponse brute:")
                    print(responseString)
                }
                
                do {
                    let decoder = JSONDecoder()
                    let reclamations = try decoder.decode([ReclamationResponseDTO].self, from: data)
                    print("✅ \(reclamations.count) réclamation(s) récupérée(s) pour cet utilisateur")
                    completion(.success(reclamations))
                } catch {
                    print("❌ Erreur de décodage GET: \(error.localizedDescription)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📥 JSON reçu: \(jsonString.prefix(500))")
                    }
                    completion(.failure(error))
                }
            }
            
            task.resume()
        }
        
    // MARK: - GET - Récupérer toutes les réclamations (avec authentification)
    func getReclamations(completion: @escaping (Result<[ReclamationDTO], Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            print("❌ URL invalide: \(baseURL)")
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        guard let accessToken = TokenManager.shared.getAccessToken() else {
            print("❌ Pas de token d'authentification")
            completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau GET: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 GET Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        TokenManager.shared.clearAllData()
                        NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
                    }
                    completion(.failure(NSError(domain: "Unauthorized", code: 401, userInfo: nil)))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 GET Réponse:")
                print(responseString)
            }
            
            do {
                let decoder = JSONDecoder()
                let reclamations = try decoder.decode([ReclamationDTO].self, from: data)
                print("✅ \(reclamations.count) réclamation(s) récupérée(s)")
                completion(.success(reclamations))
            } catch {
                print("❌ Erreur de décodage GET: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - GET - Récupérer une réclamation par ID (avec authentification)
    func getReclamationById(_ id: String, completion: @escaping (Result<ReclamationDTO, Error>) -> Void) {
        let urlString = "\(baseURL)/\(id)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        guard let accessToken = TokenManager.shared.getAccessToken() else {
            completion(.failure(NSError(domain: "Not authenticated", code: 401, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                DispatchQueue.main.async {
                    TokenManager.shared.clearAllData()
                    NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
                }
                completion(.failure(NSError(domain: "Unauthorized", code: 401, userInfo: nil)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            do {
                let reclamation = try JSONDecoder().decode(ReclamationDTO.self, from: data)
                completion(.success(reclamation))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
