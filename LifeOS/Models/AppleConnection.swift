import Foundation

enum AppleConnection: String, CaseIterable, Identifiable {
    case health = "Health"
    case calendar = "Calendar"
    case notifications = "Notifications"
    case focus = "Focus"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .health: return "heart.fill"
        case .calendar: return "calendar"
        case .notifications: return "bell.fill"
        case .focus: return "hourglass"
        }
    }

    var summary: String {
        switch self {
        case .health:
            return "Sleep, steps, workouts, and resting heart rate"
        case .calendar:
            return "Interviews, deadlines, events, and focus blocks"
        case .notifications:
            return "Private reminders for plans and upcoming actions"
        case .focus:
            return "Screen-time signals for focus risk"
        }
    }
}

enum ConnectionStatus: Equatable {
    case notRequested
    case connected
    case denied
    case unavailable
    case requiresSetup

    var title: String {
        switch self {
        case .notRequested: return "Not Connected"
        case .connected: return "Connected"
        case .denied: return "Access Denied"
        case .unavailable: return "Unavailable"
        case .requiresSetup: return "Coming Later"
        }
    }
}
