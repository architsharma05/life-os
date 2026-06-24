import Foundation

struct ScheduleBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var timeRange: String
    var detail: String

    init(id: UUID = UUID(), title: String, timeRange: String, detail: String) {
        self.id = id
        self.title = title
        self.timeRange = timeRange
        self.detail = detail
    }
}
