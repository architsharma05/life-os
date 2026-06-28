import Foundation

struct DailyCheckIn: Codable, Equatable {
    var date: Date
    var priorities: [String]
    var intention: String
    var morningEnergy: Int
    var morningCompleted: Bool
    var completedPriorityCount: Int
    var eveningEnergy: Int
    var reflection: String
    var eveningCompleted: Bool

    static func empty(for date: Date = Date()) -> DailyCheckIn {
        DailyCheckIn(
            date: Calendar.current.startOfDay(for: date),
            priorities: [],
            intention: "",
            morningEnergy: 70,
            morningCompleted: false,
            completedPriorityCount: 0,
            eveningEnergy: 60,
            reflection: "",
            eveningCompleted: false
        )
    }
}
