import Foundation

final class MockFocusDataManager {
    func fetchTodayFocusData() -> FocusData {
        FocusData(
            screenTimeHours: 5.2,
            distractingAppUsageMinutes: 74,
            lateNightUsage: true
        )
    }
}
