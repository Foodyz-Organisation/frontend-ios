import Foundation

class DealsAPIService {
    static let shared = DealsAPIService()
    
    // ✅ Utiliser AppAPIConstants pour la configuration centralisée
    private var baseURL: String {
        return AppAPIConstants.Deals.base
    }
    
    private init() {}
    
    // MARK: - Helper Method
    private func createRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 60  // 60 secondes de timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
    
    // GET all deals
    func getAllDeals() async throws -> [Deal] {
        let urlString = baseURL
        print("🔍 GET Request vers: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL invalide: \(urlString)")
            throw URLError(.badURL)
        }
        
        let request = createRequest(url: url, method: "GET")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse invalide")
                throw URLError(.badServerResponse)
            }
            
            print("📥 GET Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Status code: \(httpResponse.statusCode)")
                throw URLError(.badServerResponse)
            }
            
            let deals = try JSONDecoder().decode([Deal].self, from: data)
            print("✅ \(deals.count) deals récupéré(s)")
            return deals
        } catch {
            print("❌ Erreur getAllDeals: \(error.localizedDescription)")
            throw error
        }
    }
    
    // GET deal by ID
    func getDealById(_ id: String) async throws -> Deal {
        let urlString = "\(baseURL)/\(id)"
        print("🔍 GET Request vers: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL invalide: \(urlString)")
            throw URLError(.badURL)
        }
        
        let request = createRequest(url: url, method: "GET")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw URLError(.badServerResponse)
            }
            
            let deal = try JSONDecoder().decode(Deal.self, from: data)
            print("✅ Deal récupéré: \(deal.restaurantName)")
            return deal
        } catch {
            print("❌ Erreur getDealById: \(error.localizedDescription)")
            throw error
        }
    }
    
    // POST create deal
    func createDeal(_ dto: CreateDealDto) async throws -> Deal {
        let urlString = baseURL
        print("🔍 POST Request vers: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL invalide: \(urlString)")
            throw URLError(.badURL)
        }
        
        let body = try JSONEncoder().encode(dto)
        let request = createRequest(url: url, method: "POST", body: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse invalide")
                throw URLError(.badServerResponse)
            }
            
            print("📥 POST Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
                print("❌ Status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ Réponse d'erreur: \(errorString)")
                }
                throw URLError(.badServerResponse)
            }
            
            let deal = try JSONDecoder().decode(Deal.self, from: data)
            print("✅ Deal créé: \(deal.restaurantName)")
            return deal
        } catch {
            print("❌ Erreur createDeal: \(error.localizedDescription)")
            throw error
        }
    }
    
    // PATCH update deal
    func updateDeal(_ id: String, dto: UpdateDealDto) async throws -> Deal {
        let urlString = "\(baseURL)/\(id)"
        print("🔍 PATCH Request vers: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL invalide: \(urlString)")
            throw URLError(.badURL)
        }
        
        let body = try JSONEncoder().encode(dto)
        let request = createRequest(url: url, method: "PATCH", body: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw URLError(.badServerResponse)
            }
            
            let deal = try JSONDecoder().decode(Deal.self, from: data)
            print("✅ Deal mis à jour: \(deal.restaurantName)")
            return deal
        } catch {
            print("❌ Erreur updateDeal: \(error.localizedDescription)")
            throw error
        }
    }
    
    // DELETE deal
    func deleteDeal(_ id: String) async throws -> Deal {
        let urlString = "\(baseURL)/\(id)"
        print("🔍 DELETE Request vers: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ URL invalide: \(urlString)")
            throw URLError(.badURL)
        }
        
        let request = createRequest(url: url, method: "DELETE")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("❌ Status code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw URLError(.badServerResponse)
            }
            
            let deal = try JSONDecoder().decode(Deal.self, from: data)
            print("✅ Deal supprimé: \(deal._id)")
            return deal
        } catch {
            print("❌ Erreur deleteDeal: \(error.localizedDescription)")
            throw error
        }
    }
}
