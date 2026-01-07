import Foundation
import Combine

// MARK: - Notification ViewModel
@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationDTO] = []
    @Published var unreadNotifications: [NotificationDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    
    private let repository = NotificationRepository.shared
    
    // MARK: - Load User Notifications
    func loadUserNotifications(userId: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getUserNotifications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let notifications):
                    // Sort by createdAt (newest first)
                    self.notifications = notifications.sorted { notification1, notification2 in
                        guard let date1 = self.parseDate(notification1.createdAt),
                              let date2 = self.parseDate(notification2.createdAt) else {
                            return false
                        }
                        return date1 > date2
                    }
                    self.updateUnreadCount()
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to load notifications: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Load Professional Notifications
    func loadProfessionalNotifications(professionalId: String) {
        isLoading = true
        errorMessage = nil
        
        repository.getProfessionalNotifications(professionalId: professionalId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                
                switch result {
                case .success(let notifications):
                    // Sort by createdAt (newest first)
                    self.notifications = notifications.sorted { notification1, notification2 in
                        guard let date1 = self.parseDate(notification1.createdAt),
                              let date2 = self.parseDate(notification2.createdAt) else {
                            return false
                        }
                        return date1 > date2
                    }
                    self.updateUnreadCount()
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("❌ Failed to load notifications: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Load Unread Notifications
    func loadUnreadUserNotifications(userId: String) {
        repository.getUnreadUserNotifications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let notifications):
                    self.unreadNotifications = notifications
                    self.unreadCount = notifications.count
                    
                case .failure(let error):
                    print("❌ Failed to load unread notifications: \(error.localizedDescription)")
                    self.unreadCount = 0
                }
            }
        }
    }
    
    // MARK: - Load Unread Professional Notifications
    func loadUnreadProfessionalNotifications(professionalId: String) {
        repository.getUnreadProfessionalNotifications(professionalId: professionalId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let notifications):
                    self.unreadNotifications = notifications
                    self.unreadCount = notifications.count
                    
                case .failure(let error):
                    print("❌ Failed to load unread notifications: \(error.localizedDescription)")
                    self.unreadCount = 0
                }
            }
        }
    }
    
    // MARK: - Mark Notification as Read
    func markAsRead(notificationId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        repository.markAsRead(notificationId: notificationId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // Update local state
                    if let index = self.notifications.firstIndex(where: { $0._id == notificationId }) {
                        var updatedNotification = self.notifications[index]
                        // Create a new NotificationDTO with isRead = true
                        // Since NotificationDTO is a struct, we need to update it
                        // For now, we'll reload notifications
                        self.updateUnreadCount()
                        completion(true)
                    } else {
                        completion(true)
                    }
                    
                case .failure(let error):
                    print("❌ Failed to mark notification as read: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Mark All as Read
    func markAllAsReadUser(userId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        repository.markAllAsReadUser(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // Update all notifications to read
                    self.notifications = self.notifications.map { notification in
                        var updated = notification
                        // Since NotificationDTO is immutable, we'll reload
                        self.loadUserNotifications(userId: userId)
                        completion(true)
                        return updated
                    }
                    self.updateUnreadCount()
                    
                case .failure(let error):
                    print("❌ Failed to mark all as read: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Mark All as Read (Professional)
    func markAllAsReadProfessional(professionalId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        repository.markAllAsReadProfessional(professionalId: professionalId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.loadProfessionalNotifications(professionalId: professionalId)
                    self.updateUnreadCount()
                    completion(true)
                    
                case .failure(let error):
                    print("❌ Failed to mark all as read: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete Notification
    func deleteNotification(notificationId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        repository.deleteNotification(notificationId: notificationId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // Remove from local state
                    self.notifications.removeAll { $0._id == notificationId }
                    self.updateUnreadCount()
                    completion(true)
                    
                case .failure(let error):
                    print("❌ Failed to delete notification: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete All Notifications
    func deleteAllUserNotifications(userId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        repository.deleteAllUserNotifications(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.notifications = []
                    self.unreadCount = 0
                    completion(true)
                    
                case .failure(let error):
                    print("❌ Failed to delete all notifications: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Delete All Professional Notifications
    func deleteAllProfessionalNotifications(professionalId: String, completion: @escaping (Bool) -> Void = { _ in }) {
        repository.deleteAllProfessionalNotifications(professionalId: professionalId) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success:
                    self.notifications = []
                    self.unreadCount = 0
                    completion(true)
                    
                case .failure(let error):
                    print("❌ Failed to delete all notifications: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Refresh Notifications
    func refreshUserNotifications(userId: String) {
        loadUserNotifications(userId: userId)
        loadUnreadUserNotifications(userId: userId)
    }
    
    func refreshProfessionalNotifications(professionalId: String) {
        loadProfessionalNotifications(professionalId: professionalId)
        loadUnreadProfessionalNotifications(professionalId: professionalId)
    }
    
    // MARK: - Helper Methods
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    // MARK: - Format Date for Display
    func formatDate(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else {
            return dateString
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: date)?.contains(now) ?? false {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Navigation Helpers
    
    /// Get the appropriate navigation destination for a notification
    func getNavigationDestination(for notification: NotificationDTO) -> Screen? {
        switch notification.type {
        // Order notifications
        case .orderCreated, .orderConfirmed, .orderCompleted, .orderCancelled, .orderRefused, .paymentSuccess, .paymentFailed:
            if let orderId = notification.orderId?._id {
                return .orderDetail(orderId)
            }
            
        // Event notifications
        case .eventCreated:
            if let eventId = notification.eventId?._id {
                // Navigate to event list (you can create a specific event detail screen later)
                return .userEventList
            }
            
        // Post notifications
        case .postCreated, .postLiked, .postCommented:
            if let postId = notification.postId?._id {
                return .postDetails(postId)
            }
            
        // Deal notifications
        case .dealCreated:
            if let dealId = notification.dealId?._id {
                return .dealDetail(dealId: dealId)
            }
            
        // Reclamation notifications
        case .reclamationCreated, .reclamationUpdated, .reclamationResponded:
            if let reclamationId = notification.reclamationId?._id {
                return .reclamationDetail(reclamationId: reclamationId)
            }
            
        // Chat notifications
        case .messageReceived, .conversationStarted:
            if let conversationId = notification.conversationId?._id {
                // Extract conversation title from metadata or use default
                let title = notification.metadata?.senderName ?? "Chat"
                return .chatThread(conversationId: conversationId, title: title)
            }
        }
        
        return nil
    }
    
    /// Get the entity ID from a notification
    func getEntityId(for notification: NotificationDTO) -> String? {
        switch notification.type {
        case .orderCreated, .orderConfirmed, .orderCompleted, .orderCancelled, .orderRefused, .paymentSuccess, .paymentFailed:
            return notification.orderId?._id
        case .eventCreated:
            return notification.eventId?._id
        case .postCreated, .postLiked, .postCommented:
            return notification.postId?._id
        case .dealCreated:
            return notification.dealId?._id
        case .reclamationCreated, .reclamationUpdated, .reclamationResponded:
            return notification.reclamationId?._id
        case .messageReceived, .conversationStarted:
            return notification.conversationId?._id
        }
    }
    
    /// Get a user-friendly subtitle for the notification (metadata preview)
    func getNotificationSubtitle(for notification: NotificationDTO) -> String? {
        guard let metadata = notification.metadata else { return nil }
        
        switch notification.type {
        case .orderCreated, .orderConfirmed, .orderCompleted, .orderCancelled, .orderRefused:
            if let totalPrice = metadata.totalPrice {
                return String(format: "Total: $%.2f", totalPrice)
            }
        case .eventCreated:
            if let eventDate = metadata.eventDate {
                return "Date: \(eventDate)"
            }
        case .postCreated:
            return metadata.postCaption
        case .postLiked, .postCommented:
            return metadata.postOwnerName
        case .dealCreated:
            if let discount = metadata.dealDiscount {
                return "Discount: \(discount)"
            }
        case .reclamationCreated, .reclamationUpdated, .reclamationResponded:
            return metadata.reclamationStatus
        case .messageReceived:
            return metadata.messagePreview
        case .conversationStarted:
            return metadata.senderName
        case .paymentSuccess, .paymentFailed:
            if let totalPrice = metadata.totalPrice {
                return String(format: "$%.2f", totalPrice)
            }
        }
        
        return nil
    }
}

