import Foundation
import UIKit

// MARK: - DTO
struct EventDTO: Codable {
    var id: String?
    var _id: String?
    var nom: String
    var description: String
    var dateDebut: String
    var dateFin: String
    var image: String?
    var lieu: String
    var categorie: String
    var statut: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case nom
        case name
        case title
        case description
        case dateDebut
        case date_debut
        case startDate
        case dateFin
        case date_fin
        case endDate
        case image
        case lieu
        case location
        case place
        case categorie
        case category
        case type
        case statut
        case status
        case state
    }
    
    // Custom decoder to handle both id and _id, and different field name formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id fields (id or _id)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        _id = try container.decodeIfPresent(String.self, forKey: ._id)
        
        // Handle nom (try multiple field names)
        if let nomValue = try? container.decode(String.self, forKey: .nom) {
            nom = nomValue
        } else if let nameValue = try? container.decode(String.self, forKey: .name) {
            nom = nameValue
        } else if let titleValue = try? container.decode(String.self, forKey: .title) {
            nom = titleValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.nom, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot find nom, name, or title field"))
        }
        
        // Handle description
        description = try container.decode(String.self, forKey: .description)
        
        // Handle dateDebut (try multiple field names)
        if let dateDebutValue = try? container.decode(String.self, forKey: .dateDebut) {
            dateDebut = dateDebutValue
        } else if let date_debutValue = try? container.decode(String.self, forKey: .date_debut) {
            dateDebut = date_debutValue
        } else if let startDateValue = try? container.decode(String.self, forKey: .startDate) {
            dateDebut = startDateValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.dateDebut, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot find dateDebut, date_debut, or startDate field"))
        }
        
        // Handle dateFin (try multiple field names)
        if let dateFinValue = try? container.decode(String.self, forKey: .dateFin) {
            dateFin = dateFinValue
        } else if let date_finValue = try? container.decode(String.self, forKey: .date_fin) {
            dateFin = date_finValue
        } else if let endDateValue = try? container.decode(String.self, forKey: .endDate) {
            dateFin = endDateValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.dateFin, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot find dateFin, date_fin, or endDate field"))
        }
        
        // Handle optional image
        image = try container.decodeIfPresent(String.self, forKey: .image)
        
        // Handle lieu (try multiple field names)
        if let lieuValue = try? container.decode(String.self, forKey: .lieu) {
            lieu = lieuValue
        } else if let locationValue = try? container.decode(String.self, forKey: .location) {
            lieu = locationValue
        } else if let placeValue = try? container.decode(String.self, forKey: .place) {
            lieu = placeValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.lieu, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot find lieu, location, or place field"))
        }
        
        // Handle categorie (try multiple field names)
        if let categorieValue = try? container.decode(String.self, forKey: .categorie) {
            categorie = categorieValue
        } else if let categoryValue = try? container.decode(String.self, forKey: .category) {
            categorie = categoryValue
        } else if let typeValue = try? container.decode(String.self, forKey: .type) {
            categorie = typeValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.categorie, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot find categorie, category, or type field"))
        }
        
        // Handle statut (try multiple field names)
        if let statutValue = try? container.decode(String.self, forKey: .statut) {
            statut = statutValue
        } else if let statusValue = try? container.decode(String.self, forKey: .status) {
            statut = statusValue
        } else if let stateValue = try? container.decode(String.self, forKey: .state) {
            statut = stateValue
        } else {
            throw DecodingError.keyNotFound(CodingKeys.statut, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot find statut, status, or state field"))
        }
    }
    
    // Custom encoder - Envoie les données en snake_case pour correspondre au backend NestJS/Mongoose
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Envoyer id ou _id si présent
        if let idValue = id {
            try container.encode(idValue, forKey: .id)
        } else if let idValue = _id {
            try container.encode(idValue, forKey: ._id)
        }
        
        // Envoyer nom
        try container.encode(nom, forKey: .nom)
        
        // Envoyer description
        try container.encode(description, forKey: .description)
        
        // ⚠️ IMPORTANT: Envoyer en snake_case pour correspondre au backend
        // Le backend attend date_debut et date_fin (snake_case)
        try container.encode(dateDebut, forKey: .date_debut)
        try container.encode(dateFin, forKey: .date_fin)
        
        // Envoyer image si présente
        if let imageValue = image {
            try container.encode(imageValue, forKey: .image)
        }
        
        // Envoyer lieu
        try container.encode(lieu, forKey: .lieu)
        
        // Envoyer categorie
        try container.encode(categorie, forKey: .categorie)
        
        // Envoyer statut
        try container.encode(statut, forKey: .statut)
    }
    
    // Convenience initializer
    init(id: String? = nil, _id: String? = nil, nom: String, description: String, dateDebut: String, dateFin: String, image: String? = nil, lieu: String, categorie: String, statut: String) {
        self.id = id
        self._id = _id
        self.nom = nom
        self.description = description
        self.dateDebut = dateDebut
        self.dateFin = dateFin
        self.image = image
        self.lieu = lieu
        self.categorie = categorie
        self.statut = statut
    }
    
    // Convert to Event model
    func toEvent() -> Event? {
        // Normalisation du statut pour éviter les erreurs de casse ou d'accents
        let normalizedStatut = statut
            .lowercased()
            .replacingOccurrences(of: "à", with: "a") // simplifie les accents
        
        let status: EventStatus
        switch normalizedStatut {
        case "a venir": status = .aVenir
        case "en cours": status = .enCours
        case "termine", "terminé": status = .termine
        default:
            print("⚠️ Statut inconnu: \(statut)")
            return nil
        }
        
        let eventId = id ?? _id ?? UUID().uuidString
        
        return Event(
            id: eventId,
            nom: nom,
            description: description,
            dateDebut: dateDebut,
            dateFin: dateFin,
            image: image,
            lieu: lieu,
            categorie: categorie,
            statut: status
        )
    }

}

// MARK: - API Response
struct EventResponse: Codable {
    var message: String?
    var event: EventDTO?
    var success: Bool?
}

// MARK: - API Client
// MARK: - API Client avec routes corrigées
class EventAPI {
    static let shared = EventAPI()
    
    // ⚠️ IMPORTANT: Vérifiez votre backend Node.js
    // Les routes possibles sont généralement:
    // - /events (PLURIEL) ✅ Le plus courant
    // - /api/events ✅
    // - /event (SINGULIER) - moins courant
    
    // 🔧 CHANGEZ CETTE LIGNE selon votre backend:
    private let baseURL = "http://172.18.5.57:3000/events"  // ← Notez le 's' à la fin!
    // OU si vous avez un préfixe /api:
    // private let baseURL = "http://localhost:3000/api/events"
    
    private init() {}
    
    // MARK: - GET - Récupérer tous les événements
    func getEvents(completion: @escaping (Result<[EventDTO], Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            print("❌ URL invalide: \(baseURL)")
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        print("🔍 GET Request vers: \(url.absoluteString)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau GET: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 GET Status Code: \(httpResponse.statusCode)")
                
                // Si 404, donner un message clair
                if httpResponse.statusCode == 404 {
                    print("❌ ERREUR 404: La route n'existe pas!")
                    print("💡 SOLUTIONS:")
                    print("   1. Vérifiez votre fichier backend (server.js ou app.js)")
                    print("   2. La route est probablement '/events' (PLURIEL) et non '/event'")
                    print("   3. Ou '/api/events' si vous avez un préfixe /api")
                    print("   4. Vérifiez avec: app.get('/events', ...) dans votre backend")
                    
                    let error = NSError(
                        domain: "Route non trouvée",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "La route \(url.absoluteString) n'existe pas sur le serveur"]
                    )
                    completion(.failure(error))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
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
                print("📥 RÉPONSE BRUTE:")
                print(responseString)
            }
            
            let decoder = JSONDecoder()
            
            // Format 1: Array direct [...]
            if let events = try? decoder.decode([EventDTO].self, from: data) {
                print("✅ \(events.count) événement(s) récupéré(s)")
                completion(.success(events))
                return
            }
            
            // Format 2: Wrapper {events: [...]}
            struct EventsWrapper: Codable {
                let events: [EventDTO]
            }
            if let wrapper = try? decoder.decode(EventsWrapper.self, from: data) {
                print("✅ \(wrapper.events.count) événement(s) récupéré(s)")
                completion(.success(wrapper.events))
                return
            }
            
            // Si échec, afficher l'erreur
            do {
                let _ = try decoder.decode([EventDTO].self, from: data)
            } catch {
                print("❌ Erreur de décodage: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - POST - Créer un événement
    func createEvent(_ event: EventDTO, completion: @escaping (Result<EventDTO, Error>) -> Void) {
        print("📤 POST Request vers: \(baseURL)")
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(event)
            request.httpBody = jsonData
            
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Données envoyées:")
                print(jsonString)
            }
        } catch {
            print("❌ Erreur d'encodage: \(error)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau POST: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 POST Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 404 {
                    print("❌ ERREUR 404 sur POST: Vérifiez la route dans votre backend")
                    completion(.failure(NSError(domain: "Route not found", code: 404, userInfo: nil)))
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
            }
            
            guard let data = data else {
                print("⚠️ Pas de données retournées (mais succès)")
                completion(.success(event))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📥 Réponse POST:")
                print(responseString)
            }
            
            // Essayer de décoder la réponse
            if let createdEvent = try? JSONDecoder().decode(EventDTO.self, from: data) {
                print("✅ Événement créé avec succès!")
                completion(.success(createdEvent))
            } else {
                print("✅ Création réussie (réponse non décodée)")
                completion(.success(event))
            }
        }
        
        task.resume()
    }
    
    // MARK: - GET by ID
    func getEventById(_ id: String, completion: @escaping (Result<EventDTO, Error>) -> Void) {
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
                let event = try JSONDecoder().decode(EventDTO.self, from: data)
                completion(.success(event))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - PUT - Mettre à jour
    func updateEvent(_ id: String, event: EventDTO, completion: @escaping (Result<EventDTO, Error>) -> Void) {
        let urlString = "\(baseURL)/\(id)"
        print("🔄 URL de mise à jour: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(event)
            request.httpBody = jsonData
            
            // 🔹 Intégration du debug JSON et du statut
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 JSON envoyé:")
                print(jsonString)
                
                // Vérifier le statut spécifiquement
                if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let statut = json["statut"] as? String {
                    print("✅ Statut envoyé: '\(statut)'")
                    print("✅ Caractères: \(Array(statut))")
                }
            }
        } catch {
            print("❌ Erreur d'encodage PUT: \(error)")
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau PUT: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 PUT Status Code: \(httpResponse.statusCode)")
                print("📥 Headers: \(httpResponse.allHeaderFields)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let error = NSError(
                        domain: "HTTP Error",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Erreur HTTP \(httpResponse.statusCode)"]
                    )
                    completion(.failure(error))
                    return
                }
            }
            
            if let data = data {
                let dataSize = data.count
                print("📥 Taille des données reçues: \(dataSize) bytes")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📥 Réponse brute du serveur:")
                    print(responseString)
                }
                
                // Décodage réponse
                let decoder = JSONDecoder()
                if let updatedEvent = try? decoder.decode(EventDTO.self, from: data) {
                    print("✅ Événement décodé avec succès!")
                    completion(.success(updatedEvent))
                    return
                } else {
                    print("⚠️ Impossible de décoder la réponse, utilisation des données envoyées")
                    completion(.success(event))
                }
            } else {
                print("⚠️ Aucune donnée reçue du serveur")
                completion(.success(event))
            }
        }
        
        task.resume()
    }

    
    // MARK: - DELETE
    func deleteEvent(_ id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "\(baseURL)/\(id)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
                    return
                }
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
}

// MARK: - 🔧 GUIDE DE VÉRIFICATION BACKEND
/*
 VÉRIFIEZ VOTRE FICHIER BACKEND (server.js ou app.js):
 
 ✅ La route doit être:
    app.get('/events', ...)      // PLURIEL
    app.post('/events', ...)
    app.get('/events/:id', ...)
    app.put('/events/:id', ...)
    app.delete('/events/:id', ...)
 
 ❌ PAS:
    app.get('/event', ...)       // SINGULIER
 
 Si vous avez un préfixe /api:
    app.get('/api/events', ...)
    → Changez baseURL en "http://localhost:3000/api/events"
 
 Pour tester rapidement dans le terminal:
    curl http://localhost:3000/events
    → Doit retourner vos événements, pas une erreur 404
*/
