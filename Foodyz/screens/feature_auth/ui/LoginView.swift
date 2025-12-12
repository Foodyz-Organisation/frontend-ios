import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showError = false
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false

    // Navigation closures
    var onSignup: (() -> Void)? = nil
    // This closure will be called when login is successful
    var onLoginSuccess: (AppUserRole) -> Void

    var body: some View {
    var onForgotPassword: (() -> Void)? = nil  // Add this line
    var onLoginSuccess: (UserRole) -> Void

    enum UserRole {
        case user, professional
    }

    var body: some View {
        let gradient = LinearGradient(
            colors: [Color(hex: 0xFFFBEA), Color(hex: 0xFFF8D6), Color(hex: 0xFFF6C1)],
            startPoint: .top,
            endPoint: .bottom
        )

        ScrollView {
            VStack(spacing: 20) {
                // Spacer to push content down
                Spacer()
                    .frame(height: 60)
                
                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFFD54F), Color(hex: 0xFFA726)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: "fork.knife")
                        .font(.system(size: 45))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 20)
                
                // Welcome Text
                Text("Welcome Back")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color(hex: 0xD97706))
                
                Text("Login to continue your food journey")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // Email Field
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    .foregroundColor(Color(hex: 0x6B7280))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)

                // MARK: Email
                CustomTextField(icon: "envelope.fill",
                                 placeholder: "Email",
                                 text: $viewModel.email)

                // MARK: Password
                CustomSecureField(icon: "lock.fill",
                                 placeholder: "Password",
                                 text: $viewModel.password,
                                 showPassword: $showPassword)

                // MARK: Forgot Password
                HStack {
                    Spacer()
                    Button(action: { onForgotPassword?() }) {
                        Text("Forgot Password?")
                            .foregroundColor(Color(hex: 0xF59E0B))
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .padding(.top, 4)

                // MARK: Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.body)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color(hex: 0xF3F4F6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                // Password Field
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .frame(width: 24)
                    
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(hex: 0xF3F4F6))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                // Remember Me & Forgot Password
                HStack {
                    Button(action: {
                        rememberMe.toggle()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                .foregroundColor(rememberMe ? Color(hex: 0xD97706) : .gray)
                            Text("Remember Me")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Text("Forgot Password?")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: 0xD97706))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 5)
                
                // Login Button
                Button(action: loginAction) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Login")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xFFC107), Color(hex: 0xFFB300)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.top, 10)
                .disabled(viewModel.isLoading)
                
                // Or continue with
                Text("Or continue with")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 10)
                
                // Social Login Buttons
                HStack(spacing: 15) {
                    // Google Button
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .foregroundColor(Color(hex: 0x4285F4))
                            Text("Google")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    
                    // Facebook Button
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "globe")
                                .foregroundColor(Color(hex: 0x1877F2))
                            Text("Facebook")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                
                // Register Section
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Button(action: {
                        onSignup?()
                    }) {
                        Text("Register Now")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: 0xD97706))
                    }
                }
                .padding(.top, 15)
                
                Text("Create an account to be able to order/reserve/get a delivery")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .background(Color.white)
        .navigationBarBackButtonHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func loginAction() {
        Task {
            // Update viewModel's email and password from local state variables
            viewModel.email = email
            viewModel.password = password
            await viewModel.login { role in
                let userRole: UserRole
                switch role {
                case "professional":
                    userRole = .professional
                default:
                    userRole = .user
                }
                onLoginSuccess(userRole)
            }
        }
    }
}

// NOTE: Ensure this struct is available in your project
struct SocialButton: View {
    let iconName: String
    let text: String
    
    var body: some View {
        HStack {
            // Placeholder for Google/Facebook icons (replace with actual Image("iconName"))
            Image(systemName: "globe")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(.textPrimary)
            
            Text(text)
                .foregroundColor(.textPrimary)
                .fontWeight(.medium)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.gray100)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.gray300, lineWidth: 0.5)
        )
    }
}
