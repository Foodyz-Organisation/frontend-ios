import SwiftUI

struct UserSignupView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var fullName = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var address = ""

    var onFinishSignup: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Create Your Account")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: 0x6B7280))
                    
                    Text("Sign up to start your foodie journey")
                        .font(.body)
                        .foregroundColor(Color(hex: 0x6B7280))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                // MARK: Full Name
                CustomTextField(icon: "person.fill",
                                placeholder: "Full Name",
                                text: $fullName)

                // MARK: Email
                CustomTextField(icon: "envelope.fill",
                                placeholder: "Email Address",
                                text: $viewModel.email,
                                keyboardType: .emailAddress)

                // MARK: Passwords
                CustomSecureField(icon: "lock.fill",
                                  placeholder: "Password",
                                  text: $viewModel.password,
                                  showPassword: $showPassword)

                CustomSecureField(icon: "lock.fill",
                                  placeholder: "Confirm Password",
                                  text: $confirmPassword,
                                  showPassword: $showConfirmPassword)

                // MARK: Optional Contact Info
                CustomTextField(icon: "phone.fill",
                                placeholder: "Phone Number",
                                text: $phone)
                CustomTextField(icon: "house.fill",
                                placeholder: "Address",
                                text: $address)

                // MARK: Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                // MARK: Signup Button
                Button(action: signupAction) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(colors: [Color(hex: 0xFFE15A), Color(hex: 0xF59E0B)],
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                            .frame(height: 56)

                        if viewModel.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Create Account")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(viewModel.isLoading)
                .padding(.top, 20)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: Signup Action
    private func signupAction() {
        viewModel.errorMessage = nil

        guard !fullName.isEmpty,
              !viewModel.email.isEmpty,
              !viewModel.password.isEmpty else {
            viewModel.errorMessage = "Please fill all required fields."
            return
        }

        guard viewModel.password == confirmPassword else {
            viewModel.errorMessage = "Passwords do not match."
            return
        }

        let signupData = SignupRequest(
            username: fullName,
            email: viewModel.email,
            password: viewModel.password,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address
        )

        Task {
            await viewModel.signup(userData: signupData)
            if viewModel.errorMessage == nil {
                onFinishSignup?()
            }
        }
    }
}
