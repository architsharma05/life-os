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
        preferredStartDate: Date,
        durationMinutes: Int = 90
    ) async throws -> Date {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw AppleIntegrationError.permissionRequired("Calendar")
        }
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            throw AppleIntegrationError.noWritableCalendar
        }

        let startDate = nextAvailableStart(
            preferredStart: preferredStartDate,
            durationMinutes: durationMinutes
        )
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
        return startDate
    }

    private func nextAvailableStart(
        preferredStart: Date,
        durationMinutes: Int
    ) -> Date {
        let duration = TimeInterval(durationMinutes * 60)
        var searchDay = calendar.startOfDay(for: preferredStart)

        for dayOffset in 0..<7 {
            if dayOffset > 0 {
                searchDay = calendar.date(byAdding: .day, value: 1, to: searchDay) ?? searchDay
            }

            let workdayStart = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: searchDay) ?? searchDay
            let workdayEnd = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: searchDay) ?? searchDay
            let initialCandidate = dayOffset == 0 ? max(preferredStart, workdayStart) : workdayStart
            var candidate = roundedUpToHalfHour(initialCandidate)

            let predicate = eventStore.predicateForEvents(
                withStart: workdayStart,
                end: workdayEnd,
                calendars: nil
            )
            let events = eventStore.events(matching: predicate)
                .filter { !$0.isAllDay }
                .sorted { $0.startDate < $1.startDate }

            while candidate.addingTimeInterval(duration) <= workdayEnd {
                let candidateEnd = candidate.addingTimeInterval(duration)
                let conflicts = events.filter {
                    $0.startDate < candidateEnd && $0.endDate > candidate
                }

                if conflicts.isEmpty {
                    return candidate
                }

                let latestConflictEnd = conflicts.map(\.endDate).max() ?? candidate
                candidate = roundedUpToHalfHour(latestConflictEnd)
            }
        }

        return preferredStart
    }

    private func roundedUpToHalfHour(_ date: Date) -> Date {
        let minute = calendar.component(.minute, from: date)
        let minutesToAdd = minute == 0 || minute == 30 ? 0 : (minute < 30 ? 30 - minute : 60 - minute)
        let rounded = calendar.date(byAdding: .minute, value: minutesToAdd, to: date) ?? date
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: rounded),
            minute: calendar.component(.minute, from: rounded),
            second: 0,
            of: rounded
        ) ?? rounded
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
