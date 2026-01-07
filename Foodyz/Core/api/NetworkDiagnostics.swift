import Foundation
import Network

/// NetworkDiagnostics - Helps diagnose network connection issues
final class NetworkDiagnostics {
    static let shared = NetworkDiagnostics()
    private init() {}
    
    /// Test connection to the server
    func testServerConnection(completion: @escaping (Result<DiagnosticResult, Error>) -> Void) {
        let baseURL = BaseUrlProvider.shared.baseURL
        // Try health endpoint first, fallback to root
        let urlString = "\(baseURL)/health"
        guard let url = URL(string: urlString) else {
            // Fallback to root
            guard let fallbackURL = URL(string: "\(baseURL)/") else {
                completion(.failure(DiagnosticError.invalidURL))
                return
            }
            performConnectionTest(url: fallbackURL, baseURL: baseURL, completion: completion)
            return
        }
        performConnectionTest(url: url, baseURL: baseURL, completion: completion)
    }
    
    private func performConnectionTest(url: URL, baseURL: String, completion: @escaping (Result<DiagnosticResult, Error>) -> Void) {
        
        print("🔍 [NetworkDiagnostics] Testing connection to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            var result = DiagnosticResult()
            result.baseURL = baseURL
            result.timestamp = Date()
            
            // Check for errors
            if let error = error {
                result.hasError = true
                result.errorMessage = error.localizedDescription
                
                if let nsError = error as NSError? {
                    result.errorCode = nsError.code
                    result.errorDomain = nsError.domain
                    
                    // Check for local network permission issue
                    if nsError.code == -1009 {
                        if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError,
                           let pathKey = underlyingError.userInfo["_NSURLErrorNWPathKey"] as? String,
                           pathKey.contains("unsatisfied") || pathKey.contains("prohibited") {
                            result.isLocalNetworkBlocked = true
                            result.suggestedFix = "Enable Local Network permission in Settings > Privacy & Security > Local Network > Foodyz"
                        }
                    }
                }
                
                completion(.failure(error))
                return
            }
            
            // Check response
            if let httpResponse = response as? HTTPURLResponse {
                result.httpStatusCode = httpResponse.statusCode
                result.isConnected = true
                result.responseReceived = true
                
                if (200...299).contains(httpResponse.statusCode) {
                    result.isServerResponding = true
                    result.success = true
                } else {
                    result.isServerResponding = true
                    result.success = false
                    result.errorMessage = "Server returned status code: \(httpResponse.statusCode)"
                }
            }
            
            if let data = data {
                result.responseDataSize = data.count
            }
            
            completion(.success(result))
        }
        
        task.resume()
    }
    
    /// Get network diagnostics information
    func getDiagnosticsInfo() -> String {
        let baseURL = BaseUrlProvider.shared.baseURL
        #if targetEnvironment(simulator)
        let isSimulator = true
        #else
        let isSimulator = false
        #endif
        
        var info = """
        📊 Network Diagnostics
        =====================
        Base URL: \(baseURL)
        Device Type: \(isSimulator ? "Simulator" : "Real Device")
        Timestamp: \(Date())
        
        """
        
        // Check network path
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        let path = monitor.currentPath
        info += """
        Network Status:
        - Status: \(path.status == .satisfied ? "✅ Connected" : "❌ Not Connected")
        - Interface: \(path.availableInterfaces.map { $0.name }.joined(separator: ", "))
        - Expensive: \(path.isExpensive ? "Yes" : "No")
        - Constrained: \(path.isConstrained ? "Yes" : "No")
        
        """
        
        monitor.cancel()
        
        return info
    }
}


struct DiagnosticResult {
    var baseURL: String = ""
    var timestamp: Date = Date()
    var hasError: Bool = false
    var errorMessage: String?
    var errorCode: Int?
    var errorDomain: String?
    var isLocalNetworkBlocked: Bool = false
    var suggestedFix: String?
    var isConnected: Bool = false
    var responseReceived: Bool = false
    var httpStatusCode: Int?
    var isServerResponding: Bool = false
    var responseDataSize: Int = 0
    var success: Bool = false
    
    var summary: String {
        var summary = "📊 Connection Test Results\n"
        summary += "========================\n"
        summary += "URL: \(baseURL)\n"
        summary += "Time: \(timestamp)\n\n"
        
        if success {
            summary += "✅ Status: SUCCESS\n"
            summary += "✅ Server is responding\n"
            if let statusCode = httpStatusCode {
                summary += "✅ HTTP Status: \(statusCode)\n"
            }
        } else if isLocalNetworkBlocked {
            summary += "❌ Status: LOCAL NETWORK BLOCKED\n"
            summary += "⚠️ iOS is blocking local network access\n"
            if let fix = suggestedFix {
                summary += "\n💡 Fix: \(fix)\n"
            }
        } else if hasError {
            summary += "❌ Status: CONNECTION FAILED\n"
            if let error = errorMessage {
                summary += "❌ Error: \(error)\n"
            }
            if let code = errorCode {
                summary += "❌ Code: \(code)\n"
            }
        } else {
            summary += "⚠️ Status: UNKNOWN\n"
        }
        
        return summary
    }
}

enum DiagnosticError: Error, LocalizedError {
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for connection test"
        }
    }
}

