import SwiftUI

enum Screen: Hashable {
    case splash
    case login
    case userSignup
    case homeUser
    case homeProfessional
    case proSignup // <-- New case for Professional Signup
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
                            default:
                                print("Navigate to \(route)")
                            }
                        }
                    )

                case .proSignup:
                    ProSignupView(onFinish: {
                        path.removeLast(path.count)
                        path.append(Screen.homeUser)
                    })

                case .homeProfessional:
                    HomeProfessionalView()
                }
            }
        }
    }
}
