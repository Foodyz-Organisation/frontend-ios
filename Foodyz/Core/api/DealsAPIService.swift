import Foundation

class DealsAPIService {
    static let shared = DealsAPIService()
    private let baseURL = "http://192.168.1.10:3000/"
    
    private init() {}
    
    // GET all deals
    func getAllDeals() async throws -> [Deal] {
        let url = URL(string: "\(baseURL)deals")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let deals = try JSONDecoder().decode([Deal].self, from: data)
        return deals
    }
    
    // GET deal by ID
    func getDealById(_ id: String) async throws -> Deal {
        let url = URL(string: "\(baseURL)deals/\(id)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let deal = try JSONDecoder().decode(Deal.self, from: data)
        return deal
    }
    
    // POST create deal
    func createDeal(_ dto: CreateDealDto) async throws -> Deal {
        let url = URL(string: "\(baseURL)deals")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(dto)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let deal = try JSONDecoder().decode(Deal.self, from: data)
        return deal
    }
    
    // PATCH update deal
    func updateDeal(_ id: String, dto: UpdateDealDto) async throws -> Deal {
        let url = URL(string: "\(baseURL)deals/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(dto)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let deal = try JSONDecoder().decode(Deal.self, from: data)
        return deal
    }
    
    // DELETE deal
    func deleteDeal(_ id: String) async throws -> Deal {
        let url = URL(string: "\(baseURL)deals/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let deal = try JSONDecoder().decode(Deal.self, from: data)
        return deal
    }
}
