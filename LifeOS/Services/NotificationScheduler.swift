import Foundation
import UserNotifications

final class NotificationScheduler {
    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let identifierPrefix = "lifeos."

    init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current
    ) {
        self.center = center
        self.calendar = calendar
    }

    func scheduleReminders(
        for plan: DailyPlan,
        jobApplications: [JobApplication],
        preferences: ReminderPreferences
    ) async throws -> Int {
        let settings = await center.notificationSettings()
        guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else {
            throw AppleIntegrationError.permissionRequired("Notifications")
        }

        await removeLifeOSReminders()
        var scheduledCount = 0

        for block in plan.scheduleBlocks {
            guard let startDate = block.startDate else { continue }
            let reminderDate = startDate.addingTimeInterval(
                -Double(preferences.focusLeadMinutes * 60)
            )
            guard reminderDate > Date(),
                  !preferences.isInsideQuietHours(reminderDate, calendar: calendar)
            else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Focus block in \(preferences.focusLeadMinutes) minutes"
            content.body = "\(block.title): \(block.detail)"
            content.sound = .default

            try await addNotification(
                identifier: "\(identifierPrefix)block.\(block.id.uuidString)",
                content: content,
                date: reminderDate
            )
            scheduledCount += 1
        }

        for application in jobApplications.prefix(5) {
            let deadlineDay = calendar.startOfDay(for: application.deadline)
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: deadlineDay),
                  let reminderDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: dayBefore),
                  reminderDate > Date(),
                  !preferences.isInsideQuietHours(reminderDate, calendar: calendar)
            else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Job deadline tomorrow"
            content.body = "\(application.company) — \(application.nextAction)"
            content.sound = .default

            try await addNotification(
                identifier: "\(identifierPrefix)job.\(application.id.uuidString)",
                content: content,
                date: reminderDate
            )
            scheduledCount += 1
        }

        if let reviewDate = nextEveningReviewDate(hour: preferences.eveningReviewHour),
           !preferences.isInsideQuietHours(reviewDate, calendar: calendar) {
            let content = UNMutableNotificationContent()
            content.title = "Close the loop on today"
            content.body = "Take one minute to review your plan and set up tomorrow."
            content.sound = .default

            try await addNotification(
                identifier: "\(identifierPrefix)daily-review",
                content: content,
                date: reviewDate
            )
            scheduledCount += 1
        }

        return scheduledCount
    }

    func removeLifeOSReminders() async {
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func addNotification(
        identifier: String,
        content: UNNotificationContent,
        date: Date
    ) async throws {
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    private func nextEveningReviewDate(hour: Int) -> Date? {
        let todayReview = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: Date())
        guard let todayReview else { return nil }
        if todayReview > Date() { return todayReview }
        return calendar.date(byAdding: .day, value: 1, to: todayReview)
    }
}
