import SwiftUI

enum Screen: Hashable {
    case splash
    case login
    case userSignup
    case homeUser
    case homeProfessional
    case proSignup
    case userProfile(String)
    case postDetails(String)
    case userPostDetail(String) // User's own post detail with edit/delete
    case userPostsList(String) // User's all posts list view
    case professionalAddContent
    case professionalProfile(String)
    case professionalPostDetail(String) // Professional's own post detail with edit/delete
    case editPost(String) // Edit post caption
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
                    ProfessionalProfileScreen(
                        professionalId: professionalId,
                        onPostTap: { postId in
                            path.append(Screen.professionalPostDetail(postId))
                        }
                    )
                    
                case .userProfile(let userId):
                    UserProfileView(
                        userId: userId,
                        path: Binding(get: { path }, set: { newPath in path = newPath })
                    )
                    
                case .postDetails(let postId):
                    PostDetailsScreen(postId: postId)
                    
                case .userPostDetail(let postId):
                    UserPostDetailScreen(postId: postId, path: $path)
                    
                case .userPostsList(let userId):
                    UserPostsListView(userId: userId, initialPostId: nil, path: $path)
                    
                case .professionalPostDetail(let postId):
                    ProfessionalPostDetailScreen(postId: postId, path: $path)
                    
                case .editPost(let postId):
                    EditPostScreen(postId: postId, path: $path)
                }
            }
        }
    }
}
