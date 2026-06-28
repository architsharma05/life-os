import Foundation

struct ScheduleBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var timeRange: String
    var detail: String
    var startDate: Date?
    var durationMinutes: Int

    init(
        id: UUID = UUID(),
        title: String,
        timeRange: String,
        detail: String,
        startDate: Date? = nil,
        durationMinutes: Int = 60
    ) {
        self.id = id
        self.title = title
        self.timeRange = timeRange
        self.detail = detail
        self.startDate = startDate
        self.durationMinutes = durationMinutes
    }
}
