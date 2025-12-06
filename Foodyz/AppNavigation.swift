import SwiftUI
import Combine // Required for ObservableObject and @Published

// -----------------------------
// MARK: - AuthService Placeholder (The Fix) 🛠️
// -----------------------------

/// Minimal AuthService definition to resolve the 'Cannot find AuthService in scope' error.
/// In a real project, this class should be in its own AuthService.swift file.
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
    case splash
    case login
    case userSignup
    case homeUser
    case homeProfessional
    case proSignup
    case menu
    case createMenuItem(String)
    case editMenuItem(MenuNavigationItem)
    case professionalProfile(String) // Professional ID
    case professionalMenu(String) // Professional ID for user menu view
    case shoppingCart(String) // Professional ID
    case orderConfirmation(String) // Professional ID
    case orderHistory

    // ... Equatable and Hashable implementations ...
}


// -----------------------------
// MARK: - AppNavigation
// -----------------------------
struct AppNavigation: View {
    @State private var path = NavigationPath()
    @StateObject private var authService = AuthService()
    @StateObject private var menuVM = MenuViewModel()
    
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
                let currentProId = authService.professionalId ?? ""
                // Get current userId safely - using professionalId as userId
                let currentUserId = authService.professionalId ?? "mock_user_id"

                switch screen {
                    
                // ===================================
                // AUTH SCREENS
                // ===================================
                    
                case .splash:
                    SplashView(onFinished: { path.append(Screen.login) })
                    
                case .login:
                    LoginView(
                        onSignup: { path.append(Screen.userSignup) },
                        onLoginSuccess: { role, id, token in
                            authService.setSession(proId: id, token: token)
                            // Update cart userId when user logs in
                            cartViewModel.updateUserId(id)
                            path.removeLast(path.count)
                            switch role {
                            case .user:
                                path.append(Screen.homeUser)
                            case .professional:
                                path.append(Screen.homeProfessional)
                            default:
                                path.append(Screen.login)
                            }
                        }
                    )

                    
                case .userSignup:
                    UserSignupView(onFinishSignup: { path.removeLast() })
                    
                case .proSignup:
                    ProSignupView()
                    
                // ===================================
                // USER SCREENS
                // ===================================
                    
                case .homeUser:
                    HomeUserScreen(
                        onNavigateToProfessional: { professionalId in
                            path.append(Screen.professionalProfile(professionalId))
                        },
                        onNavigateToOrders: {
                            path.append(Screen.orderHistory)
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
                        }
                    )
                    
                // ===================================
                // PROFESSIONAL SCREENS
                // ===================================
                    
                case .homeProfessional:
                    // NOTE: This order (path, professionalId) should match your HomeProfessionalView definition
                    HomeProfessionalView(path: $path, professionalId: currentProId)
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
                }
            }
        }
        .environmentObject(authService)
    }
}

// -----------------------------
// MARK: - Preview
// -----------------------------
struct AppNavigation_Previews: PreviewProvider {
    static var previews: some View {
        AppNavigation()
            // Add environment object for preview to prevent crashes if child views use it
            .environmentObject(AuthService())
    }
}
