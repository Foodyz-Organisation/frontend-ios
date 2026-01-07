import SwiftUI

struct UserNotificationScreen: View {
    @Binding var path: NavigationPath
    @StateObject private var viewModel = NotificationViewModel()
    @EnvironmentObject private var session: SessionManager
    
    // Bottom Bar Navigation State
    @State private var selectedTab = "notifications"
    
    // Drawer Mock (If user has drawer, though mainly for navigation consistency)
    @State private var showingDrawer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        path.removeLast()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(TopAppBarColors.darkGray)
                    }
                    
                    Spacer()
                    
                    Text("Notifications")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(TopAppBarColors.darkGray)
                    
                    Spacer()
                    
                    // Invisible button for centering
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .zIndex(1)
                
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
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationItemView(
                                    notification: notification,
                                    onTap: {
                                        // Mark as read
                                        if !notification.isRead {
                                            viewModel.markAsRead(notificationId: notification._id) { success in
                                                if success {
                                                    // Reload notifications to update UI
                                                    if let userId = TokenManager.shared.getUserId() {
                                                        viewModel.loadUserNotifications(userId: userId)
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
                        .padding(.vertical)
                        .padding(.bottom, 100) // Space for bottom bar
                    }
                }
            }
            
            // Bottom Bar
            UserBottomBar(
                selectedTab: $selectedTab,
                onTabSelect: { tab in
                    if tab == "home" {
                        // Navigate back to home root or append home?
                        // Usually clean navigation to root home
                        // For now simple jump
                       navigateToHome()
                    } else if tab == "chat" {
                         path.append(Screen.chatList(role: .user))
                    }
                },
                onReels: { /* Navigate */ },
                onTrending: { /* Navigate */ },
                onChat: {
                    path.append(Screen.chatList(role: .user))
                },
                onMenu: {
                    // Already here or open drawer if needed
                    // For now, since we are in notifications, maybe menu does nothing or opens drawer
                    // user request was just to fix validation error
                }
            )
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let userId = TokenManager.shared.getUserId() {
                viewModel.loadUserNotifications(userId: userId)
            }
        }
    }
    
    private func navigateToHome() {
        // Pop until we find home or reset
        // Since we are in a stack, simplest is to pop back if we came from home,
        // but if we came from chat -> notification, we might want to pop to root.
        // For this simplified logic, let's assume root is home or we push home (not ideal for stack).
        // Better:
        path.removeLast(path.count) // Go to root (HomeUserScreen)
    }
}
