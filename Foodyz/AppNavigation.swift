import SwiftUI

enum Screen: Hashable {
    case splash
    case login
    case userSignup
    case homeUser
    case homeProfessional
    case proSignup
    case chatList(role: AppUserRole)
    case chatThread(conversationId: String, title: String?)
    case userProfile
}

struct AppNavigation: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            
            // Root view — Splash screen
            SplashView(onFinished: {
                path.append(Screen.login)
            })
            
            .navigationDestination(for: Screen.self) { screen in
                switch screen {
                case .splash:
                    SplashView(onFinished: { path.append(Screen.login) })

                case .login:
                    LoginView(
                        onSignup: { path.append(Screen.userSignup) },
                        onLoginSuccess: { role in
                            path.removeLast(path.count)
                            switch role { // <-- match enum, not string
                            case .user:
                                path.append(Screen.homeUser)
                            case .professional:
                                path.append(Screen.homeProfessional)
                            }
                        }
                    )


                case .userSignup:
                    UserSignupView(onFinishSignup: { path.removeLast() })

                case .homeUser:
                    HomeUserScreen(
                        onNavigateDrawer: { route in
                            switch route {
                            case "signup_pro":
                                path.append(Screen.proSignup)
                            case "home":
                                path.removeLast(path.count)
                                path.append(Screen.homeUser)
                            case "chat":
                                path.append(Screen.chatList(role: AppUserRole.user))
                            case "profile":
                                path.append(Screen.userProfile)
                            case "login":
                                path.removeLast(path.count)
                                path.append(Screen.login)
                            default:
                                print("Navigate to \(route)")
                            }
                        },
                        onOpenMessages: {
                            path.append(Screen.chatList(role: AppUserRole.user))
                        },
                        onOpenProfile: {
                            path.append(Screen.userProfile)
                        }
                    )

                case .proSignup:
                    ProSignupView(onFinish: {
                        path.removeLast(path.count)
                        path.append(Screen.homeUser)
                    })

                case .homeProfessional:
                    HomeProfessionalView(onOpenMessages: {
                        path.append(Screen.chatList(role: AppUserRole.professional))
                    })

                case .chatList(let role):
                    ChatListView(role: role) { conversation, resolvedTitle in
                        path.append(Screen.chatThread(conversationId: conversation.id, title: resolvedTitle))
                    }

                case .chatThread(let conversationId, let title):
                    ChatDetailView(conversationId: conversationId, title: title)

                case .userProfile:
                    UserProfileView()
                }
            }
        }
    }
}
