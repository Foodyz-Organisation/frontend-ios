import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    static let shared = SessionManager()

    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var userId: String?
    @Published private(set) var role: AppUserRole?
    @Published private(set) var displayName: String?
    @Published private(set) var avatarURL: String?
    @Published private(set) var email: String?

    private init() {}

    @MainActor
    func update(with response: LoginResponse) {
        accessToken = response.access_token
        refreshToken = response.refresh_token
        userId = response.id
        role = AppUserRole(rawValue: response.role) ?? .user
        displayName = response.username
        avatarURL = response.avatarUrl
        email = response.email
    }

    @MainActor
    func clear() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        role = nil
        displayName = nil
        avatarURL = nil
        email = nil
    }

    @MainActor
    func updateProfileMetadata(name: String?, avatarURL: String?) {
        if let name, !name.isEmpty {
            displayName = name
        }
        self.avatarURL = avatarURL
    }
}
