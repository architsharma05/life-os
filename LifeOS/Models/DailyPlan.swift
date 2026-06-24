import Foundation

struct DailyPlan: Codable, Equatable {
    var date: Date
    var energyScore: Int
    var focusRisk: FocusRisk
    var topPriorities: [String]
    var scheduleBlocks: [ScheduleBlock]
    var warnings: [String]
    var recommendations: [Recommendation]

    var mainPriority: String {
        topPriorities.first ?? "Plan the day"
    }
}
