import BackgroundTasks
import Foundation

final class BackgroundRefreshManager {
    static let shared = BackgroundRefreshManager()
    static let taskIdentifier = "com.lifeos.mvp.health-refresh"

    private let healthKitDataManager: HealthKitDataManager
    private let mockHealthDataManager: MockHealthDataManager
    private let userDefaults: UserDefaults
    private let cacheKey = "lifeos.cachedHealthSnapshot"

    init(
        healthKitDataManager: HealthKitDataManager = HealthKitDataManager(),
        mockHealthDataManager: MockHealthDataManager = MockHealthDataManager(),
        userDefaults: UserDefaults = .standard
    ) {
        self.healthKitDataManager = healthKitDataManager
        self.mockHealthDataManager = mockHealthDataManager
        self.userDefaults = userDefaults
    }

    func scheduleNextRefresh() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Unable to schedule LifeOS background refresh: \(error.localizedDescription)")
        }
    }

    func performRefresh() async {
        defer { scheduleNextRefresh() }

        do {
            let fallback = cachedHealthData() ?? mockHealthDataManager.fetchTodayHealthData()
            let healthData = try await healthKitDataManager.fetchTodayHealthData(fallback: fallback)
            cache(healthData)
        } catch {
            print("LifeOS background health refresh failed: \(error.localizedDescription)")
        }
    }

    func cache(_ healthData: HealthData) {
        let snapshot = CachedHealthSnapshot(savedAt: Date(), healthData: healthData)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: cacheKey)
    }

    func cachedHealthData(maxAge: TimeInterval = 12 * 60 * 60) -> HealthData? {
        guard
            let data = userDefaults.data(forKey: cacheKey),
            let snapshot = try? JSONDecoder().decode(CachedHealthSnapshot.self, from: data),
            Date().timeIntervalSince(snapshot.savedAt) <= maxAge
        else { return nil }

        return snapshot.healthData
    }
}

private struct CachedHealthSnapshot: Codable {
    let savedAt: Date
    let healthData: HealthData
}
