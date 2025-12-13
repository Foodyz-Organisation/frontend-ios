import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var licenseNumber = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn = false
    @Published var userRole: AppUserRole? = nil

    private let session = SessionManager.shared

    // MARK: - Login
    func login(onSuccess: ((AppUserRole) -> Void)? = nil) async {
        isLoading = true
        errorMessage = nil

        // 🔍 DEBUG: Log raw values
        print("🔍 ========== AUTH VIEWMODEL DEBUG ==========")
        print("🔍 Raw Email: '\(email)' (length: \(email.count), isEmpty: \(email.isEmpty))")
        print("🔍 Raw Password: '\(String(repeating: "*", count: password.count))' (length: \(password.count), isEmpty: \(password.isEmpty))")
        
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Clean Email: '\(cleanEmail)' (length: \(cleanEmail.count), isEmpty: \(cleanEmail.isEmpty))")
        print("🔍 Clean Password length: \(cleanPassword.count), isEmpty: \(cleanPassword.isEmpty)")
        print("🔍 ==========================================")

        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            let errorMsg = "Please enter both email and password."
            print("❌ VALIDATION FAILED:")
            print("   - Email empty: \(cleanEmail.isEmpty)")
            print("   - Password empty: \(cleanPassword.isEmpty)")
            errorMessage = errorMsg
            isLoading = false
            return
        }

        do {
            print("🚀 ========== API CALL DEBUG ==========")
            print("🚀 Endpoint: login")
            print("🚀 Request Email: '\(cleanEmail)'")
            print("🚀 Request Password length: \(cleanPassword.count)")
            print("🚀 Making API call...")
            
            let loginData = LoginRequest(email: cleanEmail, password: cleanPassword)
            let response: LoginResponse = try await AuthAPI.shared.post(
                endpoint: "login",
                body: loginData,
                responseType: LoginResponse.self
            )
            
            print("🚀 API Response received successfully")
            print("🚀 =====================================")
            
            print("========== LOGIN SUCCESS ==========")
            print("📧 Email: \(response.email)")
            print("🎭 Role: \(response.role)")
            print("🆔 User ID: \(response.id)")
            print("🔑 Access Token (first 30 chars): \(String(response.access_token.prefix(30)))...")
            print("🔄 Refresh Token present: \(!response.refresh_token.isEmpty)")
            
            // ✅ CRITICAL: Save user data and tokens to TokenManager
            TokenManager.shared.saveUserData(
                accessToken: response.access_token,
                refreshToken: response.refresh_token,
                userId: response.id,
                role: response.role,
                name: response.email.components(separatedBy: "@").first ?? "User", // Utiliser le nom de l'email si pas de nom
                email: response.email
            )
            
            print("✅ User data saved to TokenManager")
            print("====================================")
            
            // Verify the token was saved
            TokenManager.shared.debugPrintAll()
            
            isLoggedIn = true
            userRole = response.role
            
            // Save user session for use across the app
            UserSession.shared.saveSession(
                userId: response.id,
                email: response.email,
                role: response.role
            )

            // Trigger navigation based on role
            if let resolvedRole = userRole {
                onSuccess?(resolvedRole)
            }

        } catch {
            print("❌ ========== LOGIN ERROR ==========")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
            print("❌ ==================================")
            handleAuthError(error)
        }

        isLoading = false
    }

    // MARK: - Logout
    func logout() {
        print("🔓 Logging out user...")
        TokenManager.shared.clearAllData()
        isLoggedIn = false
        userRole = nil
        email = ""
        password = ""
        fullName = ""
        licenseNumber = ""
        print("✅ User logged out successfully")
    }

    // MARK: - Check Login Status
    func checkLoginStatus() {
        isLoggedIn = TokenManager.shared.isLoggedIn()
        if isLoggedIn {
            if let roleString = TokenManager.shared.getUserRole() {
                userRole = AppUserRole(rawValue: roleString)
            }
            email = TokenManager.shared.getUserEmail() ?? ""
            print("✅ User is logged in - Role: \(userRole?.rawValue ?? "unknown")")
        } else {
            print("❌ User is not logged in")
        }
    }

    // MARK: - User Signup
    func signup(userData: SignupRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: SignupResponse = try await AuthAPI.shared.post(
                endpoint: "signup/user",
                body: userData,
                responseType: SignupResponse.self
            )
            print("✅ Signup successful: \(response.message)")
        } catch {
            handleAuthError(error)
        }
        isLoading = false
    }

    // MARK: - Professional Signup
    func signupProfessional(proData: ProfessionalSignupRequest) async {
        isLoading = true
        errorMessage = nil
        do {
            _ = try await AuthAPI.shared.post(
                endpoint: "signup/professional",
                body: proData,
                responseType: SignupProResponse.self
            )
            print("✅ Professional signup successful")
        } catch {
            handleAuthError(error)
        }
        isLoading = false
    }

    // MARK: - Helper: Clean Server Error Messages
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthError {
            switch authError {
            case .serverError(let rawMessage):
                self.errorMessage = extractMessage(from: rawMessage) ?? "Request failed."
            default:
                self.errorMessage = authError.localizedDescription
            }
        } else {
            self.errorMessage = error.localizedDescription
        }
    }

    private func extractMessage(from rawJsonString: String) -> String? {
        let cleanedString = rawJsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\\"", with: "\"")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        guard let data = cleanedString.data(using: .utf8) else { return nil }

        struct ServerErrorBody: Decodable {
            let message: String?
        }

        return (try? JSONDecoder().decode(ServerErrorBody.self, from: data))?.message
    }
}
