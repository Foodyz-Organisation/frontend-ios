import Foundation

struct APIConfig {
    static var baseURLString: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:3000"
        #else
        return "http://192.168.1.186:3000"
        #endif
    }
    
    static var baseURL: URL {
        return URL(string: baseURLString)!
    }
}
