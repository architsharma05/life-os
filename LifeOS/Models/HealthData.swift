import Foundation

struct HealthData: Codable, Equatable {
    let sleepHours: Double
    let steps: Int
    let workoutCompleted: Bool
    let restingHeartRate: Int
}
