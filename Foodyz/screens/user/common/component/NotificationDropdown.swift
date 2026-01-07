import SwiftUI

// MARK: - Dynamic Notification Dropdown Component
struct NotificationDropdown: View {
    @Binding var showNotifications: Bool
    @StateObject private var viewModel = NotificationViewModel()
    
    let userId: String?
    let professionalId: String?
    var onNotificationTap: ((NotificationDTO) -> Void)? = nil
    var onViewAll: (() -> Void)? = nil
    
    var body: some View {
        // Only render the button - dropdown will be handled by parent overlay
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showNotifications.toggle()
            }
        }) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(TopAppBarColors.darkGray)
                    .frame(width: 36, height: 36)
                    .background(TopAppBarColors.lightGray)
                    .clipShape(Circle())
                
                // Badge with count
                if viewModel.unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        
                        Text("\(viewModel.unreadCount > 99 ? "99+" : "\(viewModel.unreadCount)")")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 6, y: -6)
                } else {
                    // Small dot indicator if there are notifications but all read
                    if !viewModel.notifications.isEmpty {
                        Circle()
                            .fill(TopAppBarColors.notificationBadge)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                            .offset(x: 6, y: -6)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Load unread count for badge
            if let userId = userId {
                viewModel.loadUnreadUserNotifications(userId: userId)
            } else if let professionalId = professionalId {
                viewModel.loadUnreadProfessionalNotifications(professionalId: professionalId)
            }
        }
    }
}

// MARK: - Notification Dropdown Content (Separate component for overlay)
struct NotificationDropdownContent: View {
    @Binding var showNotifications: Bool
    @StateObject private var viewModel = NotificationViewModel()
    
    let userId: String?
    let professionalId: String?
    var onNotificationTap: ((NotificationDTO) -> Void)? = nil
    var onViewAll: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if showNotifications {
                VStack(alignment: .leading, spacing: 0) {
                    // Professional Header with Gradient
                    ZStack {
                        // Gradient Background
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.97, blue: 0.94),
                                Color.white
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        HStack(alignment: .center, spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                TopAppBarColors.primary.opacity(0.2),
                                                TopAppBarColors.primary.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(TopAppBarColors.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(TopAppBarColors.darkGray)
                                
                                if viewModel.unreadCount > 0 {
                                    Text("\(viewModel.unreadCount) unread")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gray)
                                } else if !viewModel.notifications.isEmpty {
                                    Text("All caught up")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Spacer()
                            
                            // Badge
                            if viewModel.unreadCount > 0 {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(viewModel.unreadCount > 99 ? "99+" : "\(viewModel.unreadCount)")")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            // Close Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showNotifications = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray.opacity(0.6))
                                    .font(.system(size: 22))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                    }
                    
                    // Divider with shadow
                    Divider()
                        .background(Color.gray.opacity(0.1))
                        .shadow(color: Color.black.opacity(0.05), radius: 1, y: 1)
                    
                    // Notifications List
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: TopAppBarColors.primary))
                                .scaleEffect(1.2)
                            Text("Loading notifications...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if viewModel.notifications.isEmpty {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "bell.slash.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.gray.opacity(0.4))
                            }
                            
                            VStack(spacing: 4) {
                                Text("No notifications")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(TopAppBarColors.darkGray)
                                
                                Text("You're all caught up!")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.notifications.prefix(5).enumerated()), id: \.element.id) { index, notification in
                                    NotificationItemView(
                                        notification: notification,
                                        onTap: {
                                            // Mark as read when tapped
                                            if !notification.isRead {
                                                viewModel.markAsRead(notificationId: notification._id)
                                            }
                                            onNotificationTap?(notification)
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                showNotifications = false
                                            }
                                        }
                                    )
                                    
                                    if index < min(4, viewModel.notifications.count - 1) {
                                        Divider()
                                            .padding(.leading, 72)
                                            .background(Color.gray.opacity(0.1))
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 420)
                    }
                    
                    // Professional Footer
                    if !viewModel.notifications.isEmpty {
                        Divider()
                            .background(Color.gray.opacity(0.1))
                        
                        HStack(spacing: 16) {
                            if viewModel.unreadCount > 0 {
                                Button(action: {
                                    if let userId = userId {
                                        viewModel.markAllAsReadUser(userId: userId)
                                    } else if let professionalId = professionalId {
                                        viewModel.markAllAsReadProfessional(professionalId: professionalId)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 14))
                                        Text("Mark all read")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(TopAppBarColors.primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(TopAppBarColors.primary.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showNotifications = false
                                onViewAll?()
                            }) {
                                HStack(spacing: 6) {
                                    Text("View All")
                                        .font(.system(size: 13, weight: .semibold))
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    LinearGradient(
                                        colors: [TopAppBarColors.primary, TopAppBarColors.primary.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.99, green: 0.99, blue: 0.99))
                    }
                }
                .frame(width: 340)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 15)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    // Arrow pointer pointing to bell icon
                    Triangle()
                        .fill(Color.white)
                        .frame(width: 16, height: 12)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -1)
                        .offset(x: 130, y: -6)
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        if let userId = userId {
            viewModel.loadUnreadUserNotifications(userId: userId)
            viewModel.loadUserNotifications(userId: userId)
        } else if let professionalId = professionalId {
            viewModel.loadUnreadProfessionalNotifications(professionalId: professionalId)
            viewModel.loadProfessionalNotifications(professionalId: professionalId)
        }
    }
}

// MARK: - Professional Notification Item View
struct NotificationItemView: View {
    let notification: NotificationDTO
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Professional Icon with Gradient
                ZStack {
                    // Background Circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    hexColor(notification.type.color),
                                    hexColor(notification.type.color).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: hexColor(notification.type.color).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // Icon
                    Image(systemName: notification.type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                // Content Section
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            // Title with unread indicator
                            HStack(spacing: 6) {
                                Text(notification.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(TopAppBarColors.darkGray)
                                    .lineLimit(1)
                                
                                if !notification.isRead {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.red, Color.red.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 8, height: 8)
                                }
                            }
                            
                            // Message
                            Text(notification.message)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(.gray)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    
                    // Order Info & Time Row
                    HStack(spacing: 12) {
                        if let orderId = notification.orderId {
                            HStack(spacing: 4) {
                                Image(systemName: "cart.fill")
                                    .font(.system(size: 10))
                                Text("Order #\(orderId._id.prefix(8))")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(TopAppBarColors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(TopAppBarColors.primary.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                        
                        Text(formatTime(notification.createdAt))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Group {
                    if !notification.isRead {
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.97, blue: 0.95),
                                Color.white
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.white
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return dateFormatter.string(from: date)
        }
    }
}

// MARK: - Triangle Shape for Arrow Pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Color Helper
private func hexColor(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
        (r, g, b) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
        (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    default:
        return TopAppBarColors.primary
    }
    return Color(
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue: Double(b) / 255
    )
}

