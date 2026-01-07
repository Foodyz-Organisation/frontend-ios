import Foundation
import UIKit

/// BaseUrlProvider - Automatically detects simulator vs real device and switches base URL
/// Similar to Android's BaseUrlProvider for consistent behavior across platforms
final class BaseUrlProvider {
    
    // MARK: - Configuration Constants
    
    /// Set to false to use MANUAL_BASE_URL instead of auto-detection
    private static let USE_AUTO_DETECTION = true
    
    /// Manual base URL (used when USE_AUTO_DETECTION is false)
    private static let MANUAL_BASE_URL = "http://127.0.0.1:3000"
    
    /// Base URL for iOS Simulator
    /// Use localhost or 127.0.0.1 for simulator
    private static let SIMULATOR_BASE_URL = "http://127.0.0.1:3000"
    
    /// Base URL for real iOS device
    /// ⚠️ IMPORTANT: Replace with your Mac's IP address
    /// Find your Mac's IP: System Settings > Network > Wi-Fi > Details
    /// Or run in terminal: ifconfig | grep "inet " | grep -v 127.0.0.1
    private static let REAL_DEVICE_BASE_URL = "http://192.168.149.33:3000"
    
    // MARK: - Singleton
    
    static let shared = BaseUrlProvider()
    private init() {}
    
    // MARK: - Device Detection
    
    /// Detects if running on iOS Simulator
    private static func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        // Additional checks for real device
        // These are extra safety checks, but #if targetEnvironment(simulator) is the primary method
        return false
        #endif
    }
    
    // MARK: - Base URL Properties
    
    /// Main BASE_URL - use this everywhere in your app
    /// Automatically switches between simulator and real device
    lazy var baseURL: String = {
        let url: String
        
        if Self.USE_AUTO_DETECTION {
            let isSim = Self.isSimulator()
            print("🔍 [BaseUrlProvider] Auto-detection: isSimulator = \(isSim)")
            
            if isSim {
                print("📱 [BaseUrlProvider] Using SIMULATOR URL: \(Self.SIMULATOR_BASE_URL)")
                url = Self.SIMULATOR_BASE_URL
            } else {
                print("📲 [BaseUrlProvider] Using REAL DEVICE URL: \(Self.REAL_DEVICE_BASE_URL)")
                print("⚠️ [BaseUrlProvider] Make sure your computer IP is correct: \(Self.REAL_DEVICE_BASE_URL)")
                url = Self.REAL_DEVICE_BASE_URL
            }
        } else {
            print("🔧 [BaseUrlProvider] Using MANUAL URL: \(Self.MANUAL_BASE_URL)")
            url = Self.MANUAL_BASE_URL
        }
        
        print("✅ [BaseUrlProvider] Final BASE_URL selected: \(url)")
        return url
    }()
    
    /// BASE_URL with trailing slash (for URL construction)
    var baseURLWithSlash: String {
        if baseURL.hasSuffix("/") {
            return baseURL
        } else {
            return "\(baseURL)/"
        }
    }
    
    /// BASE_URL as URL object
    var baseURLObject: URL? {
        return URL(string: baseURL)
    }
    
    // MARK: - Image URL Helper
    
    /// Get full image URL from a path (handles both Supabase URLs and legacy relative paths)
    ///
    /// After Supabase migration:
    /// - New uploads return full Supabase URLs (e.g., https://xxx.supabase.co/storage/v1/object/public/...)
    /// - These URLs are returned directly without modification
    /// - Legacy relative paths (e.g., /uploads/image.jpg) are still supported for backward compatibility
    ///
    /// - Parameter path: Image path from API response (can be full Supabase URL or relative path)
    /// - Returns: Full URL ready to use in image loading, or nil if path is nil/empty
    func getFullImageUrl(_ path: String?) -> String? {
        guard let path = path, !path.isEmpty else {
            return nil
        }
        
        // If it's already a full URL (Supabase or any http/https URL), use it directly
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return path
        } else {
            // Legacy support: construct full URL from relative path
            // This handles old data that might still have relative paths
            let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
            return "\(baseURLWithSlash)\(cleanPath)"
        }
    }
    
    // MARK: - Configuration Info
    
    /// Get current configuration info (for debugging)
    func getConfigInfo() -> String {
        var info = "BaseUrlProvider Configuration:\n"
        info += "  Auto-detection: \(Self.USE_AUTO_DETECTION)\n"
        
        if Self.USE_AUTO_DETECTION {
            let deviceType = Self.isSimulator() ? "Simulator" : "Real Device"
            info += "  Detected device: \(deviceType)\n"
        }
        
        info += "  Current BASE_URL: \(baseURL)\n"
        info += "  BASE_URL with slash: \(baseURLWithSlash)\n"
        
        return info
    }
    
    /// Print configuration info to console
    func printConfigInfo() {
        print("🌐 ============================================")
        print(getConfigInfo())
        print("🌐 ============================================")
    }
}

// MARK: - Convenience Extensions

extension BaseUrlProvider {
    /// Convenience property for backward compatibility with APIConfig
    static var baseURLString: String {
        return shared.baseURL
    }
    
    /// Convenience property for backward compatibility
    static var baseURL: URL? {
        return shared.baseURLObject
    }
}

