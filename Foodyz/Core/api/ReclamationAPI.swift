import Foundation
import UIKit

// MARK: - DTO
struct ReclamationDTO: Codable {
    var commandeConcernee: String
    var complaintType: String
    var description: String
    var image: String?
    // ✅ Plus besoin de nomClient et emailClient dans le DTO envoyé
    // Le backend les récupère automatiquement du token JWT
}

// MARK: - API Response
struct ReclamationResponse: Codable {
    var message: String?
    var reclamation: ReclamationDTO?
    var success: Bool?
}

// MARK: - API Client
class ReclamationAPI {
    static let shared = ReclamationAPI()
    
    // ⚠️ IMPORTANT: Changez cette URL selon votre configuration
    private let baseURL = "http://172.18.5.57:3000/reclamation"
    
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
        request.timeoutInterval = 30
        
        print("🔑 Token utilisé (30 premiers caractères): \(String(accessToken.prefix(30)))...")
        
        // Encoder les données
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(reclamation)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Données envoyées au backend:")
                print(jsonString)
            }
        } catch {
            print("❌ Erreur d'encodage: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        // Envoyer la requête
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Status Code: \(httpResponse.statusCode)")
                
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
                        print("📥 Réponse du serveur: \(responseString)")
                    }
                    
                    completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue du serveur")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Réponse brute du serveur:")
                print(responseString)
            }
            
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
        func getMyReclamations(completion: @escaping (Result<[ReclamationDTO], Error>) -> Void) {
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
                    let reclamations = try decoder.decode([ReclamationDTO].self, from: data)
                    print("✅ \(reclamations.count) réclamation(s) récupérée(s) pour cet utilisateur")
                    completion(.success(reclamations))
                } catch {
                    print("❌ Erreur de décodage GET: \(error.localizedDescription)")
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
