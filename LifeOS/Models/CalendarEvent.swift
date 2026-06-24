import Foundation

enum CalendarEventType: String, Codable, CaseIterable, Identifiable {
    case interview = "Interview"
    case study = "Study"
    case deadline = "Deadline"
    case workout = "Workout"
    case reminder = "Reminder"

    var id: String { rawValue }
}

struct CalendarEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var type: CalendarEventType

    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date,
        endDate: Date,
        type: CalendarEventType
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
    }
}
