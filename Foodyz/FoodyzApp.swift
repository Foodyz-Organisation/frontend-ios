import SwiftUI

@main
@MainActor
struct FoodyzApp: App {
    var body: some Scene {
        WindowGroup {
            AppNavigation()
                .environmentObject(SessionManager.shared)
        }
    }
}
