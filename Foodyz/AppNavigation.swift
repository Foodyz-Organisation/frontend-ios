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

    var body: some View {
        NavigationStack(path: $path) {
            // Splash Screen
            SplashView(onFinished: { path.append(Screen.login) })

            // Navigation Destinations
            .navigationDestination(for: Screen.self) { screen in
                let currentProId = sessionManager.userId ?? ""
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
                            connectSocket()
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
                            case "login":
                                disconnectSocket()
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
                                    path.append(Screen.myProfile)
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
                            .environmentObject(cartViewModel)
                    
                case .orderConfirmation(let professionalId):
                    OrderConfirmationScreen(
                                cartViewModel: cartViewModel,
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
                        },
                        onReclamationClick: { orderId in
                            path.append(Screen.createReclamation(orderId: orderId))
                        }
                    )

                case .chatList(let role):
                    ChatListView(role: role) { conversation, resolvedTitle in
                        path.append(Screen.chatThread(conversationId: conversation.id, title: resolvedTitle))
                    }

                case .chatThread(let conversationId, let title):
                    ChatDetailView(conversationId: conversationId, title: title)

                        case .myProfile:
                            MyProfileView()
                
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
                    HomeProfessionalView(path: $path, professionalId: currentProId)
                            
                case .menu:
                            MenuItemManagementScreen(
                                viewModel: menuVM,
                                             professionalId: currentProId,
                                path: $path
                            )
                            
                        case .createMenuItem(_):
                            CreateMenuItemScreen(
                                viewModel: menuVM,
                                         professionalId: currentProId,
                                path: $path
                            )
                            
                case .editMenuItem(let navItem):
                    if let itemId = navItem.itemId {
                                ItemDetailsView(
                                    viewModel: menuVM,
                                    itemId: itemId,
                                    professionalId: navItem.professionalId
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
    
    var body: some View {
        ZStack {
            BrandColors.Cream100.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    switch viewModel.dealsState {
                    case .loading:
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding(50)
                            
                    case .success(let deals):
                        if deals.isEmpty {
                            EmptyDealsUserStateView()
                        } else {
                            ForEach(deals) { deal in
                                NavigationLink(value: Screen.dealDetail(dealId: deal._id)) {
                                    DealUserCardView(deal: deal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                    case .error(let message):
                        ErrorDealsUserStateView(message: message) {
                            viewModel.loadDeals()
                        }
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Daily Deals")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            viewModel.loadDeals()
        }
    }
}

struct DealUserCardView: View {
    let deal: Deal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            if let url = URL(string: deal.image) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderImage
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()
            } else {
                placeholderImage
            }
            
                // Content
            VStack(alignment: .leading, spacing: 12) {
                DealStatusBadge(isActive: deal.isActive)
                
                Text(deal.restaurantName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(BrandColors.TextPrimary)
                    .lineLimit(2)
                
                Text(deal.description)
                    .font(.system(size: 14))
                    .foregroundColor(BrandColors.TextSecondary)
                    .lineLimit(2)
                
                Divider()
                    .background(BrandColors.Cream200)
                
                DealInfoRow(icon: "tag", text: deal.category)
                DealInfoRow(icon: "calendar", text: "Expire: \(formatDate(deal.endDate))")
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var placeholderImage: some View {
        LinearGradient(
            colors: [BrandColors.Yellow, BrandColors.YellowPressed],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 180)
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
    
    var body: some View {
        ZStack {
            BrandColors.Cream100.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                .padding()
            }
        }
        .navigationTitle("Détails du Deal")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadDealById(dealId)
        }
    }
    
    @ViewBuilder
    private func dealDetailContent(deal: Deal) -> some View {
        // Image
        if let url = URL(string: deal.image) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholderImage
            }
            .frame(height: 300)
            .frame(maxWidth: .infinity)
            .clipped()
            .cornerRadius(16)
        } else {
            placeholderImage
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
        }
        
            // Content
        VStack(alignment: .leading, spacing: 16) {
            DealStatusBadge(isActive: deal.isActive)
            
            Text(deal.restaurantName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(BrandColors.TextPrimary)
            
            Text(deal.description)
                .font(.system(size: 16))
                .foregroundColor(BrandColors.TextSecondary)
                .lineSpacing(4)
            
            Divider()
                .background(BrandColors.Cream200)
            
            DetailInfoCard(icon: "tag.fill", title: "Catégorie", value: deal.category)
            DetailInfoCard(icon: "calendar", title: "Date de début", value: formatDate(deal.startDate))
            DetailInfoCard(icon: "calendar", title: "Date de fin", value: formatDate(deal.endDate))
            DetailInfoCard(icon: "info.circle", title: "Statut", value: deal.isActive ? "Actif" : "Inactif")
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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

// MARK: - Preview
#Preview {
    AppNavigation()
}
