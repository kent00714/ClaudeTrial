import Foundation
import UserNotifications

@MainActor
class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current notification authorization status
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Destination Reminders
    
    /// Schedule a notification reminder for a destination
    func scheduleDestinationReminder(
        for destination: TripDestination,
        tripName: String,
        minutesBefore: Int = 30
    ) async {
        guard let scheduledTime = destination.plannedArrival else {
            print("No scheduled time for destination, skipping notification")
            return
        }
        
        // Cancel any existing notification for this destination
        cancelReminder(for: destination.id)
        
        // Calculate trigger time
        let triggerDate = scheduledTime.addingTimeInterval(-Double(minutesBefore * 60))
        
        // Don't schedule if trigger time is in the past
        guard triggerDate > Date() else {
            print("Trigger time is in the past, skipping notification")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Destination"
        content.body = "Reminder: \(destination.name) is scheduled in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "DESTINATION_REMINDER"
        content.userInfo = [
            "destinationId": destination.id.uuidString,
            "tripName": tripName
        ]
        
        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: destination.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification for \(destination.name) at \(triggerDate)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    /// Schedule a notification reminder for a destination (alternate signature for flexibility)
    func scheduleDestinationReminder(
        destinationId: UUID,
        destinationName: String,
        scheduledTime: Date,
        minutesBefore: Int = 30
    ) async {
        // Cancel any existing notification for this destination
        cancelReminder(for: destinationId)
        
        // Calculate trigger time
        let triggerDate = scheduledTime.addingTimeInterval(-Double(minutesBefore * 60))
        
        // Don't schedule if trigger time is in the past
        guard triggerDate > Date() else {
            print("Trigger time is in the past, skipping notification")
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Destination"
        content.body = "Reminder: \(destinationName) is scheduled in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "DESTINATION_REMINDER"
        content.userInfo = ["destinationId": destinationId.uuidString]
        
        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: destinationId.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        do {
            try await notificationCenter.add(request)
            print("Scheduled notification for \(destinationName) at \(triggerDate)")
        } catch {
            print("Error scheduling notification: \(error)")
        }
    }
    
    /// Cancel a reminder for a specific destination
    func cancelReminder(for destinationId: UUID) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [destinationId.uuidString])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [destinationId.uuidString])
    }
    
    /// Cancel all pending reminders
    func cancelAllReminders() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Get all pending notification requests
    func getPendingReminders() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle the notification tap here
        let userInfo = response.notification.request.content.userInfo
        
        if let destinationIdString = userInfo["destinationId"] as? String,
           let _ = UUID(uuidString: destinationIdString) {
            // Navigate to the destination or trip detail view
            print("User tapped notification for destination: \(destinationIdString)")
        }
        
        completionHandler()
    }
}
