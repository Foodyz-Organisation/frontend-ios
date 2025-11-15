import Foundation
import UIKit

// MARK: - DTO
struct ReclamationDTO: Codable {
    var commandeConcernee: String
    var complaintType: String
    var description: String
    var image: String?
    var nomClient: String
    var emailClient: String
}

// MARK: - API Response (pour gérer la réponse du backend)
struct ReclamationResponse: Codable {
    var message: String?
    var reclamation: ReclamationDTO?
    var success: Bool?
}

// MARK: - API Client
class ReclamationAPI {
    static let shared = ReclamationAPI()
    
    // ⚠️ IMPORTANT: Changez cette URL selon votre configuration
    // Si vous testez sur simulateur iOS: http://localhost:3000
    // Si vous testez sur appareil réel: http://VOTRE_IP_LOCAL:3000
    // Exemple: http://192.168.1.10:3000
    private let baseURL = "http://localhost:3000/reclamation"
    
    private init() {}
    
    // MARK: - POST - Créer une réclamation
    func createReclamation(_ reclamation: ReclamationDTO, completion: @escaping (Result<ReclamationDTO, Error>) -> Void) {
        // 🔥 TEST: Ce message devrait TOUJOURS s'afficher
        print("🔥🔥🔥 FONCTION createReclamation APPELÉE 🔥🔥🔥")
        print("📍 URL du backend: \(baseURL)")
        
        guard let url = URL(string: baseURL) else {
            print("❌ URL invalide: \(baseURL)")
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        // Encoder les données
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Pour le debug
            let jsonData = try encoder.encode(reclamation)
            request.httpBody = jsonData
            
            // 📝 DEBUG: Afficher les données envoyées
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
            // Vérifier les erreurs réseau
            if let error = error {
                print("❌ Erreur réseau: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Vérifier la réponse HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 Status Code: \(httpResponse.statusCode)")
                
                // Vérifier si la requête a réussi (200-299)
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = "Erreur HTTP: \(httpResponse.statusCode)"
                    print("❌ \(errorMessage)")
                    
                    // Afficher le contenu de la réponse pour debug
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📥 Réponse du serveur: \(responseString)")
                    }
                    
                    completion(.failure(NSError(domain: errorMessage, code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
            }
            
            // Vérifier les données reçues
            guard let data = data else {
                print("❌ Aucune donnée reçue du serveur")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            // 📝 DEBUG: Afficher la réponse brute
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Réponse brute du serveur:")
                print(responseString)
            }
            
            // Décoder la réponse
            do {
                let decoder = JSONDecoder()
                
                // Essayer de décoder comme ReclamationDTO directement
                if let createdReclamation = try? decoder.decode(ReclamationDTO.self, from: data) {
                    print("✅ Réclamation créée avec succès!")
                    completion(.success(createdReclamation))
                    return
                }
                
                // Sinon, essayer comme ReclamationResponse
                if let response = try? decoder.decode(ReclamationResponse.self, from: data) {
                    if let createdReclamation = response.reclamation {
                        print("✅ Réclamation créée avec succès!")
                        completion(.success(createdReclamation))
                    } else {
                        print("✅ Succès mais pas de réclamation retournée")
                        completion(.success(reclamation)) // Retourner l'original
                    }
                    return
                }
                
                // Si aucun décodage ne fonctionne
                print("✅ Requête réussie (pas de décodage nécessaire)")
                completion(.success(reclamation))
                
            } catch {
                print("❌ Erreur de décodage: \(error.localizedDescription)")
                // Même si le décodage échoue, si le code HTTP est 200-299, considérer comme succès
                completion(.success(reclamation))
            }
        }
        
        task.resume()
    }
    
    // MARK: - GET - Récupérer toutes les réclamations
    func getReclamations(completion: @escaping (Result<[ReclamationDTO], Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            print("❌ URL invalide: \(baseURL)")
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        // Pour éviter le cache
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau GET: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 GET Status Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data else {
                print("❌ Aucune donnée reçue")
                completion(.failure(NSError(domain: "No data", code: -1, userInfo: nil)))
                return
            }
            
            // 📝 DEBUG: Afficher la réponse
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
    
    // MARK: - GET - Récupérer une réclamation par ID
    func getReclamationById(_ id: String, completion: @escaping (Result<ReclamationDTO, Error>) -> Void) {
        let urlString = "\(baseURL)/\(id)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
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
