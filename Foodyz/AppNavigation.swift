//
//  AppNavigation.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import SwiftUI

enum Screen: Hashable {
    case splash
    case login
    case userSignup
    case proSignup
    case forgotPassword
    case verifyOtp(email: String)
    case resetPassword(email: String, resetToken: String)
    case homeUser
    case homeProfessional
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
                    SplashView(onFinished: {
                        path.append(Screen.login)
                    })
                    
                case .login:
                    LoginView(
                        onSignup: {
                            path.append(Screen.userSignup)
                        },
                        onForgotPassword: {
                            path.append(Screen.forgotPassword)
                        },
                        onLoginSuccess: { role in
                            path.removeLast(path.count)
                            switch role {
                            case .user:
                                path.append(Screen.homeUser)
                            case .professional:
                                path.append(Screen.homeProfessional)
                            }
                        }
                    )
                    
                case .userSignup:
                    UserSignupView(onFinishSignup: {
                        path.removeLast()
                    })
                    
                case .proSignup:
                    ProSignupView(onFinish: {
                        path.removeLast(path.count)
                        path.append(Screen.homeUser)
                    })
                    
                case .forgotPassword:
                    ForgotPasswordView()
                    
                case .verifyOtp(let email):
                    VerifyOtpView(email: email)
                    
                case .resetPassword(let email, let resetToken):
                    ResetPasswordView(email: email, resetToken: resetToken)
                    
                case .homeUser:
                    HomeUserScreen(
                        onNavigateDrawer: { route in
                            switch route {
                            case "signup_pro":
                                path.append(Screen.proSignup)
                            case "home":
                                path.removeLast(path.count)
                                path.append(Screen.homeUser)
                            case "logout":
                                path.removeLast(path.count)
                                path.append(Screen.login)
                            default:
                                print("Navigate to \(route)")
                            }
                        }
                    )
                    
                case .homeProfessional:
                    MainTabView()
                }
            }
        }
    }
}

#Preview {
    AppNavigation()
}
