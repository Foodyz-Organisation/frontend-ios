import SwiftUI

// -----------------------------
// MARK: - Navigation DTOs
// -----------------------------

struct MenuNavigationItem: Hashable {
    let professionalId: String
    let itemId: String?
}

// -----------------------------
// MARK: - Screen Enum
// -----------------------------

enum Screen: Hashable {
    // Auth
    case splash
    case login
    case userSignup
    case addPhone(AuthViewModel)
    case addAddress(AuthViewModel)
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
    case payment(professionalId: String, orderType: OrderType, deliveryAddress: String?, notes: String?) // Payment screen
    case orderHistory
    case orderDetail(String) // Order ID
    case chatList(role: AppUserRole)
    case chatThread(conversationId: String, title: String?)
    case myProfile // Current user profile (no parameter)
    case userProfile(String) // Other user profile (with userId parameter)
    case loyaltyPoints
    case reclamationList
    case eventList
    case userEventList
  
    // Deals
    case dealsList
    case dealDetail(dealId: String)
    case proDealsManagement
    case proDealDetail(dealId: String)
    case addDeal
    case editDeal(dealId: String)
    
    // Reclamation
    case createReclamation(orderId: String)
    case reclamationDetail(reclamationId: String)
    
    // Posts
    case postDetails(String)
    case userPostDetail(String) // User's own post detail with edit/delete
    case userPostsList(String) // User's all posts list view
    case professionalAddContent
    case professionalPostDetail(String) // Professional's own post detail with edit/delete
    case editPost(String) // Edit post caption
    case reels // Reels screen
    case trending // Trending screen
    case professionalNotifications // New notification screen
    case professionalProfileManagement // New profile management screen
    case professionalDataEdit // New professional data edit screen
    case professionalEmailNameEdit // New email and name edit screen
    case professionalChangePassword // New change password screen
    case userNotifications // New user notification screen
    case settings // New settings screen
    case editProfile // New edit profile screen
    case changePassword // New change password screen
    case savedPosts // Saved posts screen
    case allUsersTracking // All users tracking map screen
}

// -----------------------------
// MARK: - AppNavigation
// -----------------------------

struct AppNavigation: View {
    @State private var path = NavigationPath()
    @StateObject private var sessionManager = SessionManager.shared
    @StateObject private var menuVM = MenuViewModel()
    @StateObject private var dealsVM = DealsViewModel()
    @StateObject private var eventManager = EventManager()
    @State private var incomingCallOffer: [String: Any]?
    @State private var isIncomingCallPresented = false
    @EnvironmentObject private var session: SessionManager
    
    @StateObject private var cartViewModel: CartViewModel
    
    init() {
        // Initialize with temp userId, will update after login
        _cartViewModel = StateObject(wrappedValue: CartViewModel(userId: "temp"))
    }
    
    // MARK: - Authentication Helpers
    
    /// Check if user is logged in
    private func isUserLoggedIn() -> Bool {
        // Check TokenManager for access token
        if let token = TokenManager.shared.getAccessToken(), !token.isEmpty {
            return true
        }
        // Also check SessionManager as fallback
        if let sessionToken = sessionManager.accessToken, !sessionToken.isEmpty {
            return true
        }
        return false
    }
    
    /// Get current user role
    private func getCurrentUserRole() -> AppUserRole {
        if let roleString = TokenManager.shared.getUserRole(),
           let role = AppUserRole(rawValue: roleString) {
            return role
        }
        if let sessionRole = sessionManager.role {
            return sessionRole
        }
        return .user // Default to user
    }

    var body: some View {
        NavigationStack(path: $path) {
            // Check authentication state and navigate accordingly
            Group {
                if isUserLoggedIn() {
                    // User is logged in, show appropriate home screen
                    // Use a minimal view that will be replaced by navigation
                    Color.clear
                        .task {
                            // Navigate to home based on role if path is empty
                            if path.isEmpty {
                                let role = getCurrentUserRole()
                                print("🚀 [AppNavigation] User is logged in, navigating to home (role: \(role))")
                                switch role {
                                case .user:
                                    path.append(Screen.homeUser)
                                case .professional:
                                    path.append(Screen.homeProfessional)
                                }
                            }
                        }
                } else {
                    // User not logged in, show splash then login
                    SplashView(onFinished: {
                        if path.isEmpty {
                            print("🚀 [AppNavigation] User not logged in, navigating to login")
                            path.append(Screen.login)
                        }
                    })
                }
            }

            // Navigation Destinations
            .navigationDestination(for: Screen.self) { screen in
                // Use TokenManager for consistent user ID retrieval (cache to avoid multiple calls)
                let cachedUserId = TokenManager.shared.getUserId()
                let currentProId = cachedUserId ?? ""
                let currentUserId = cachedUserId ?? "mock_user_id"

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
                            print("🚀 [AppNavigation] Login success callback received with role: \(role)")
                            
                            // Ensure we're on the main thread for UI updates
                            Task { @MainActor in
                                print("🚀 [AppNavigation] Updating cart and navigating...")
                                
                                // Update cart with logged-in user ID
                                if let userId = sessionManager.userId {
                                    print("🚀 [AppNavigation] Updating cart with userId: \(userId)")
                                    cartViewModel.updateUserId(userId)
                                } else {
                                    // Try to get from TokenManager as fallback
                                    if let userId = TokenManager.shared.getUserId() {
                                        print("🚀 [AppNavigation] Using TokenManager userId: \(userId)")
                                        cartViewModel.updateUserId(userId)
                                    } else {
                                        print("⚠️ [AppNavigation] No userId found in SessionManager or TokenManager")
                                    }
                                }
                                
                                // Connect socket
                                connectSocket()
                                
                                // Clear navigation path and navigate to home
                                print("🚀 [AppNavigation] Clearing path (current count: \(path.count))")
                                path.removeLast(path.count)
                                
                                // Small delay to ensure path is cleared
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                
                                // Navigate based on role
                                switch role {
                                case .user:
                                    print("🚀 [AppNavigation] Navigating to homeUser")
                                    path.append(Screen.homeUser)
                                case .professional:
                                    print("🚀 [AppNavigation] Navigating to homeProfessional")
                                    path.append(Screen.homeProfessional)
                                }
                                
                                print("✅ [AppNavigation] Navigation complete. Path count: \(path.count)")
                            }
                        }
                    )
                    
                case .userSignup:
                    UserSignupView(onNext: { vm in path.append(Screen.addPhone(vm)) },
                                   onFinishSignup: { path.removeLast() })
                    
                case .addPhone(let vm):
                    AddPhoneView(viewModel: vm, 
                                 onNext: { path.append(Screen.addAddress(vm)) },
                                 onBack: { path.removeLast() })
                    
                case .addAddress(let vm):
                    AddAddressView(viewModel: vm,
                                   onFinish: {
                                       path.removeLast(path.count)
                                       path.append(Screen.login)
                                   },
                                   onBack: { path.removeLast() })
                    
                case .proSignup:
                    ProSignupView(
                        onFinish: {
                            // Navigate to login screen after successful professional signup
                            path.removeLast(path.count)
                            path.append(Screen.login)
                        }
                    )
                    
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
                                if let userId = TokenManager.shared.getUserId() {
                                    path.append(Screen.userProfile(userId))
                                }
                            case "events":
                                path.append(Screen.userEventList)
                            case "reclamations":
                                path.append(Screen.reclamationList)
                            case "loyalty_points":
                                path.append(Screen.loyaltyPoints)
                            case "order_history":
                                path.append(Screen.orderHistory)
                            case "deals":
                                path.append(Screen.dealsList)
                            case "login":
                                disconnectSocket()
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
                        onNavigateToDeals: {
                            path.append(Screen.dealsList)
                        },
                        onNavigateToReels: {
                            path.append(Screen.reels)
                        },
                        onNavigateToTrending: {
                            path.append(Screen.trending)
                        },
                        onOpenMessages: {
                            path.append(Screen.chatList(role: AppUserRole.user))
                        },
                        onOpenProfile: {
                            if let userId = TokenManager.shared.getUserId() {
                                path.append(Screen.userProfile(userId))
                            }
                        },
                        onPostClick: { postId in
                            path.append(Screen.postDetails(postId))
                        }
                    )
                    
                case .professionalProfile(let professionalId):
                            // Show different screens based on whether current user is viewing their own profile
                            if currentProId == professionalId {
                                // Professional viewing their own profile
                                ProfessionalProfileScreen(
                                    professionalId: professionalId,
                                    onPostTap: { postId in
                                        path.append(Screen.professionalPostDetail(postId))
                                    },
                                    onSettingsTap: {
                                        path.append(Screen.professionalProfileManagement)
                                    }
                                )
                            } else {
                                // User viewing a professional's profile
                    ClientRestaurantProfileScreen(
                        professionalId: professionalId,
                        onViewMenuClick: { profId in
                            path.append(Screen.professionalMenu(profId))
                        }
                    )
                            }
                    
                case .professionalMenu(let professionalId):
                    // Update cartViewModel with current user ID before showing menu
                    Group {
                        if cartViewModel.userId != currentUserId && currentUserId != "mock_user_id" {
                            let _ = {
                                print("🔄 [AppNavigation] Updating cartViewModel userId from '\(cartViewModel.userId)' to '\(currentUserId)'")
                                cartViewModel.updateUserId(currentUserId)
                            }()
                        }
                        
                        // Check and clear cart if switching to a different professional
                        let _ = {
                            print("🔄 [AppNavigation] Checking cart for professional \(professionalId)")
                            cartViewModel.checkAndClearCartIfNeeded(for: professionalId)
                        }()
                        
                        DynamicMenuScreen(
                            professionalId: professionalId,
                            userId: currentUserId,
                            onBackClick: { path.removeLast() },
                            onCartClick: {
                                path.append(Screen.shoppingCart(professionalId))
                            },
                            onConfirmOrderClick: {
                                // Navigate to order confirmation screen
                                path.append(Screen.orderConfirmation(professionalId))
                            }
                        )
                        .environmentObject(cartViewModel)
                    }
                    
                case .shoppingCart(let professionalId):
                    // Ensure cartViewModel has the correct userId
                    Group {
                        if cartViewModel.userId != currentUserId && currentUserId != "mock_user_id" {
                            let _ = {
                                print("🔄 [AppNavigation] Updating cartViewModel userId from '\(cartViewModel.userId)' to '\(currentUserId)' before showing cart")
                                cartViewModel.updateUserId(currentUserId)
                            }()
                        }
                        
                        ShoppingCartScreen(
                            professionalId: professionalId,
                            userId: currentUserId,
                            onCheckout: { _ in
                                path.append(Screen.orderConfirmation(professionalId))
                            }
                        )
                        .environmentObject(cartViewModel)
                    }
                    
                case .orderConfirmation(let professionalId):
                    OrderConfirmationScreen(
                        cartViewModel: cartViewModel,
                        professionalId: professionalId,
                        onOrderSuccess: {
                            path.removeLast() // Remove confirmation
                            path.removeLast() // Remove cart
                            path.append(Screen.orderHistory)
                        },
                        onNavigateToPayment: { orderType, deliveryAddress, notes in
                            path.append(Screen.payment(professionalId: professionalId, orderType: orderType, deliveryAddress: deliveryAddress, notes: notes))
                        }
                    )
                    
                case .payment(let professionalId, let orderType, let deliveryAddress, let notes):
                    PaymentScreen(
                        cartViewModel: cartViewModel,
                        professionalId: professionalId,
                        orderType: orderType,
                        deliveryAddress: deliveryAddress,
                        notes: notes,
                        totalPrice: cartViewModel.totalPrice,
                        onOrderSuccess: {
                            // Remove payment and confirmation screens, go to order history
                            path.removeLast() // Remove payment
                            path.removeLast() // Remove confirmation
                            path.removeLast() // Remove cart
                            path.append(Screen.orderHistory)
                        }
                    )
                    
                case .orderHistory:
                    OrderHistoryScreen(
                        userId: currentUserId,
                        onOrderClick: { orderId in
                            path.append(Screen.orderDetail(orderId))
                        },
                        onReclamationClick: { orderId in
                            path.append(Screen.createReclamation(orderId: orderId))
                        },
                        onHomeClick: {
                            // Navigate to home
                            path.removeLast(path.count)
                            path.append(Screen.homeUser)
                        },
                        onMessagesClick: {
                            // Navigate to chat list
                            path.removeLast(path.count)
                            path.append(Screen.chatList(role: AppUserRole.user))
                        },
                        onOrdersClick: {
                            // Already on orders, do nothing
                        },
                        onProfileClick: {
                            if let userId = TokenManager.shared.getUserId() {
                                path.append(Screen.userProfile(userId))
                            }
                        },
                        onSearchClick: {
                            // Search functionality (if needed)
                        },
                        onAddPostClick: {
                            // Add post functionality (if needed)
                        },
                        onOpenDrawer: {
                            // Drawer functionality (if needed)
                        },
                        onNavigateDrawer: { route in
                             switch route {
                             case "signup_pro":
                                 path.append(Screen.proSignup)
                             case "home":
                                  path.removeLast(path.count)
                                  path.append(Screen.homeUser)
                             case "chat":
                                  path.removeLast(path.count)
                                  path.append(Screen.chatList(role: AppUserRole.user))
                             case "profile":
                                  if let userId = TokenManager.shared.getUserId() {
                                      path.append(Screen.userProfile(userId))
                                  }
                             case "events":
                                  path.append(Screen.userEventList)
                             case "reclamations":
                                  path.append(Screen.reclamationList)
                             case "loyalty_points":
                                   path.append(Screen.loyaltyPoints)
                             case "order_history":
                                 // Already here
                                 break
                            case "deals":
                                path.append(Screen.dealsList)
                            case "saved_posts":
                                path.append(Screen.savedPosts)
                            case "login":
                                disconnectSocket()
                                path.removeLast(path.count)
                                path.append(Screen.login)
                            default:
                                print("Navigate to \(route)")
                            }
                        }
                    )
                    
                case .orderDetail(let orderId):
                    OrderDetailsScreen(
                        orderId: orderId,
                        userId: currentUserId
                    )

                case .chatList(let role):
                    ChatListView(
                        role: role,
                        path: $path,
                        onConversationSelected: { conversation, resolvedTitle in
                            path.append(Screen.chatThread(conversationId: conversation.id, title: resolvedTitle))
                        },
                        onHomeClick: {
                            // Navigate to home
                            path.removeLast(path.count)
                            path.append(Screen.homeUser)
                        },
                        onMessagesClick: {
                            // Already on messages, do nothing
                        },
                        onOrdersClick: {
                            // Navigate to orders
                            path.removeLast(path.count)
                            path.append(Screen.orderHistory)
                        },
                        onProfileClick: {
                            if let userId = TokenManager.shared.getUserId() {
                                path.append(Screen.userProfile(userId))
                            }
                        },
                        onSearchClick: {
                            // Search functionality (if needed)
                        },
                        onAddPostClick: {
                            // Add post functionality (if needed)
                        },
                        onOpenDrawer: {
                            // Drawer functionality (if needed)
                        },
                        onNavigateDrawer: { route in
                            switch route {
                            case "signup_pro":
                                path.append(Screen.proSignup)
                            case "home":
                                path.removeLast(path.count)
                                path.append(Screen.homeUser)
                            case "chat":
                                // Already on chat
                                break
                            case "profile":
                                if let userId = TokenManager.shared.getUserId() {
                                    path.append(Screen.userProfile(userId))
                                }
                            case "events":
                                path.append(Screen.userEventList)
                            case "reclamations":
                                path.append(Screen.reclamationList)
                            case "loyalty_points":
                                path.append(Screen.loyaltyPoints)
                            case "order_history":
                                path.removeLast(path.count)
                                path.append(Screen.orderHistory)
                            case "deals":
                                path.append(Screen.dealsList)
                            case "saved_posts":
                                path.append(Screen.savedPosts)
                            case "login":
                                disconnectSocket()
                                path.removeLast(path.count)
                                path.append(Screen.login)
                            default:
                                print("Navigate to \(route)")
                            }
                        }
                    )

                case .chatThread(let conversationId, let title):
                    ChatDetailView(conversationId: conversationId, title: title)
                   
                case .userNotifications:
                    UserNotificationScreen(path: $path)

                        case .myProfile:
                            MyProfileView()
                            
                        case .settings:
                            SettingsView(
                                onLogout: {
                                    disconnectSocket()
                                    path.removeLast(path.count)
                                    path.append(Screen.login)
                                },
                                onEditProfile: {
                                    path.append(Screen.editProfile)
                                },
                                onChangePassword: {
                                    path.append(Screen.changePassword)
                                }
                            )
                            
                        case .editProfile:
                            EditProfileView()
                            
                        case .changePassword:
                            ChangePasswordView()
                
                case .loyaltyPoints:
                    LoyaltyPointsScreen(loyaltyData: nil) {
                        path.removeLast()
                    }
                
                case .reclamationList:
                    ReclamationListView()
                
                case .userEventList:
                    UserEventListView()
                        .environmentObject(eventManager)
                
                case .eventList:
                    EventListView()
                        .environmentObject(eventManager)
                
                case .createReclamation(let orderId):
                    ReclamationView(
                                restaurantNames: ["Restaurant A", "Restaurant B", "Restaurant C"],
                        complaintTypes: ["Late delivery", "Missing item", "Quality issue", "Other"],
                                commandeConcernees: [orderId]
                    ) { restaurant, type, description, photos in
                        path.removeLast()
                    }
                
                case .reclamationDetail(let reclamationId):
                    Text("Reclamation Detail: \(reclamationId)")
                        .navigationTitle("Détails Réclamation")
                    
                // ===================================
                // PROFESSIONAL SCREENS
                // ===================================
                    
                case .homeProfessional:
                    HomeProfessionalView(
                        path: $path,
                        professionalId: currentProId,
                        onNavigateDrawer: { route in
                            switch route {
                            case "menu":
                                path.append(Screen.menu)
                            case "deals_management":
                                path.append(Screen.proDealsManagement)
                            case "analytics":
                                // TODO: Add analytics screen
                                print("Navigate to analytics")
                            case "events":
                                path.append(Screen.eventList)
                            case "notifications":
                                // TODO: Add notifications screen
                                print("Navigate to notifications")
                            case "reclamations":
                                path.append(Screen.reclamationList)
                            case "settings":
                                // TODO: Add settings screen
                                print("Navigate to settings")
                            case "logout":
                                disconnectSocket()
                                path.removeLast(path.count)
                                path.append(Screen.login)
                            default:
                                print("Navigate to \(route)")
                            }
                        }
                    )
                            
                case .menu:
                            MenuItemManagementScreen(
                                viewModel: menuVM,
                                             professionalId: currentProId,
                                path: $path
                            )
                            
                        case .createMenuItem(let professionalId):
                            CreateMenuItemScreen(
                                viewModel: menuVM,
                                professionalId: professionalId,
                                path: $path
                            )
                            
                case .editMenuItem(let navItem):
                    if let itemId = navItem.itemId {
                        EditMenuItemScreen(
                            viewModel: menuVM,
                            itemId: itemId,
                            professionalId: navItem.professionalId,
                            path: $path
                        )
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
                        },
                        onDealClick: { dealId in
                            path.append(Screen.proDealDetail(dealId: dealId))
                        }
                    )
                    .onAppear {
                        dealsVM.loadDeals()
                    }
                    
                case .proDealDetail(let dealId):
                    ProDealDetailView(dealId: dealId, viewModel: dealsVM)
                    
                case .addDeal:
                    AddEditDealView(viewModel: dealsVM, dealId: nil)
                        .navigationTitle("Nouveau Deal")
                    
                case .editDeal(let dealId):
                    AddEditDealView(viewModel: dealsVM, dealId: dealId)
                        .navigationTitle("Modifier Deal")
                    
                case .professionalAddContent:
                    ProfessionalAddContentScreen(path: $path)
                    
                case .professionalNotifications:
                    ProfessionalNotificationScreen(path: $path)
                    
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
                    
                case .professionalProfileManagement:
                    ProfessionalProfileManagementScreen(path: $path)
                    
                case .professionalDataEdit:
                    ProfessionalDataEditScreen()
                
                case .professionalEmailNameEdit:
                    ProfessionalEmailNameEditScreen()
                
                case .professionalChangePassword:
                    ProfessionalChangePasswordScreen()
                    
                case .reels:
                    ReelsScreen(
                        onBack: {
                            path.removeLast()
                        },
                        onNavigateToProfessional: { professionalId in
                            path.append(Screen.professionalProfile(professionalId))
                        },
                        onFollowProfessional: { professionalId in
                            // Follow professional - you can add API call here if needed
                            print("📌 Following professional: \(professionalId)")
                            // TODO: Add follow API call if available
                        }
                    )
                    
                case .trending:
                    TrendingScreen(onBack: {
                        path.removeLast()
                    })
                    
                case .savedPosts:
                    SavedPostsScreen()
                    
                case .allUsersTracking:
                    AllUsersTrackingScreen()
                }
            }
        }
        .onReceive(SocketIOManager.shared.callMadeSubject) { offerDict in
             print("AppNavigation received call offer: \(offerDict)")
             self.incomingCallOffer = offerDict
             self.isIncomingCallPresented = true
        }
        .sheet(isPresented: $isIncomingCallPresented) {
            if let offer = incomingCallOffer,
               let conversationId = offer["conversationId"] as? String {
               CallView(conversationId: conversationId, incomingOffer: offer)
            } else {
               Text("Incoming call error")
            }
        }
        .onAppear {
             if session.accessToken != nil {
                 connectSocket()
             }
        }
    }
    
    private func connectSocket() {
        guard let token = session.accessToken else { return }
        SocketIOManager.shared.connect(token: token)
    }
    
    private func disconnectSocket() {
        SocketIOManager.shared.disconnect()
    }
}

// -----------------------------
// MARK: - Deals Views
// -----------------------------

struct DealsListUserView: View {
    @ObservedObject var viewModel: DealsViewModel
    @Environment(\.dismiss) var dismiss
    
    private var maxDiscount: Int {
        if case .success(let deals) = viewModel.dealsState, !deals.isEmpty {
            return deals.map { $0.discountPercentage }.max() ?? 50
        }
        return 50
    }
    
    private var dealsCount: Int {
        if case .success(let deals) = viewModel.dealsState {
            return deals.count
        }
        return 0
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Limited time offers text
                    Text("Limited time offers")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    
                    // Today's Special Offers header
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: "#F59E0B"))
                            
                            Text("Today's Special Offers")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("\(dealsCount) deals available")
                            .font(.system(size: 11))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    // Deals grid
                    switch viewModel.dealsState {
                    case .loading:
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(50)
                            
                    case .success(let deals):
                        if deals.isEmpty {
                            EmptyDealsUserStateView()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], alignment: .leading, spacing: 14) {
                                ForEach(deals) { deal in
                                    NavigationLink(value: Screen.dealDetail(dealId: deal._id)) {
                                        DealUserCardView(deal: deal)
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100)
                        }
                        
                    case .error(let message):
                        ErrorDealsUserStateView(message: message) {
                            viewModel.loadDeals()
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#F59E0B"))
                        .clipShape(Circle())
                }
            }
            
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#F59E0B"))
                    
                    Text("Daily Deals")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Text("Up to \(maxDiscount)% OFF")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#F59E0B"))
                        .cornerRadius(8)
                }
            }
        }
        .refreshable {
            viewModel.loadDeals()
        }
    }
}

struct DealUserCardView: View {
    let deal: Deal
    @State private var base64Image: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with discount badge - Fixed height container
            ZStack(alignment: .topLeading) {
                // Fixed size container to prevent layout shifts
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                
                Group {
                    if let base64Image = base64Image {
                        Image(uiImage: base64Image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else if let url = URL(string: deal.image), deal.image.hasPrefix("http") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                placeholderImage
                                    .frame(height: 140)
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure:
                                placeholderImage
                                    .frame(height: 140)
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                placeholderImage
                                    .frame(height: 140)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    } else {
                        placeholderImage
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
                .frame(maxWidth: .infinity)
                .clipped()
                .onAppear {
                    loadImage()
                }
                
                // Red discount badge
                Text("-\(deal.discountPercentage)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(4)
                    .padding(8)
            }
            .frame(height: 140)
            .clipped()
            
            // Content section
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(deal.restaurantName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                // Description
                Text(deal.description)
                    .font(.system(size: 12))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Offer date box
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                        .foregroundColor(.black)
                    
                    Text("Offer: \(formatOfferDate(deal.startDate)) - \(formatOfferDate(deal.endDate))")
                        .font(.system(size: 9))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(Color(hex: "#F59E0B").opacity(0.25))
                .cornerRadius(5)
                
                // Category tags
                HStack(spacing: 6) {
                    Text(deal.category)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#F59E0B").opacity(0.25))
                        .cornerRadius(10)
                    
                    // Show BURGER tag if category is burger
                    if deal.category.lowercased().contains("burger") {
                        Text("BURGER")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#F59E0B").opacity(0.25))
                            .cornerRadius(10)
                    }
                }
                
                                // Grab Deal button - Navigation is handled by NavigationLink wrapper
                                Button(action: {}) {
                                    Text("Grab Deal")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: "#F59E0B"))
                                        .cornerRadius(8)
                                }
                                .allowsHitTesting(false) // Let NavigationLink handle the tap
            }
            .padding(10)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
        )
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private func loadImage() {
        // Si l'image est une URL HTTP/HTTPS, AsyncImage la gérera
        if deal.image.hasPrefix("http") {
            return
        }
        
        // Sinon, essayer de charger comme image base64
        var base64String = deal.image
        
        // Retirer le préfixe data:image/...;base64, si présent
        if let range = base64String.range(of: "base64,") {
            base64String = String(base64String[range.upperBound...])
        } else if base64String.hasPrefix("data:") {
            // Si c'est un data URI mais sans "base64,", chercher la virgule
            if let commaIndex = base64String.firstIndex(of: ",") {
                base64String = String(base64String[base64String.index(after: commaIndex)...])
            }
        }
        
        // Décoder l'image base64
        if let imageData = Data(base64Encoded: base64String),
           let uiImage = UIImage(data: imageData) {
            base64Image = uiImage
        }
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.15))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.4))
            )
    }
    
    private func formatOfferDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd-MM"
        displayFormatter.locale = Locale(identifier: "en_US")
        
        return displayFormatter.string(from: date)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy 'à' HH:mm"
        displayFormatter.locale = Locale(identifier: "fr_FR")
        
        return displayFormatter.string(from: date)
    }
}

struct EmptyDealsUserStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 80))
                .foregroundColor(BrandColors.TextSecondary.opacity(0.3))
            
            Text("Aucun deal disponible")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(BrandColors.TextPrimary)
            
            Text("Revenez plus tard pour découvrir nos deals")
                .font(.system(size: 14))
                .foregroundColor(BrandColors.TextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

struct ErrorDealsUserStateView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(BrandColors.Red.opacity(0.7))
            
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(BrandColors.TextPrimary)
                .multilineTextAlignment(.center)
            
            Button(action: onRetry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Réessayer")
                }
                .foregroundColor(BrandColors.TextPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(BrandColors.Yellow)
                .cornerRadius(24)
            }
        }
        .padding()
    }
}

struct DealDetailUserView: View {
    let dealId: String
    @ObservedObject var viewModel: DealsViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            BrandColors.Cream100.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch viewModel.dealDetailState {
                    case .loading:
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(50)
                        
                    case .success(let deal):
                        dealDetailContent(deal: deal)
                        
                    case .error(let message):
                        ErrorDealsUserStateView(message: message) {
                            viewModel.loadDealById(dealId)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#F59E0B"))
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            viewModel.loadDealById(dealId)
        }
    }
    
    @ViewBuilder
    private func dealDetailContent(deal: Deal) -> some View {
        VStack(spacing: 0) {
            // Image section with discount badge
            ZStack(alignment: .bottomTrailing) {
                DealDetailImageView(imageString: deal.image)
                    .frame(height: min(UIScreen.main.bounds.height * 0.4, 350))
                    .frame(maxWidth: .infinity)
                    .clipped()
                
                // Discount badge bottom right
                Text("-\(deal.discountPercentage)%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#F59E0B"))
                    .cornerRadius(8)
                    .padding(20)
            }
            
            // Content card
            VStack(alignment: .leading, spacing: 16) {
                // Restaurant name (small gray text above title)
                Text(deal.restaurantName)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                // Special Deal title
                HStack {
                    Text("Special Deal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Category tag
                    Text(deal.category)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "#F59E0B").opacity(0.2))
                        .cornerRadius(12)
                }
                
                // About this offer
                VStack(alignment: .leading, spacing: 8) {
                    Text("About this offer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(deal.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                
                // Deal duration box
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                        
                        Text("\(daysRemaining(deal.endDate)) days remaining")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Starts")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text(formatShortDate(deal.startDate))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Ends")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text(formatShortDate(deal.endDate))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "#F59E0B").opacity(0.15))
                .cornerRadius(12)
                
                // Order Now button
                if let professionalId = deal.professionalId {
                    NavigationLink(value: Screen.professionalProfile(professionalId)) {
                        Text("Order Now")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#F59E0B"))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 20)
            .background(Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
        .background(Color.white)
    }
    
    private func daysRemaining(_ endDateString: String) -> Int {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let endDate = isoFormatter.date(from: endDateString) else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(0, components.day ?? 0)
    }
    
    private func formatShortDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy"
        displayFormatter.locale = Locale(identifier: "en_US")
        
        return displayFormatter.string(from: date)
    }
    
    private var placeholderImage: some View {
        LinearGradient(
            colors: [BrandColors.Yellow, BrandColors.YellowPressed],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
        )
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy 'à' HH:mm"
        displayFormatter.locale = Locale(identifier: "fr_FR")
        
        return displayFormatter.string(from: date)
    }
}

// MARK: - Deal Detail Image View
struct DealDetailImageView: View {
    let imageString: String
    @State private var base64Image: UIImage?
    
    var body: some View {
        Group {
            if let base64Image = base64Image {
                Image(uiImage: base64Image)
                    .resizable()
                    .scaledToFill()
            } else if let url = URL(string: imageString), imageString.hasPrefix("http") {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderImage
                }
            } else {
                placeholderImage
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        // Si l'image est une URL HTTP/HTTPS, AsyncImage la gérera
        if imageString.hasPrefix("http") {
            return
        }
        
        // Sinon, essayer de charger comme image base64
        var base64String = imageString
        
        // Retirer le préfixe data:image/...;base64, si présent
        if let range = base64String.range(of: "base64,") {
            base64String = String(base64String[range.upperBound...])
        } else if base64String.hasPrefix("data:") {
            // Si c'est un data URI mais sans "base64,", chercher la virgule
            if let commaIndex = base64String.firstIndex(of: ",") {
                base64String = String(base64String[base64String.index(after: commaIndex)...])
            }
        }
        
        // Décoder l'image base64
        if let imageData = Data(base64Encoded: base64String),
           let uiImage = UIImage(data: imageData) {
            base64Image = uiImage
        }
    }
    
    private var placeholderImage: some View {
        LinearGradient(
            colors: [BrandColors.Yellow, BrandColors.YellowPressed],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            Image(systemName: "tag.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
        )
    }
}

// MARK: - Preview
#Preview {
    AppNavigation()
}
