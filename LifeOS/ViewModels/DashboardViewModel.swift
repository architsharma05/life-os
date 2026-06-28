import Foundation
import Combine

enum PlannerDataSource: String {
    case mock = "Mock Data"
    case manual = "Manual"
    case healthKit = "HealthKit"
    case appleCalendar = "Apple Calendar"
}

final class DashboardViewModel: ObservableObject {
    @Published private(set) var healthData: HealthData
    @Published private(set) var focusData: FocusData
    @Published private(set) var calendarEvents: [CalendarEvent]
    @Published private(set) var dailyPlan: DailyPlan
    @Published private(set) var weeklyHealthSummary: WeeklyHealthSummary?
    @Published private(set) var healthDataSource: PlannerDataSource = .mock
    @Published private(set) var calendarDataSource: PlannerDataSource = .mock

    private let healthDataManager: MockHealthDataManager
    private let focusDataManager: MockFocusDataManager
    private let calendarManager: MockCalendarManager
    private let healthKitDataManager: HealthKitDataManager
    private let eventKitCalendarManager: EventKitCalendarManager
    private let notificationScheduler: NotificationScheduler
    private let backgroundRefreshManager: BackgroundRefreshManager
    private let plannerEngine: DailyPlannerEngine
    private let jobStore: JobApplicationStore
    private let checkInStore: DailyCheckInStore
    private var isUsingCustomMockData = false

    init(
        healthDataManager: MockHealthDataManager = MockHealthDataManager(),
        focusDataManager: MockFocusDataManager = MockFocusDataManager(),
        calendarManager: MockCalendarManager = MockCalendarManager(),
        healthKitDataManager: HealthKitDataManager = HealthKitDataManager(),
        eventKitCalendarManager: EventKitCalendarManager = EventKitCalendarManager(),
        notificationScheduler: NotificationScheduler = NotificationScheduler(),
        backgroundRefreshManager: BackgroundRefreshManager = .shared,
        plannerEngine: DailyPlannerEngine = DailyPlannerEngine(),
        jobStore: JobApplicationStore,
        checkInStore: DailyCheckInStore
    ) {
        self.healthDataManager = healthDataManager
        self.focusDataManager = focusDataManager
        self.calendarManager = calendarManager
        self.healthKitDataManager = healthKitDataManager
        self.eventKitCalendarManager = eventKitCalendarManager
        self.notificationScheduler = notificationScheduler
        self.backgroundRefreshManager = backgroundRefreshManager
        self.plannerEngine = plannerEngine
        self.jobStore = jobStore
        self.checkInStore = checkInStore

        let initialHealth = healthDataManager.fetchTodayHealthData()
        let initialFocus = focusDataManager.fetchTodayFocusData()
        let initialEvents = calendarManager.fetchTodayEvents()

        self.healthData = initialHealth
        self.focusData = initialFocus
        self.calendarEvents = initialEvents
        self.weeklyHealthSummary = nil
        self.dailyPlan = plannerEngine.generatePlan(
            healthData: initialHealth,
            focusData: initialFocus,
            calendarEvents: initialEvents,
            jobApplications: jobStore.applications,
            preferredPriorities: checkInStore.today.priorities
        )
    }

    func refresh() {
        regeneratePlan()
    }

    @MainActor
    func refreshFromConnectedServices(permissionManager: ApplePermissionManager) async {
        if !isUsingCustomMockData {
            let fallback = backgroundRefreshManager.cachedHealthData()
                ?? healthDataManager.fetchTodayHealthData()

            if permissionManager.status(for: .health) == .connected {
                do {
                    healthData = try await healthKitDataManager.fetchTodayHealthData(fallback: fallback)
                    healthDataSource = .healthKit
                    backgroundRefreshManager.cache(healthData)
                    weeklyHealthSummary = try? await healthKitDataManager.fetchWeeklySummary()
                } catch {
                    healthData = fallback
                    healthDataSource = .mock
                    weeklyHealthSummary = nil
                }
            } else {
                healthData = fallback
                healthDataSource = .mock
                weeklyHealthSummary = nil
            }

            focusData = focusDataManager.fetchTodayFocusData()
        }

        if permissionManager.status(for: .calendar) == .connected {
            do {
                calendarEvents = try await eventKitCalendarManager.fetchTodayEvents()
                calendarDataSource = .appleCalendar
            } catch {
                calendarEvents = calendarManager.fetchTodayEvents()
                calendarDataSource = .mock
            }
        } else {
            calendarEvents = calendarManager.fetchTodayEvents()
            calendarDataSource = .mock
        }

        regeneratePlan()
    }

    @MainActor
    func addSuggestedFocusBlockToCalendar() async throws -> Date {
        let startDate = nextRoundedHour()
        let scheduledStart = try await eventKitCalendarManager.createFocusBlock(
            title: dailyPlan.mainPriority,
            preferredStartDate: startDate
        )
        calendarEvents = try await eventKitCalendarManager.fetchTodayEvents()
        calendarDataSource = .appleCalendar
        regeneratePlan()
        return scheduledStart
    }

    @MainActor
    func scheduleReminders(
        permissionManager: ApplePermissionManager,
        preferences: ReminderPreferences
    ) async throws -> Int {
        guard permissionManager.status(for: .notifications) == .connected else {
            throw AppleIntegrationError.permissionRequired("Notifications")
        }
        return try await notificationScheduler.scheduleReminders(
            for: dailyPlan,
            jobApplications: jobStore.applications,
            preferences: preferences
        )
    }

    func cancelReminders() async {
        await notificationScheduler.removeLifeOSReminders()
    }

    func updateMockInputs(healthData: HealthData, focusData: FocusData) {
        isUsingCustomMockData = true
        self.healthData = healthData
        self.focusData = focusData
        healthDataSource = .manual
        weeklyHealthSummary = nil
        regeneratePlan()
    }

    func resetMockInputs() {
        isUsingCustomMockData = false
        healthData = healthDataManager.fetchTodayHealthData()
        focusData = focusDataManager.fetchTodayFocusData()
        calendarEvents = calendarManager.fetchTodayEvents()
        healthDataSource = .mock
        calendarDataSource = .mock
        weeklyHealthSummary = nil
        regeneratePlan()
    }

    private func regeneratePlan() {
        dailyPlan = plannerEngine.generatePlan(
            healthData: healthData,
            focusData: focusData,
            calendarEvents: calendarEvents,
            jobApplications: jobStore.applications,
            preferredPriorities: checkInStore.today.priorities,
            weeklyHealthSummary: weeklyHealthSummary
        )
    }

    private func nextRoundedHour() -> Date {
        let calendar = Calendar.current
        let oneHourFromNow = calendar.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: oneHourFromNow),
            minute: 0,
            second: 0,
            of: oneHourFromNow
        ) ?? oneHourFromNow
    }
}
