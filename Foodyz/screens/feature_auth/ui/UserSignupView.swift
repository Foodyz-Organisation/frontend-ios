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

                // MARK: Avatar Picker
                PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                    HStack(spacing: 16) {
                        ZStack {
                            if let avatarPreview {
                                Image(uiImage: avatarPreview)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(Color(hex: 0x6B7280))
                            }
                        }
                        .frame(width: 64, height: 64)
                        .background(Color(hex: 0xF3F4F6))
                        .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add profile photo")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: 0x111827))
                            Text("Optional, but it helps professionals recognize you.")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }

                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(18)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                }
                .onChange(of: avatarItem) { newValue in
                    Task { await updateAvatarSelection(with: newValue) }
                }

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

        let dataURI = avatarUploadData?.dataURI()

        let signupData = SignupRequest(
            username: fullName,
            email: viewModel.email,
            password: viewModel.password,
            phone: phone.isEmpty ? nil : phone,
            address: address.isEmpty ? nil : address,
            avatarUrl: dataURI
        )

        Task {
            await viewModel.signup(userData: signupData)
            if viewModel.errorMessage == nil {
                onFinishSignup?()
            }
        }
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
