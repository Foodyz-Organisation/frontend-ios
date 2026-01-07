import SwiftUI

struct ProfessionalNotificationScreen: View {
    @Binding var path: NavigationPath
    @State private var showingDrawer = false
    @State private var showNotifications = false // Not used here but needed for TopBar binding
    @StateObject private var viewModel = NotificationViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                FoodyzTopBar(
                    path: $path,
                    professionalId: TokenManager.shared.getUserId() ?? "",
                    openDrawer: { withAnimation { showingDrawer = true } },
                    onProfileClick: {
                        if let proId = TokenManager.shared.getUserId() {
                            path.append(Screen.professionalProfile(proId))
                        }
                    },
                    onLocationClick: {
                        path.append(Screen.allUsersTracking)
                    }
                )
                
                // Content
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                        Text("Loading notifications...")
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No notifications yet")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            HStack {
                                Text("Notifications")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                if viewModel.unreadCount > 0 {
                                    Button(action: markAllAsRead) {
                                        Text("Mark all as read")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // List
                            VStack(spacing: 0) {
                                ForEach(viewModel.notifications) { notification in
                                    NotificationItemView(
                                        notification: notification,
                                        onTap: {
                                            // Mark as read
                                            if !notification.isRead {
                                                viewModel.markAsRead(notificationId: notification._id) { success in
                                                    if success {
                                                        // Reload notifications to update UI
                                                        if let professionalId = TokenManager.shared.getUserId() {
                                                            viewModel.loadProfessionalNotifications(professionalId: professionalId)
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            // Navigate to entity detail screen
                                            if let destination = viewModel.getNavigationDestination(for: notification) {
                                                path.append(destination)
                                            }
                                        }
                                    )
                                    Divider()
                                }
                            }
                            .padding(.bottom, 100) // Space for bottom bar
                        }
                        .padding(.top, 10)
                    }
                }
            }
            
            // Bottom Bar
            ProfessionalBottomBar(
                path: $path,
                selectedTab: "notifications",
                openDrawer: { withAnimation { showingDrawer = true } }
            )
            
            // Drawer Overlay
            if showingDrawer {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showingDrawer = false } }
                
                ProfessionalDrawer(
                    onCloseDrawer: { withAnimation { showingDrawer = false } },
                    navigateTo: { route in
                        if route == "logout" {
                            path.removeLast(path.count)
                            path.append(Screen.login)
                            TokenManager.shared.clearAllData()
                        } else if route == "profile" {
                            if let proId = TokenManager.shared.getUserId() {
                                path.append(Screen.professionalProfile(proId))
                            }
                        }
                        withAnimation { showingDrawer = false }
                    }
                )
                .transition(.move(edge: .trailing))
                .animation(.easeInOut, value: showingDrawer)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let professionalId = TokenManager.shared.getUserId() {
                viewModel.loadProfessionalNotifications(professionalId: professionalId)
            }
        }
    }
    
    private func markAllAsRead() {
        if let professionalId = TokenManager.shared.getUserId() {
            viewModel.markAllAsReadProfessional(professionalId: professionalId) { success in
                if success {
                    viewModel.loadProfessionalNotifications(professionalId: professionalId)
                }
            }
        }
    }
}

