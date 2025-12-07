import SwiftUI

enum Screen: Hashable {
    case splash
    case login
    case userSignup
    case homeUser
    case homeProfessional
    case proSignup // <-- New case for Professional Signup
    case userProfile(String) // <-- New case for User Profile
    case postDetails(String) // <-- New case for Post Details
    case professionalAddContent // <-- New case for Professional Add Content
    case professionalProfile(String) // <-- New case for Professional Profile
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
                        },
                        onNavigateToProfile: {
                            if let userId = UserSession.shared.userId {
                                path.append(Screen.userProfile(userId))
                            }
                        },
                        onNavigateToPost: { postId in
                            path.append(Screen.postDetails(postId))
                        }
                    )

                case .proSignup:
                    ProSignupView(onFinish: {
                        path.removeLast(path.count)
                        path.append(Screen.homeUser)
                    })

                case .homeProfessional:
                    HomeProfessionalView(
                        path: $path,
                        professionalId: UserSession.shared.userId ?? ""
                    )
                    
                case .professionalAddContent:
                    ProfessionalAddContentScreen()
                    
                case .professionalProfile(let professionalId):
                    ProfessionalProfileScreen(professionalId: professionalId)
                    
                case .userProfile(let userId):
                    UserProfileView(userId: userId)
                    
                case .postDetails(let postId):
                    PostDetailsScreen(postId: postId)
                }
            }
        }
    }
}
