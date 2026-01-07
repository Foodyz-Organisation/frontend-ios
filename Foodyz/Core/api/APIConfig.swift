import Foundation

/// APIConfig - Legacy configuration, now uses BaseUrlProvider
/// Kept for backward compatibility with existing code
struct APIConfig {
    /// Base URL string - now uses BaseUrlProvider for automatic detection
    static var baseURLString: String {
        return BaseUrlProvider.shared.baseURL
    }
    
    /// Base URL as URL object
    static var baseURL: URL {
        // Use BaseUrlProvider's baseURLObject, fallback to a default if nil
        return BaseUrlProvider.shared.baseURLObject ?? URL(string: "http://127.0.0.1:3000")!
    }
}
