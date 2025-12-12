import SwiftUI
import PhotosUI
import UIKit
import Combine

@MainActor
struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
    @State private var avatarItem: PhotosPickerItem?
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                if let profile = viewModel.profile {
                    profileInfoCard(profile)
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("We could not load your profile yet.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.loadProfile(force: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .task {
            await viewModel.loadProfile(force: false)
        }
        .onChange(of: avatarItem) { _, newItem in
            Task { await processAvatarSelection(newItem) }
        }
        .overlay(alignment: .center) {
            if viewModel.isUpdatingAvatar {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    ProgressView("Updating avatar…")
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                }
            }
        }
        .alert("Profile Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var profileHeader: some View {
        let profile = viewModel.profile
        let fallbackName = profile?.username ?? (session.displayName ?? "Foodies Member")
        let fallbackEmail = profile?.email ?? session.email
        let avatarURL = profile?.avatarUrl ?? session.avatarURL

        return VStack(spacing: 16) {
            PhotosPicker(selection: $avatarItem, matching: .images, photoLibrary: .shared()) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        avatarURL: avatarURL,
                        size: 120,
                        fallback: fallbackName
                    )
                        .overlay(Circle().stroke(AppColors.primary, lineWidth: 2))

                    Image(systemName: "camera.fill")
                        .font(.caption)
                        .padding(8)
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .offset(x: -6, y: -6)
                }
            }
            .buttonStyle(.plain)

            Text(fallbackName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.darkGray)

            if let email = fallbackEmail {
                Text(email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColors.white)
        .cornerRadius(32)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 8)
    }

    private func profileInfoCard(_ profile: UserProfileDTO) -> some View {
        VStack(spacing: 16) {
            ProfileFieldRow(label: "Phone", value: profile.phone ?? "Add your phone")
            ProfileFieldRow(label: "Address", value: profile.address ?? "Add your address")
            ProfileFieldRow(label: "Role", value: profile.role?.capitalized ?? "User")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private func processAvatarSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data),
               let jpeg = image.jpegData(compressionQuality: 0.85) {
                await viewModel.updateAvatar(with: jpeg)
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Unable to load selected photo."
            }
        }
    }
}

private struct ProfileFieldRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .foregroundColor(AppColors.darkGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfileDTO?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isUpdatingAvatar = false

    private let userAPI: UserAPI

    init(userAPI: UserAPI? = nil) {
        self.userAPI = userAPI ?? UserAPI.shared
    }

    func loadProfile(force: Bool) async {
        guard let userId = SessionManager.shared.userId else { return }
        if !force, profile != nil { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await userAPI.fetchProfile(userId: userId)
            profile = data
            SessionManager.shared.updateProfileMetadata(name: data.username, avatarURL: data.avatarUrl)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateAvatar(with data: Data) async {
        guard let userId = SessionManager.shared.userId else { return }
        isUpdatingAvatar = true
        defer { isUpdatingAvatar = false }

        do {
            let payload = UpdateUserProfileRequest(
                username: profile?.username,
                phone: profile?.phone,
                address: profile?.address,
                avatarUrl: data.dataURI()
            )
            let updated = try await userAPI.updateProfile(userId: userId, payload: payload)
            profile = updated
            SessionManager.shared.updateProfileMetadata(name: updated.username, avatarURL: updated.avatarUrl)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
