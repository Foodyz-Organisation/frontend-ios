import SwiftUI

struct UserSignupView: View {
    @StateObject private var viewModel = AuthViewModel()
    
    // View States
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var fullName = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var address = ""

    // Completion Handler (for navigation back to Login screen)
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

                // MARK: Input Fields
                CustomTextField(icon: "person.fill",
                                 placeholder: "Full Name",
                                 text: $fullName)

                CustomTextField(icon: "envelope.fill",
                                 placeholder: "Email Address",
                                 text: $viewModel.email,
                                 keyboardType: .emailAddress)

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

        // Trim input
        let cleanFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Validate required fields
        guard !cleanFullName.isEmpty,
              !cleanEmail.isEmpty,
              !cleanPassword.isEmpty else {
            viewModel.errorMessage = "Please fill all required fields."
            return
        }

        // 2. Validate password match
        guard cleanPassword == cleanConfirmPassword else {
            viewModel.errorMessage = "Passwords do not match."
            return
        }

        // 3. Prepare payload for backend (use optional types for phone/address if empty)
        let signupData = SignupRequest(
            username: cleanFullName,
            email: cleanEmail,
            password: cleanPassword,
            // Use nil for optional fields if the trimmed string is empty
            phone: cleanPhone.isEmpty ? nil : cleanPhone,
            address: cleanAddress.isEmpty ? nil : cleanAddress
        )

        print("Signup payload:", signupData)

        // 4. Call ViewModel function
        Task {
            // Your actual ViewModel logic (using AuthAPI) will run here
            await viewModel.signup(userData: signupData)
            
            // 5. Navigate on success
            if viewModel.errorMessage == nil {
                onFinishSignup?()
            }
        }
    }
}
