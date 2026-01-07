import SwiftUI
import PhotosUI
import UIKit

struct UserSignupView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var fullName = ""
    @State private var confirmPassword = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarPreview: UIImage?
    @State private var avatarUploadData: Data?

    var onNext: ((AuthViewModel) -> Void)? = nil
    var onFinishSignup: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .top) {
            // MARK: - Top Background Color
            Color(hex: 0xFFFBEA)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Illustration Section
                VStack {
                    Spacer()
                    Image("auth_signup_illustration")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                    Spacer()
                }
                .frame(height: UIScreen.main.bounds.height * 0.32)
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
                                Text("Create Account")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(hex: 0x1E293B)) // Dark slate
                                
                                Text("Enter your personal details")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 5)
                            
                            // Form Fields
                            VStack(spacing: 16) {
                                // Full Name
                                CustomTextField(
                                    icon: "person.fill",
                                    placeholder: "Full Name",
                                    text: $fullName,
                                    iconColor: Color(hex: 0xFAB005) // Yellow
                                )
                                
                                // Email
                                CustomTextField(
                                    icon: "envelope.fill",
                                    placeholder: "Email",
                                    text: $viewModel.email,
                                    keyboardType: .emailAddress,
                                    iconColor: Color(hex: 0xFAB005)
                                )
                                
                                // Password
                                CustomSecureField(
                                    icon: "lock.fill",
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    showPassword: $showPassword,
                                    iconColor: Color(hex: 0xFAB005)
                                )
                                
                                // Confirm Password
                                CustomSecureField(
                                    icon: "lock.fill",
                                    placeholder: "Confirm Password",
                                    text: $confirmPassword,
                                    showPassword: $showConfirmPassword,
                                    iconColor: Color(hex: 0xFAB005)
                                )
                            }
                            .padding(.horizontal, 24)
                            
                            // Error Message
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            // Next (Signup) Button
                            Button(action: signupAction) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Next")
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
                            
                            // Or divider
                            HStack {
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                                Text("or")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                                Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 1)
                            }
                            .padding(.horizontal, 24)
                            
                            // Already have an account?
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Button(action: {
                                    onFinishSignup?()
                                }) {
                                    Text("Login")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color(hex: 0xF59E0B))
                                }
                            }
                            .padding(.bottom, 40)
                            
                        } // End VStack (Scroll Content)
                    } // End ScrollView
                } // End ZStack (White Container)
            } // End Main VStack
        } // End Root ZStack
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)

    }

    // MARK: Signup Action
    private func signupAction() {
        viewModel.errorMessage = nil

        // Trim input
        let cleanFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = viewModel.password.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanConfirmPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Validate required fields
        guard !cleanFullName.isEmpty,
              !cleanEmail.isEmpty,
              !cleanPassword.isEmpty else {
            viewModel.errorMessage = "Please fill all required fields."
            return
        }

        guard viewModel.password == confirmPassword else {
            viewModel.errorMessage = "Passwords do not match."
            return
        }
        
        // Update viewModel state before navigating
        viewModel.fullName = cleanFullName
        
        // Navigate to next step
        onNext?(viewModel)
    }
}

// MARK: - Avatar Helpers
private extension UserSignupView {
    func updateAvatarSelection(with item: PhotosPickerItem?) async {
        guard let item else {
            await MainActor.run {
                avatarPreview = nil
                avatarUploadData = nil
            }
            return
        }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let compressed = image.jpegData(compressionQuality: 0.85) ?? data
                await MainActor.run {
                    avatarPreview = image
                    avatarUploadData = compressed
                }
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Unable to load selected image."
            }
        }
    }
}
