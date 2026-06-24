import Foundation

final class MockHealthDataManager {
    func fetchTodayHealthData() -> HealthData {
        HealthData(
            sleepHours: 6.8,
            steps: 3_650,
            workoutCompleted: false,
            restingHeartRate: 68
        )
    }
}
