import SwiftUI
import Combine
import UIKit // Added for UIImage

@MainActor
class AuthViewModel: ObservableObject, Hashable {
    static func == (lhs: AuthViewModel, rhs: AuthViewModel) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
    
    // MARK: - Published properties
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    @Published var phone = ""
    @Published var address = ""
    @Published var licenseNumber = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isLoggedIn = false
    @Published var userRole: AppUserRole? = nil

    // MARK: - Pro Wizard State
    @Published var currentStep: Int = 1
    @Published var permitImage: UIImage? = nil
    @Published var permitImageBase64: String? = nil
    @Published var isCompressingImage: Bool = false
    @Published var permitFileName: String? = nil
    @Published var permitFileSize: String? = nil
    @Published var permitNumberExtracted: String? = nil
    @Published var showSuccessDialog: Bool = false
    @Published var selectedLocation: LocationDto? = nil

    private let session = SessionManager.shared

    // MARK: - Login
    // MARK: - Google Login
    func googleLogin(onSuccess: ((AppUserRole) -> Void)? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔍 ========== GOOGLE LOGIN START ==========")
            
            // 1. Get ID Token from Google
            let idToken = try await GoogleSignInManager.shared.signIn()
            print("✅ ID Token received from Google")
            
            // 2. Send to Backend
            print("🚀 Sending ID Token to backend...")
            let response = try await AuthAPI.shared.googleLogin(idToken: idToken)
            
            print("✅ Backend Google Login successful")
            print("📧 Email: \(response.email)")
            print("🎭 Role: \(response.role)")
            
            // 3. Save Session Data
            TokenManager.shared.saveUserData(
                accessToken: response.access_token,
                refreshToken: response.refresh_token,
                userId: response.id,
                role: response.role,
                name: response.email.components(separatedBy: "@").first ?? "User",
                email: response.email
            )
            
            // 4. Update Chat Session
            await MainActor.run {
                SessionManager.shared.update(with: response)
            }
            
            // 5. Update Local State
            isLoggedIn = true
            userRole = AppUserRole(rawValue: response.role)
            UserSession.shared.saveSession(
                userId: response.id,
                email: response.email,
                role: response.role
            )
            
            // 6. Sync FCM token with backend after successful login
            FirebaseNotificationManager.shared.getFCMToken { token in
                if let token = token {
                    FirebaseNotificationManager.shared.syncTokenWithBackend(token: token)
                }
            }
            
            // 7. Navigation
            if let resolvedRole = userRole {
                onSuccess?(resolvedRole)
            }
            
        } catch {
            print("❌ Google Login Failed: \(error.localizedDescription)")
            handleAuthError(error)
        }
        
        isLoading = false
    }

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
            
            // ✅ Also update SessionManager for chat functionality
            await MainActor.run {
                SessionManager.shared.update(with: response)
                print("✅ SessionManager updated - userId: \(SessionManager.shared.userId ?? "nil")")
            }
            print("✅ SessionManager updated for chat")
            
            // Verify the token was saved
            TokenManager.shared.debugPrintAll()
            
            isLoggedIn = true
            userRole = AppUserRole(rawValue: response.role)
            
            // Save user session for use across the app
            UserSession.shared.saveSession(
                userId: response.id,
                email: response.email,
                role: response.role
            )
            
            // Sync FCM token with backend after successful login
            FirebaseNotificationManager.shared.getFCMToken { token in
                if let token = token {
                    FirebaseNotificationManager.shared.syncTokenWithBackend(token: token)
                }
            }

            // Small delay to ensure all updates are complete
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Trigger navigation based on role - ensure on main thread
            await MainActor.run {
                if let resolvedRole = userRole {
                    print("🚀 [AuthViewModel] Calling onSuccess with role: \(resolvedRole)")
                    onSuccess?(resolvedRole)
                } else {
                    print("⚠️ [AuthViewModel] userRole is nil, cannot navigate")
                }
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
        
        // Also clear SessionManager for chat functionality
        Task { @MainActor in
            SessionManager.shared.clear()
        }
        
        isLoggedIn = false
        userRole = nil
        email = ""
        password = ""
        fullName = ""
        phone = ""
        address = ""
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

    // MARK: - Image Processing
    func convertImageToBase64(_ image: UIImage, fileName: String? = nil) {
        isCompressingImage = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                print("📸 Image selected: \(fileName ?? "unknown")")
                
                // Store original file name
                DispatchQueue.main.async {
                    self?.permitFileName = fileName
                }
                
                // Compress image using ImageCompressor
                let compressedBase64 = try ImageCompressor.compressImageToBase64(image)
                
                // Calculate compressed size
                let base64String = compressedBase64.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                if let data = Data(base64Encoded: base64String) {
                    let sizeKB = data.count / 1024
                    let formattedSize = self?.formatFileSize(sizeKB * 1024) ?? "\(sizeKB) KB"
                    
                    DispatchQueue.main.async {
                        self?.permitImageBase64 = compressedBase64
                        self?.permitImage = image
                        self?.permitFileSize = formattedSize
                        self?.isCompressingImage = false
                        print("✅ Image compressed and ready! Size: \(formattedSize)")
                    }
                } else {
                    // If base64 decoding fails, still set the image but warn
                    DispatchQueue.main.async {
                        self?.permitImageBase64 = compressedBase64
                        self?.permitImage = image
                        self?.permitFileSize = "Unknown size"
                        self?.isCompressingImage = false
                        print("⚠️ Compression complete but size calculation failed")
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.errorMessage = "Failed to process image. Please try another photo."
                    self?.isCompressingImage = false // CRITICAL: Always clear loading state
                    self?.clearPermitImage()
                    print("❌ Image compression failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func clearPermitImage() {
        permitImage = nil
        permitImageBase64 = nil
        permitFileName = nil
        permitFileSize = nil
        isCompressingImage = false
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let kb = Double(size) / 1024.0
        let mb = kb / 1024.0
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else if kb >= 1.0 {
            return String(format: "%.2f KB", kb)
        } else {
            return "\(size) B"
        }
    }
    
    // MARK: - Professional Signup
    func signupProfessional(proData: ProfessionalSignupRequest) async {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Convert image to Base64 if needed
        var finalProData = proData
        
        // If we have a permit image base64 in the ViewModel but not in the DTO yet (wizard flow), add it
        if let base64Image = permitImageBase64, finalProData.licenseImage == nil {
            finalProData = ProfessionalSignupRequest(
                email: finalProData.email,
                password: finalProData.password,
                fullName: finalProData.fullName,
                licenseNumber: finalProData.licenseNumber,
                licenseImage: base64Image,
                licenseImageUrl: nil,
                linkedUserId: finalProData.linkedUserId,
                locations: selectedLocation != nil ? [selectedLocation!] : nil
            )
        }
        
        do {
            print("📤 Sending signup request to backend...")
            let response = try await AuthAPI.shared.professionalSignup(request: finalProData)
            print("✅ Signup response received!")
            
            await MainActor.run {
                permitNumberExtracted = response.permitNumber
                isLoading = false
                showSuccessDialog = true
                
                // Reset wizard state on success
                self.currentStep = 1
                self.permitImage = nil
                self.permitImageBase64 = nil
                self.selectedLocation = nil
            }
            
        } catch {
            await MainActor.run {
                let errorMsg = error.localizedDescription
                print("❌ Professional signup failed: \(errorMsg)")
                
                // Check if it's a permit validation error
                let isPermitValidationError = errorMsg.localizedCaseInsensitiveContains("tunisian restaurant") ||
                                             errorMsg.localizedCaseInsensitiveContains("extract permit number") ||
                                             errorMsg.localizedCaseInsensitiveContains("permit") ||
                                             errorMsg.localizedCaseInsensitiveContains("validation") ||
                                             errorMsg.localizedCaseInsensitiveContains("Image quality too low") ||
                                             errorMsg.localizedCaseInsensitiveContains("no readable text") ||
                                             errorMsg.localizedCaseInsensitiveContains("clearer photo")
                
                if isPermitValidationError {
                    errorMessage = "We were not able to validate the document provided, please provide another one"
                    clearPermitImage()
                    currentStep = 2 // Go back to step 2
                } else if errorMsg.localizedCaseInsensitiveContains("email") ||
                          errorMsg.localizedCaseInsensitiveContains("mail") {
                    errorMessage = "This mail already exist"
                    currentStep = 1 // Go back to step 1
                } else {
                    handleAuthError(error)
                }
                
                isLoading = false
            }
        }
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
