import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showError = false

    // Navigation closures
    var onSignup: (() -> Void)? = nil
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
                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(Color(hex: 0x5F370E))
                }
                .padding(.top, 60)

                // MARK: Title
                Text("Welcome Back")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(hex: 0xB87300))

                Text("Login to continue your food journey")
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
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                }
                .padding(.vertical, 16)
                .disabled(viewModel.isLoading)

                // MARK: Signup Link
                HStack {
                    Text("Don't have an account? ")
                        .foregroundColor(Color(hex: 0x6B7280))
                    Button(action: { onSignup?() }) {
                        Text("Register Now")
                            .foregroundColor(Color(hex: 0xF59E0B))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .background(gradient.ignoresSafeArea())
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: Login Action
    private func loginAction() {
        Task {
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
