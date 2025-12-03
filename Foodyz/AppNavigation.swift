//
//  AppNavigation.swift
//  Foodyz
//
//  Created by Mouscou Mohamed khalil on 15/11/2025.
//

import SwiftUI

// MARK: - Navigation Routes
enum Screen: Hashable {
    // Auth
    case splash
    case login
    case userSignup
    case proSignup
    case forgotPassword
    case verifyOtp(email: String)
    case resetPassword(email: String, resetToken: String)
    
    // Home
    case homeUser
    case homeProfessional
    
    // Deals - Professional
    case proDealsManagement
    case addDeal
    case editDeal(dealId: String)
    
    // Deals - User
    case dealsList
    case dealDetail(dealId: String)
}

// MARK: - Main Navigation
struct AppNavigation: View {
    @State private var path = NavigationPath()
    @StateObject private var dealsViewModel = DealsViewModel()
    
    var body: some View {
        NavigationStack(path: $path) {
            // Root view — Splash screen
            SplashView(onFinished: {
                path.append(Screen.login)
            })
            .navigationDestination(for: Screen.self) { screen in
                destinationView(for: screen)
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for screen: Screen) -> some View {
        switch screen {
        // ============================================
        // 📌 SECTION AUTH
        // ============================================
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
            
        // ============================================
        // 📌 SECTION HOME
        // ============================================
        case .homeUser:
            HomeUserScreen(
                onNavigateDrawer: { route in
                    handleDrawerNavigation(route: route)
                }
            )
            
        case .homeProfessional:
            HomeProfessionalView(
                onNavigateToDealsList: {
                    path.append(Screen.proDealsManagement)
                }
            )
            
        // ============================================
        // 📌 SECTION DEALS - PROFESSIONAL
        // ============================================
        case .proDealsManagement:
            ProDealsManagementView(
                viewModel: dealsViewModel,
                onAddDealClick: {
                    path.append(Screen.addDeal)
                },
                onEditDealClick: { dealId in
                    path.append(Screen.editDeal(dealId: dealId))
                }
            )
            .onAppear {
                dealsViewModel.loadDeals()
            }
            
        case .addDeal:
            AddEditDealView(viewModel: dealsViewModel)
                .navigationTitle("Nouveau Deal")
            
        case .editDeal(let dealId):
            AddEditDealView(viewModel: dealsViewModel)
                .navigationTitle("Modifier Deal")
            
        // ============================================
        // 📌 SECTION DEALS - USER
        // ============================================
        case .dealsList:
            DealsListUserView(viewModel: dealsViewModel)
                .onAppear {
                    dealsViewModel.loadDeals()
                }
            
        case .dealDetail(let dealId):
            DealDetailUserView(dealId: dealId, viewModel: dealsViewModel)
        }
    }
    
    // MARK: - Navigation Helpers
    private func handleDrawerNavigation(route: String) {
        switch route {
        case "signup_pro":
            path.append(Screen.proSignup)
        case "home":
            path.removeLast(path.count)
            path.append(Screen.homeUser)
        case "deals":
            path.append(Screen.dealsList)
        case "logout":
            path.removeLast(path.count)
            path.append(Screen.login)
        default:
            print("⚠️ Unknown route: \(route)")
        }
    }
    
    private func handleProfessionalNavigation(route: String) {
        switch route {
        case "pro_deals":
            path.append(Screen.proDealsManagement)
        case "menu_management":
            print("⚠️ Menu management not yet implemented")
        case "add_meal":
            print("⚠️ Add meal not yet implemented")
        case "restaurant_reclamations":
            print("⚠️ Restaurant reclamations not yet implemented")
        case "logout":
            path.removeLast(path.count)
            path.append(Screen.login)
        default:
            print("⚠️ Unknown route: \(route)")
        }
    }
}

// MARK: - Placeholder Views (à remplacer par vos vraies vues)

struct DealsListUserView: View {
    @ObservedObject var viewModel: DealsViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch viewModel.dealsState {
                case .loading:
                    ProgressView()
                case .success(let deals):
                    ForEach(deals) { deal in
                        NavigationLink(value: Screen.dealDetail(dealId: deal._id)) {
                            DealUserCardView(deal: deal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                case .error(let message):
                    Text(message)
                        .foregroundColor(BrandColors.Red)
                }
            }
            .padding()
        }
        .navigationTitle("Deals")
    }
}

struct DealUserCardView: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = URL(string: deal.image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(height: 180)
                .clipped()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.restaurantName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                
                Text(deal.description)
                    .font(.system(size: 14))
                    .foregroundColor(BrandColors.TextSecondary)
                    .lineLimit(2)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DealDetailUserView: View {
    let dealId: String
    @ObservedObject var viewModel: DealsViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Trouver le deal dans la liste
                if case .success(let deals) = viewModel.dealsState,
                   let deal = deals.first(where: { $0._id == dealId }) {
                    
                    if let url = URL(string: deal.image) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(height: 300)
                        .clipped()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(deal.restaurantName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(BrandColors.TextPrimary)
                        
                        Text(deal.description)
                            .font(.system(size: 16))
                            .foregroundColor(BrandColors.TextSecondary)
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(BrandColors.Yellow)
                            Text(deal.category)
                                .font(.system(size: 14))
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(BrandColors.TextSecondary)
                            Text("Expire: \(deal.endDate)")
                                .font(.system(size: 14))
                        }
                        
                        if deal.isActive {
                            Text("✓ Deal actif")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(BrandColors.Green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(BrandColors.Green.opacity(0.15))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle("Détail du Deal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    AppNavigation()
}
