import Combine
import EventKit
import Foundation
import HealthKit
import UserNotifications

@MainActor
final class ApplePermissionManager: ObservableObject {
    @Published private(set) var statuses: [AppleConnection: ConnectionStatus] = [:]
    @Published private(set) var lastErrorMessage: String?

    private let healthStore = HKHealthStore()
    private let eventStore = EKEventStore()
    private let healthRequestKey = "lifeos.didRequestHealthAccess"

    init() {
        for connection in AppleConnection.allCases {
            statuses[connection] = .notRequested
        }
        statuses[.focus] = .requiresSetup
    }

    func status(for connection: AppleConnection) -> ConnectionStatus {
        statuses[connection] ?? .notRequested
    }

    func refreshStatuses() async {
        refreshHealthStatus()
        refreshCalendarStatus()
        await refreshNotificationStatus()
        statuses[.focus] = .requiresSetup
    }

    func requestAccess(for connection: AppleConnection) async {
        lastErrorMessage = nil

        do {
            switch connection {
            case .health:
                try await requestHealthAccess()
            case .calendar:
                try await requestCalendarAccess()
            case .notifications:
                try await requestNotificationAccess()
            case .focus:
                statuses[.focus] = .requiresSetup
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        await refreshStatuses()
    }

    private func refreshHealthStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statuses[.health] = .unavailable
            return
        }

        // HealthKit intentionally does not reveal read authorization per type.
        // We remember only that the user completed Apple's permission sheet.
        statuses[.health] = UserDefaults.standard.bool(forKey: healthRequestKey)
            ? .connected
            : .notRequested
    }

    private func requestHealthAccess() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            statuses[.health] = .unavailable
            return
        }

        var readTypes = Set<HKObjectType>()
        readTypes.insert(HKQuantityType(.stepCount))
        readTypes.insert(HKQuantityType(.heartRate))
        readTypes.insert(HKQuantityType(.restingHeartRate))
        readTypes.insert(HKCategoryType(.sleepAnalysis))
        readTypes.insert(HKObjectType.workoutType())

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        UserDefaults.standard.set(true, forKey: healthRequestKey)
        statuses[.health] = .connected
    }

    private func refreshCalendarStatus() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .writeOnly:
            statuses[.calendar] = .connected
        case .denied, .restricted:
            statuses[.calendar] = .denied
        case .notDetermined:
            statuses[.calendar] = .notRequested
        @unknown default:
            statuses[.calendar] = .unavailable
        }
    }

    private func requestCalendarAccess() async throws {
        let granted = try await eventStore.requestFullAccessToEvents()
        statuses[.calendar] = granted ? .connected : .denied
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            statuses[.notifications] = .connected
        case .denied:
            statuses[.notifications] = .denied
        case .notDetermined:
            statuses[.notifications] = .notRequested
        @unknown default:
            statuses[.notifications] = .unavailable
        }
    }

    private func requestNotificationAccess() async throws {
        let granted = try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
        statuses[.notifications] = granted ? .connected : .denied
    }
}
