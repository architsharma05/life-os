import EventKit
import Foundation

enum AppleIntegrationError: LocalizedError {
    case permissionRequired(String)
    case noWritableCalendar

    var errorDescription: String? {
        switch self {
        case .permissionRequired(let service):
            return "Connect \(service) in Settings before using this feature."
        case .noWritableCalendar:
            return "No writable default calendar is available."
        }
    }
}

final class EventKitCalendarManager {
    private let eventStore: EKEventStore
    private let calendar: Calendar

    init(
        eventStore: EKEventStore = EKEventStore(),
        calendar: Calendar = .current
    ) {
        self.eventStore = eventStore
        self.calendar = calendar
    }

    func fetchTodayEvents() async throws -> [CalendarEvent] {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw AppleIntegrationError.permissionRequired("Calendar")
        }

        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? Date()
        let predicate = eventStore.predicateForEvents(
            withStart: start,
            end: end,
            calendars: nil
        )

        return eventStore.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { event in
                CalendarEvent(
                    id: UUID(),
                    title: event.title ?? "Calendar Event",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    type: eventType(for: event.title ?? "")
                )
            }
    }

    func createFocusBlock(
        title: String,
        startDate: Date,
        durationMinutes: Int = 90
    ) async throws {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw AppleIntegrationError.permissionRequired("Calendar")
        }
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            throw AppleIntegrationError.noWritableCalendar
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "LifeOS Focus: \(title)"
        event.startDate = startDate
        event.endDate = calendar.date(
            byAdding: .minute,
            value: durationMinutes,
            to: startDate
        ) ?? startDate.addingTimeInterval(Double(durationMinutes * 60))
        event.calendar = defaultCalendar
        event.notes = "Created from your LifeOS daily plan."

        try eventStore.save(event, span: .thisEvent, commit: true)
    }

    private func eventType(for title: String) -> CalendarEventType {
        let normalized = title.lowercased()

        if normalized.contains("interview") { return .interview }
        if normalized.contains("deadline") || normalized.contains("due") { return .deadline }
        if normalized.contains("workout") || normalized.contains("gym") || normalized.contains("walk") {
            return .workout
        }
        if normalized.contains("study") || normalized.contains("focus") || normalized.contains("review") {
            return .study
        }
        return .reminder
    }
}
