import Foundation
import UserNotifications

// MARK: - Notification Service Protocol

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func scheduleDestinationReminder(for destination: TripDestination, tripName: String, minutesBefore: Int) async
    func cancelReminder(for destinationId: UUID)
    func cancelAllReminders(for tripId: UUID)
    func updateReminders(for trip: Trip, minutesBefore: Int) async
}

// MARK: - Notification Service

class NotificationService: NotificationServiceProtocol {

    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    private let reminderMinutesKey = "notification_reminder_minutes"
    private let notificationsEnabledKey = "notifications_enabled"

    // MARK: - Settings

    var reminderMinutes: Int {
        get { defaults.integer(forKey: reminderMinutesKey) == 0 ? 10 : defaults.integer(forKey: reminderMinutesKey) }
        set { defaults.set(newValue, forKey: reminderMinutesKey) }
    }

    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: notificationsEnabledKey) }
        set { defaults.set(newValue, forKey: notificationsEnabledKey) }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationsEnabled = granted
            return granted
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    /// Schedule a reminder for arriving at a destination
    func scheduleDestinationReminder(for destination: TripDestination, tripName: String, minutesBefore: Int = 10) async {
        guard let arrivalTime = destination.plannedArrival else { return }

        // Calculate notification time (X minutes before arrival)
        guard let notificationTime = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: arrivalTime) else {
            return
        }

        // Don't schedule if time is in the past
        guard notificationTime > Date() else { return }

        // Create arrival notification
        let arrivalContent = UNMutableNotificationContent()
        arrivalContent.title = "Upcoming: \(destination.name)"
        arrivalContent.body = "You should leave in \(minutesBefore) minutes to arrive at \(destination.formattedArrivalTime ?? "scheduled time")."
        arrivalContent.sound = .default
        arrivalContent.categoryIdentifier = "TRIP_REMINDER"
        arrivalContent.userInfo = [
            "destinationId": destination.id.uuidString,
            "tripName": tripName,
            "type": "arrival"
        ]

        let arrivalComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let arrivalTrigger = UNCalendarNotificationTrigger(dateMatching: arrivalComponents, repeats: false)

        let arrivalRequest = UNNotificationRequest(
            identifier: "arrival_\(destination.id.uuidString)",
            content: arrivalContent,
            trigger: arrivalTrigger
        )

        do {
            try await center.add(arrivalRequest)
            print("Scheduled arrival reminder for \(destination.name) at \(notificationTime)")
        } catch {
            print("Failed to schedule arrival notification: \(error)")
        }

        // Schedule departure notification if departure time is set
        if let departureTime = destination.plannedDeparture {
            guard let departureNotificationTime = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: departureTime) else {
                return
            }

            guard departureNotificationTime > Date() else { return }

            let departureContent = UNMutableNotificationContent()
            departureContent.title = "Time to Leave: \(destination.name)"
            departureContent.body = "Get ready to depart in \(minutesBefore) minutes."
            departureContent.sound = .default
            departureContent.categoryIdentifier = "TRIP_REMINDER"
            departureContent.userInfo = [
                "destinationId": destination.id.uuidString,
                "tripName": tripName,
                "type": "departure"
            ]

            let departureComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: departureNotificationTime)
            let departureTrigger = UNCalendarNotificationTrigger(dateMatching: departureComponents, repeats: false)

            let departureRequest = UNNotificationRequest(
                identifier: "departure_\(destination.id.uuidString)",
                content: departureContent,
                trigger: departureTrigger
            )

            do {
                try await center.add(departureRequest)
                print("Scheduled departure reminder for \(destination.name) at \(departureNotificationTime)")
            } catch {
                print("Failed to schedule departure notification: \(error)")
            }
        }
    }

    /// Cancel reminders for a specific destination
    func cancelReminder(for destinationId: UUID) {
        let identifiers = [
            "arrival_\(destinationId.uuidString)",
            "departure_\(destinationId.uuidString)"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled reminders for destination \(destinationId)")
    }

    /// Cancel all reminders for a trip
    func cancelAllReminders(for tripId: UUID) {
        center.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(tripId.uuidString) }
                .map { $0.identifier }
            self.center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }

    /// Update all reminders for a trip
    func updateReminders(for trip: Trip, minutesBefore: Int = 10) async {
        // Cancel existing reminders for all destinations
        for destination in trip.destinations {
            cancelReminder(for: destination.id)
        }

        // Schedule new reminders
        for destination in trip.destinations where destination.hasScheduledTime {
            await scheduleDestinationReminder(for: destination, tripName: trip.name, minutesBefore: minutesBefore)
        }
    }

    // MARK: - Notification Categories

    func registerNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_TRIP",
            title: "View Trip",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_5MIN",
            title: "Remind in 5 min",
            options: []
        )

        let tripCategory = UNNotificationCategory(
            identifier: "TRIP_REMINDER",
            actions: [viewAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([tripCategory])
    }

    // MARK: - Debug Helpers

    func listPendingNotifications() async {
        let requests = await center.pendingNotificationRequests()
        print("Pending notifications (\(requests.count)):")
        for request in requests {
            print("  - \(request.identifier): \(request.content.title)")
        }
    }
}

// MARK: - Trip Extension for Notifications

extension Trip {
    /// Schedule notifications for all destinations with times
    func scheduleAllNotifications(minutesBefore: Int = 10) async {
        let service = NotificationService.shared
        await service.updateReminders(for: self, minutesBefore: minutesBefore)
    }

    /// Cancel all notifications for this trip
    func cancelAllNotifications() {
        let service = NotificationService.shared
        for destination in destinations {
            service.cancelReminder(for: destination.id)
        }
    }
}
