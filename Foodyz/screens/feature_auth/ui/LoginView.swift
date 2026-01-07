import SwiftUI
import UIKit

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showError = false
    @State private var showDiagnostics = false
    @State private var diagnosticsMessage = ""
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false

    // Navigation closures
    var onSignup: (() -> Void)? = nil
    var onForgotPassword: (() -> Void)? = nil
    // This closure will be called when login is successful
    var onLoginSuccess: (AppUserRole) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Background Color
            Color(hex: 0xFFFBEA) // Cream background for the top part
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Illustration Section
                VStack {
                    Spacer()
                    Image("auth_login_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 250) // Increased height to match "full screen" feel in top section
                    Spacer()
                }
                .frame(height: UIScreen.main.bounds.height * 0.38)
                .frame(maxWidth: .infinity)
                
                // MARK: - Bottom Content Section (White Container)
                ZStack {
                    Color.white
                        .clipShape(RoundedCorner(radius: 30, corners: [.topLeft, .topRight]))
                        .ignoresSafeArea(edges: .bottom)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 25) {
                            // Handle bar indicator
                            Capsule()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 4)
                                .padding(.top, 15)
                            
                            // Text Header
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(hex: 0xB45309)) // Brownish gold
                                
                                Text("Login to continue your food journey")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 5)
                            
                            // Form Fields
                            VStack(spacing: 20) {
                                // Email Field
                                CustomTextField(
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $viewModel.email,
                                    iconColor: Color(hex: 0xF97316) // Orange
                                )
                                
                                // Password Field
                                CustomSecureField(
                                    icon: "lock.fill",
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    showPassword: $showPassword,
                                    iconColor: Color(hex: 0xFAB005) // Yellow
                                )
                                
                                // Remember Me & Forgot Password
                                HStack {
                                    Button(action: { rememberMe.toggle() }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                                .foregroundColor(rememberMe ? Color(hex: 0xF59E0B) : .gray)
                                            Text("Remember Me")
                                                .font(.system(size: 14))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { onForgotPassword?() }) {
                                        Text("Forgot Password?")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(hex: 0xB45309))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Login Button
                            Button(action: loginAction) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(colors: [Color(hex: 0xFFD43B), Color(hex: 0xFAB005)],
                                               startPoint: .top,
                                               endPoint: .bottom)
                            )
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .shadow(color: Color(hex: 0xFAB005).opacity(0.3), radius: 10, x: 0, y: 5)
                            .disabled(viewModel.isLoading)
                            
                            // Or continue with
                            HStack {
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                Text("Or continue with")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                            }
                            .padding(.horizontal, 24)
                            
                            // Social Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await viewModel.googleLogin { role in
                                            onLoginSuccess(role)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        if UIImage(named: "google_icon") != nil {
                                            Image("google_icon")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                        } else {
                                            Image(systemName: "g.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("Google")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.black.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Register
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Button(action: { onSignup?() }) {
                                    Text("Register Now")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hex: 0xF59E0B))
                                }
                            }
                            .padding(.bottom, 30)
                            
                        } // End VStack (Scroll Content)
                    } // End ScrollView
                } // End ZStack (White Container)
            } // End Main VStack
        } // End Root ZStack

        .ignoresSafeArea(.keyboard, edges: .bottom) // Prevent keyboard from pushing everything up awkwardly
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
            Button("Diagnose Connection") {
                diagnoseConnection()
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.errorMessage ?? "")
                if let error = viewModel.errorMessage, error.contains("offline") || error.contains("Local network") {
                    Text("\n💡 Tap 'Diagnose Connection' to check network settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .alert("Network Diagnostics", isPresented: $showDiagnostics) {
            Button("OK", role: .cancel) {}
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(diagnosticsMessage)
        }
    }
    
    // ... (loginAction implementation)
    private func loginAction() {
        // 🔍 DEBUG: Log current state before login
        print("🔍 ========== LOGIN DEBUG ==========")
        print("🔍 Email: '\(viewModel.email)'")
        print("🔍 Password length: \(viewModel.password.count)")
            
        Task {
            await viewModel.login { role in
                onLoginSuccess(role)
            }
        }
    }
    
    private func diagnoseConnection() {
        print("🔍 [LoginView] Starting network diagnostics...")
        
        // Get diagnostics info
        let info = NetworkDiagnostics.shared.getDiagnosticsInfo()
        print(info)
        
        // Test connection
        NetworkDiagnostics.shared.testServerConnection { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let diagnostic):
                    print(diagnostic.summary)
                    self.diagnosticsMessage = diagnostic.summary
                    
                    if diagnostic.isLocalNetworkBlocked {
                        self.diagnosticsMessage += "\n\n⚠️ LOCAL NETWORK PERMISSION REQUIRED\n\n"
                        self.diagnosticsMessage += "To fix this:\n"
                        self.diagnosticsMessage += "1. Open Settings app\n"
                        self.diagnosticsMessage += "2. Go to Privacy & Security\n"
                        self.diagnosticsMessage += "3. Tap Local Network\n"
                        self.diagnosticsMessage += "4. Find 'Foodyz' and toggle it ON\n"
                        self.diagnosticsMessage += "\nOr tap 'Open Settings' below."
                    } else if !diagnostic.success {
                        self.diagnosticsMessage += "\n\n⚠️ SERVER CONNECTION ISSUE\n\n"
                        self.diagnosticsMessage += "Please check:\n"
                        self.diagnosticsMessage += "1. Backend server is running on port 3000\n"
                        self.diagnosticsMessage += "2. Mac IP address is correct: \(BaseUrlProvider.shared.baseURL)\n"
                        self.diagnosticsMessage += "3. iPhone and Mac are on the same Wi-Fi network\n"
                    }
                    
                case .failure(let error):
                    print("❌ Diagnostic failed: \(error.localizedDescription)")
                    self.diagnosticsMessage = "❌ Diagnostic Error: \(error.localizedDescription)\n\n"
                    self.diagnosticsMessage += "Base URL: \(BaseUrlProvider.shared.baseURL)\n"
                    self.diagnosticsMessage += "\nPlease check:\n"
                    self.diagnosticsMessage += "1. Enable Local Network permission in Settings\n"
                    self.diagnosticsMessage += "2. Verify server is running\n"
                    self.diagnosticsMessage += "3. Check IP address is correct"
                }
                
                self.showDiagnostics = true
            }
        }
    }
}

// MARK: - Helper Views

struct SocialLoginButton: View {
    let imageName: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Determine if we use system image or asset
                if UIImage(named: imageName) != nil {
                     Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    // Fallback to stylized G text or globe
                    Image(systemName: "globe")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color(hex: 0xEA4335)) // Google Red-ish
                }
                
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}


