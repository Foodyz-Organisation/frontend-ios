import SwiftUI
import Combine // Required for ObservableObject and @Published

class AuthService: ObservableObject {
    
    // Publishable properties for session state
    @Published var professionalId: String? = nil
    @Published var authToken: String? = nil
    @Published var isAuthenticated: Bool = false
    
    // Required stub methods used by the LoginView callback
    func setSession(proId: String?, token: String?) {
        self.professionalId = proId
        self.authToken = token
        self.isAuthenticated = (token != nil)
    }
}

// -----------------------------
// MARK: - Navigation DTOs (No change needed)
// -----------------------------

struct MenuNavigationItem: Hashable {
    let professionalId: String
    let itemId: String?
}


// -----------------------------
// MARK: - Screen Enum (No change needed)
// -----------------------------
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
    case menu
    case createMenuItem(String)
    case editMenuItem(MenuNavigationItem)
    case professionalProfile(String) // Professional ID
    case professionalMenu(String) // Professional ID for user menu view
    case shoppingCart(String) // Professional ID
    case orderConfirmation(String) // Professional ID
    case orderHistory
    case chatList(role: AppUserRole)
    case chatThread(conversationId: String, title: String?)
    case userProfile
    case reclamationList
    
    // Deals
    case dealsList
    case dealDetail(dealId: String)
    case proDealsManagement
    case addDeal
    case editDeal(dealId: String)
    
    // Reclamation
    case createReclamation(orderId: String)
    case reclamationDetail(reclamationId: String)

    // ... Equatable and Hashable implementations ...
}


// -----------------------------
// MARK: - AppNavigation
// -----------------------------
struct AppNavigation: View {
    @State private var path = NavigationPath()
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var menuVM = MenuViewModel()
    @StateObject private var dealsVM = DealsViewModel()
    
    @StateObject private var cartViewModel: CartViewModel
    
    init() {
        // Initialize with temp userId, will update after login
        _cartViewModel = StateObject(wrappedValue: CartViewModel(userId: "temp"))
    }

    var body: some View {
        NavigationStack(path: $path) {

            // Splash Screen
            SplashView(onFinished: { path.append(Screen.login) })

            // Navigation Destinations
            .navigationDestination(for: Screen.self) { screen in
                let currentProId = sessionManager.userId ?? ""
                // Get current userId safely
                let currentUserId = sessionManager.userId ?? "mock_user_id"

                switch screen {
                    
                // ===================================
                // AUTH SCREENS
                // ===================================
                    
                case .splash:
                    SplashView(onFinished: { path.append(Screen.login) })
                    
                case .login:
                    LoginView(
                        onSignup: { path.append(Screen.userSignup) },
                        onForgotPassword: { path.append(Screen.forgotPassword) },
                        onLoginSuccess: { role in
                            // Update cart with logged-in user ID
                            if let userId = sessionManager.userId {
                                cartViewModel.updateUserId(userId)
                            }
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
                    UserSignupView(onFinishSignup: { path.removeLast() })
                    
                case .proSignup:
                    ProSignupView()
                    
                case .forgotPassword:
                    ForgotPasswordView()
                    
                case .verifyOtp(let email):
                    VerifyOtpView(email: email)
                    
                case .resetPassword(let email, let resetToken):
                    ResetPasswordView(email: email, resetToken: resetToken)
                    
                // ===================================
                // USER SCREENS
                // ===================================
                    
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
                             case "reclamations":
                                 path.append(Screen.reclamationList)
                             case "login":
                                 path.removeLast(path.count)
                                 path.append(Screen.login)
                             default:
                                 print("Navigate to \(route)")
                             }
                         },
                         onNavigateToProfessional: { professionalId in
                            path.append(Screen.professionalProfile(professionalId))
                        },
                        onNavigateToOrders: {
                            path.append(Screen.orderHistory)
                        },
                        onOpenMessages: {
                            path.append(Screen.chatList(role: AppUserRole.user))
                        },
                        onOpenProfile: {
                            path.append(Screen.userProfile)
                        }
                    )
                    
                case .professionalProfile(let professionalId):
                    ClientRestaurantProfileScreen(
                        professionalId: professionalId,
                        onViewMenuClick: { profId in
                            // Navigate to menu screen for this professional
                            path.append(Screen.professionalMenu(profId))
                        }
                    )
                    
                case .professionalMenu(let professionalId):
                    DynamicMenuScreen(
                        professionalId: professionalId,
                        userId: currentUserId,
                        onBackClick: { path.removeLast() },
                        onCartClick: {
                            path.append(Screen.shoppingCart(professionalId))
                        }
                    )
                    
                case .shoppingCart(let professionalId):
                    ShoppingCartScreen(
                        professionalId: professionalId,
                        userId: currentUserId,
                        onCheckout: { _ in
                            path.append(Screen.orderConfirmation(professionalId))
                        }
                    )
                    .environmentObject(cartViewModel) // Pass shared cartViewModel
                    
                case .orderConfirmation(let professionalId):
                    OrderConfirmationScreen(
                        cartViewModel: cartViewModel, // Use shared cartViewModel
                        professionalId: professionalId,
                        onOrderSuccess: {
                            path.removeLast() // Remove confirmation
                            path.removeLast() // Remove cart
                            path.append(Screen.orderHistory)
                        }
                    )
                    
                case .orderHistory:
                    OrderHistoryScreen(
                        userId: currentUserId,
                        onOrderClick: { orderId in
                            print("Order clicked: \(orderId)")
                            // Future: navigate to order details
                        },
                        onReclamationClick: { orderId in
                            // Navigate to ReclamationView with order ID
                            path.append(Screen.createReclamation(orderId: orderId))
                        }
                    )
                
                case .createReclamation(let orderId):
                    ReclamationView(
                        restaurantNames: ["Restaurant A", "Restaurant B", "Restaurant C"], // TODO: Fetch from API
                        complaintTypes: ["Late delivery", "Missing item", "Quality issue", "Other"],
                        commandeConcernees: [orderId] // Use the order ID as the concerned order
                    ) { restaurant, type, description, photos in
                        print("Réclamation soumise pour commande \(orderId): \(type)")
                        // Navigate back after submission
                        path.removeLast()
                    }

                case .chatList(let role):
                    ChatListView(role: role) { conversation, resolvedTitle in
                        path.append(Screen.chatThread(conversationId: conversation.id, title: resolvedTitle))
                    }

                case .chatThread(let conversationId, let title):
                    ChatDetailView(conversationId: conversationId, title: title)

                case .userProfile:
                    UserProfileView()
                
                case .reclamationList:
                    ReclamationListView()
                
                case .createReclamation(let orderId):
                    ReclamationView(
                        restaurantNames: ["Restaurant A", "Restaurant B", "Restaurant C"], // TODO: Fetch from API
                        complaintTypes: ["Late delivery", "Missing item", "Quality issue", "Other"],
                        commandeConcernees: [orderId] // Use the order ID as the concerned order
                    ) { restaurant, type, description, photos in
                        print("Réclamation soumise pour commande \(orderId): \(type)")
                        // Navigate back after submission
                        path.removeLast()
                    }
                
                case .reclamationDetail(let reclamationId):
                    // TODO: Fetch reclamation by ID and show detail
                    // For now, this is handled by NavigationLink in ReclamationListView
                    Text("Reclamation Detail: \(reclamationId)")
                        .navigationTitle("Détails Réclamation")
                    
                // ===================================
                // PROFESSIONAL SCREENS
                // ===================================
                    
                case .homeProfessional:
                    // NOTE: This order (path, professionalId) should match your HomeProfessionalView definition
                    HomeProfessionalView(path: $path, professionalId: currentProId)
                    /* 
                    // User snippet version (kept for reference if HomeProfessionalView is updated)
                    HomeProfessionalView(onOpenMessages: {
                        path.append(Screen.chatList(role: AppUserRole.professional))
                    }) 
                    */
                case .menu:
                    // 🔴 FIX APPLIED HERE: Swapping the order to professionalId, then path
                    MenuItemManagementScreen(viewModel: menuVM,
                                             professionalId: currentProId,
                                             path: $path)
                case .createMenuItem(let proId):
                    CreateMenuItemScreen(viewModel: menuVM,
                                         professionalId: currentProId,
                                         path: $path)
                case .editMenuItem(let navItem):
                    if let itemId = navItem.itemId {
                        ItemDetailsView(viewModel: menuVM, itemId: itemId, professionalId: navItem.professionalId)
                    }
                    
                // ===================================
                // DEALS SCREENS
                // ===================================
                    
                case .dealsList:
                    DealsListUserView(viewModel: dealsVM)
                        .onAppear {
                            dealsVM.loadDeals()
                        }
                    
                case .dealDetail(let dealId):
                    DealDetailUserView(dealId: dealId, viewModel: dealsVM)
                        .onAppear {
                            dealsVM.loadDealById(dealId)
                        }
                    
                case .proDealsManagement:
                    ProDealsManagementView(
                        viewModel: dealsVM,
                        onAddDealClick: {
                            path.append(Screen.addDeal)
                        },
                        onEditDealClick: { dealId in
                            path.append(Screen.editDeal(dealId: dealId))
                        }
                    )
                    .onAppear {
                        dealsVM.loadDeals()
                    }
                    
                case .addDeal:
                    AddEditDealView(viewModel: dealsVM)
                        .navigationTitle("Nouveau Deal")
                    
                case .editDeal(let dealId):
                    AddEditDealView(viewModel: dealsVM)
                        .navigationTitle("Modifier Deal")
                        .onAppear {
                            dealsVM.loadDealById(dealId)
                        }
                }
            }
        }
        .environmentObject(sessionManager)
    }
}


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
                switch viewModel.dealDetailState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    
                case .success(let deal):
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
                    
                case .error(let message):
                    VStack(spacing: 16) {
                        Text("Erreur")
                            .font(.headline)
                            .foregroundColor(BrandColors.Red)
                        Text(message)
                            .font(.body)
                            .foregroundColor(BrandColors.TextSecondary)
                        Button("Réessayer") {
                            viewModel.loadDealById(dealId)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
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
