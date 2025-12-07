import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showError = false

    // Remove onLogin: (() -> Void)? = nil as it seems redundant with onLoginSuccess
    var onSignup: (() -> Void)? = nil
    // This closure will be called when login is successful
    var onLoginSuccess: (AppUserRole) -> Void

    var body: some View {
        // ... (Body content remains the same)

        let gradient = LinearGradient(
            colors: [Color(hex: 0xFFFBEA), Color(hex: 0xFFF8D6), Color(hex: 0xFFF6C1)],
            startPoint: .top,
            endPoint: .bottom
        )

        ScrollView {
            VStack(spacing: 16) {
                // MARK: Logo
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [Color(hex: 0xFFECB3), Color(hex: 0xFFC107)]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        ))
                        .frame(width: 120, height: 120)
                        .shadow(radius: 5, y: 5)
                        
                    Image(systemName: "fork.knife")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(Color.textLight)
                }
                // FIX: Reduce large top padding to prevent content from being pushed off-screen
                // The large padding was causing content to hide behind the navigation bar.
                .padding(.top, 20)

                // Title
                Text("Welcome Back")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color.secondaryColor)
                
                Text("Login to continue your food journey")
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)

                // Email - Assuming CustomTextField and CustomSecureField exist elsewhere
                CustomTextField(icon: "envelope.fill",
                                placeholder: "your.email@example.com",
                                text: $viewModel.email)
                
                // Password
                CustomSecureField(icon: "lock.fill",
                                  placeholder: "Enter your password",
                                  text: $viewModel.password,
                                  showPassword: $showPassword)
                
                // Forgot Password Link
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Action for Forgot Password
                    }
                    .foregroundColor(Color.secondaryColor)
                    .font(.caption)
                }

                // Error
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(Color.error)
                        .font(.body)
                        .padding(.top, 4)
                }

                // MARK: Login Button
                Button(action: loginAction) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(LinearGradient(
                                colors: [Color(hex: 0xFFE15A), Color(hex: 0xF59E0B)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 56)

                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Login")
                                .foregroundColor(Color.textLight)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
                .padding(.vertical, 16)
                .disabled(viewModel.isLoading)
                
                // Separator Text
                Text("Or continue with")
                    .foregroundColor(Color.textSecondary)
                    .padding(.bottom, 8)

                // Social Buttons (Placeholder Structure)
                HStack(spacing: 20) {
                    SocialButton(iconName: "google", text: "Google")
                    SocialButton(iconName: "facebook", text: "Facebook")
                }
                
                Spacer()

                // Signup Link
                VStack(spacing: 8) {
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(Color.textSecondary)
                        Button(action: { onSignup?() }) {
                            Text("Register Now")
                                .foregroundColor(Color.primaryColor)
                                .fontWeight(.semibold)
                        }
                    }
                    Text("Create an account to be able to order/reserve/get a delivery")
                        .foregroundColor(Color.textSecondary)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        // CRITICAL FIX: Ignore the top safe area to pull content up under the navigation bar
        .ignoresSafeArea(.container, edges: .top)
        .background(backgroundGradient.ignoresSafeArea())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { // <-- CORRECT: Use the 'message:' label here.
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private func loginAction() {
        Task {
            await viewModel.login { role, id, token in
                let userRole: UserRole = role == "professional" ? .professional : .user
                onLoginSuccess(userRole, id, token)
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
