import SwiftUI

struct ProSignupView: View {
    var onFinish: (() -> Void)? = nil

    // MARK: - StateObject for API calls
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Logo Circle
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.4), Color.yellow]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(Color.brown)
                }
                .padding(.top, 48)

                // MARK: - Title
                VStack(spacing: 8) {
                    Text("Professional Signup")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.72, green: 0.45, blue: 0.0)) // #B87300

                    Text("Register your restaurant business to get started.")
                        .font(.body)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                }

                // MARK: - Form Fields
                Group {
                    ProTextField(icon: "person.fill", placeholder: "Full Name / Business Contact", text: $viewModel.fullName)
                    ProTextField(icon: "building.2.fill", placeholder: "Restaurant License Number (Optional)", text: $viewModel.licenseNumber)
                    ProTextField(icon: "envelope.fill", placeholder: "Email Address", text: $viewModel.email, keyboardType: .emailAddress)
                    ProSecureField(icon: "lock.fill", placeholder: "Password", text: $viewModel.password, showPassword: $showPassword)
                }

                // MARK: - Register Button
                Button(action: registerAction) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.yellow.opacity(0.9), Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 56)

                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.black))
                        } else {
                            Text("Register Professional Account")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .disabled(viewModel.isLoading)

                // MARK: - Error Message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.body)
                        .padding(.top, 8)
                }

                Spacer(minLength: 48)
            }
            .padding(.horizontal, 24)
            .background(Color.white)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Signup Action
    private func registerAction() {
        viewModel.isLoading = true
        viewModel.errorMessage = nil

        // Prepare DTO
        let proData = ProfessionalSignupRequest(
            email: viewModel.email,
            password: viewModel.password,
            fullName: viewModel.fullName,
            licenseNumber: viewModel.licenseNumber.isEmpty ? nil : viewModel.licenseNumber
        )

        // Call API asynchronously
        Task {
            await viewModel.signupProfessional(proData: proData)

            // After successful signup, navigate to login
            if viewModel.errorMessage == nil {
                onFinish?() // Trigger navigation back to login
            }
        }
    }
}

// MARK: - Custom TextField Views
struct ProTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(white: 0.96))
        .cornerRadius(16)
    }
}

struct ProSecureField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            if showPassword {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }

            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(white: 0.96))
        .cornerRadius(16)
    }
}

#Preview("Pro Signup View") {
    ProSignupView()
}
