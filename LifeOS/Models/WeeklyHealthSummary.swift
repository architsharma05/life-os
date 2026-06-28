import Foundation

struct DailyHealthTrend: Identifiable, Codable, Equatable {
    var id: Date { date }
    let date: Date
    let sleepHours: Double?
    let steps: Int?
    let workoutCount: Int
}

struct WeeklyHealthSummary: Codable, Equatable {
    let days: [DailyHealthTrend]

    var averageSleepHours: Double? {
        let values = days.compactMap(\.sleepHours)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    var averageSteps: Int? {
        let values = days.compactMap(\.steps)
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }

    var workoutCount: Int {
        days.reduce(0) { $0 + $1.workoutCount }
    }
}
