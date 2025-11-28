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
    @Published var userRole: String? = nil

    // MARK: - Login
    func login(onSuccess: ((String, String, String) -> Void)? = nil) async {
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
            isLoggedIn = true
            userRole = response.role

            // ✅ FIX: Pass role, ID, and access_token to the closure
            onSuccess?(response.role, response.id, response.access_token)

        } catch {
            handleAuthError(error)
        }

        isLoading = false
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
            print("Signup successful: \(response.message)")
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
            let response: SignupProResponse = try await AuthAPI.shared.post(
                endpoint: "signup/professional",
                body: proData,
                responseType: SignupProResponse.self
            )
            print("Professional signup successful")
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
