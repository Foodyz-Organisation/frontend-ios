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

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            errorMessage = "Please enter both email and password."
            isLoading = false
            return
        }

        do {
            let loginData = LoginRequest(email: cleanEmail, password: cleanPassword)
            let response: LoginResponse = try await AuthAPI.shared.post(
                endpoint: "login",
                body: loginData,
                responseType: LoginResponse.self
            )
            
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
            userRole = AppUserRole(rawValue: response.role) ?? .user
            session.update(with: response)

            // Trigger navigation based on role
            if let resolvedRole = userRole {
                onSuccess?(resolvedRole)
            }

        } catch {
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
            userRole = TokenManager.shared.getUserRole()
            email = TokenManager.shared.getUserEmail() ?? ""
            print("✅ User is logged in - Role: \(userRole ?? "unknown")")
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
