import Foundation

// MARK: - Token Manager pour stocker les informations d'authentification
class TokenManager {
    static let shared = TokenManager()
    
    private let userDefaults = UserDefaults.standard
    
    // Clés de stockage
    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let userId = "user_id"
        static let userRole = "user_role"
        static let userName = "user_name"
        static let userEmail = "user_email"
    }
    
    private init() {}
    
    // MARK: - Save User Data after Login
    func saveUserData(
        accessToken: String,
        refreshToken: String,
        userId: String,
        role: String,
        name: String,
        email: String
    ) {
        print("========== SAVING USER DATA ==========")
        print("AccessToken (first 30 chars): \(String(accessToken.prefix(30)))...")
        print("RefreshToken present: \(!refreshToken.isEmpty)")
        print("UserId: \(userId)")
        print("Role: \(role)")
        print("Name: \(name)")
        print("Email: \(email)")
        
        userDefaults.set(accessToken, forKey: Keys.accessToken)
        userDefaults.set(refreshToken, forKey: Keys.refreshToken)
        userDefaults.set(userId, forKey: Keys.userId)
        userDefaults.set(role, forKey: Keys.userRole)
        userDefaults.set(name, forKey: Keys.userName)
        userDefaults.set(email, forKey: Keys.userEmail)
        
        userDefaults.synchronize()
        
        print("✅ User data saved successfully")
        print("======================================")
    }
    
    // MARK: - Getters
    func getAccessToken() -> String? {
        let token = userDefaults.string(forKey: Keys.accessToken)
        if let token = token {
            print("🔑 getAccessToken() -> \(String(token.prefix(30)))...")
        } else {
            print("⚠️ getAccessToken() -> NULL")
        }
        return token
    }
    
    func getRefreshToken() -> String? {
        let token = userDefaults.string(forKey: Keys.refreshToken)
        print("🔄 getRefreshToken() -> \(token != nil ? "EXISTS" : "NULL")")
        return token
    }
    
    func getUserId() -> String? {
        let userId = userDefaults.string(forKey: Keys.userId)
        if let userId = userId {
            print("👤 getUserId() -> \(userId)")
        } else {
            print("⚠️ getUserId() -> NULL")
        }
        return userId
    }
    
    func getUserRole() -> String? {
        let role = userDefaults.string(forKey: Keys.userRole)
        print("🎭 getUserRole() -> \(role ?? "NULL")")
        return role
    }
    
    func getUserName() -> String? {
        let name = userDefaults.string(forKey: Keys.userName)
        print("📝 getUserName() -> \(name ?? "NULL")")
        return name
    }
    
    func getUserEmail() -> String? {
        let email = userDefaults.string(forKey: Keys.userEmail)
        print("📧 getUserEmail() -> \(email ?? "NULL")")
        return email
    }
    
    // MARK: - Check Login Status
    func isLoggedIn() -> Bool {
        let isLogged = getAccessToken() != nil
        print("🔐 isLoggedIn() -> \(isLogged)")
        return isLogged
    }
    
    // MARK: - Clear All Data (Logout)
    func clearAllData() {
        print("🗑️ Clearing all user data...")
        
        userDefaults.removeObject(forKey: Keys.accessToken)
        userDefaults.removeObject(forKey: Keys.refreshToken)
        userDefaults.removeObject(forKey: Keys.userId)
        userDefaults.removeObject(forKey: Keys.userRole)
        userDefaults.removeObject(forKey: Keys.userName)
        userDefaults.removeObject(forKey: Keys.userEmail)
        
        userDefaults.synchronize()
        
        print("✅ All user data cleared")
    }
    
    // MARK: - Update Access Token (for refresh)
    func updateAccessToken(_ newToken: String) {
        print("🔄 Updating access token...")
        print("New token (first 30 chars): \(String(newToken.prefix(30)))...")
        
        userDefaults.set(newToken, forKey: Keys.accessToken)
        userDefaults.synchronize()
        
        print("✅ Access token updated")
    }
    
    // MARK: - Debug Print All
    func debugPrintAll() {
        print("========== DEBUG ALL USER DATA ==========")
        print("AccessToken: \(getAccessToken()?.prefix(30) ?? "NULL")...")
        print("RefreshToken: \(getRefreshToken() != nil ? "EXISTS" : "NULL")")
        print("UserId: \(getUserId() ?? "NULL")")
        print("Role: \(getUserRole() ?? "NULL")")
        print("Name: \(getUserName() ?? "NULL")")
        print("Email: \(getUserEmail() ?? "NULL")")
        print("==========================================")
    }
}
