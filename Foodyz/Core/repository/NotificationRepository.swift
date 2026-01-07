import Foundation

// MARK: - Notification Repository
class NotificationRepository {
    static let shared = NotificationRepository()
    private let api = NotificationAPI.shared
    
    private init() {}
    
    // MARK: - Get User Notifications
    func getUserNotifications(
        userId: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.getUserNotifications(userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Get Professional Notifications
    func getProfessionalNotifications(
        professionalId: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.getProfessionalNotifications(professionalId: professionalId, token: token, completion: completion)
    }
    
    // MARK: - Get Unread User Notifications
    func getUnreadUserNotifications(
        userId: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.getUnreadUserNotifications(userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Get Unread Professional Notifications
    func getUnreadProfessionalNotifications(
        professionalId: String,
        completion: @escaping (Result<[NotificationDTO], APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.getUnreadProfessionalNotifications(professionalId: professionalId, token: token, completion: completion)
    }
    
    // MARK: - Mark Notification as Read
    func markAsRead(
        notificationId: String,
        completion: @escaping (Result<MarkAsReadResponse, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.markAsRead(notificationId: notificationId, token: token, completion: completion)
    }
    
    // MARK: - Mark All as Read (User)
    func markAllAsReadUser(
        userId: String,
        completion: @escaping (Result<MarkAsReadResponse, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.markAllAsReadUser(userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Mark All as Read (Professional)
    func markAllAsReadProfessional(
        professionalId: String,
        completion: @escaping (Result<MarkAsReadResponse, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.markAllAsReadProfessional(professionalId: professionalId, token: token, completion: completion)
    }
    
    // MARK: - Delete Notification
    func deleteNotification(
        notificationId: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.deleteNotification(notificationId: notificationId, token: token, completion: completion)
    }
    
    // MARK: - Delete All User Notifications
    func deleteAllUserNotifications(
        userId: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.deleteAllUserNotifications(userId: userId, token: token, completion: completion)
    }
    
    // MARK: - Delete All Professional Notifications
    func deleteAllProfessionalNotifications(
        professionalId: String,
        completion: @escaping (Result<Void, APIError>) -> Void
    ) {
        guard let token = TokenManager.shared.getAccessToken() else {
            return completion(.failure(.unauthorized))
        }
        api.deleteAllProfessionalNotifications(professionalId: professionalId, token: token, completion: completion)
    }
}

