import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    @Published private(set) var healthData: HealthData
    @Published private(set) var focusData: FocusData
    @Published private(set) var calendarEvents: [CalendarEvent]
    @Published private(set) var dailyPlan: DailyPlan

    private let healthDataManager: MockHealthDataManager
    private let focusDataManager: MockFocusDataManager
    private let calendarManager: MockCalendarManager
    private let plannerEngine: DailyPlannerEngine
    private let jobStore: JobApplicationStore
    private var isUsingCustomMockData = false

    init(
        healthDataManager: MockHealthDataManager = MockHealthDataManager(),
        focusDataManager: MockFocusDataManager = MockFocusDataManager(),
        calendarManager: MockCalendarManager = MockCalendarManager(),
        plannerEngine: DailyPlannerEngine = DailyPlannerEngine(),
        jobStore: JobApplicationStore
    ) {
        self.healthDataManager = healthDataManager
        self.focusDataManager = focusDataManager
        self.calendarManager = calendarManager
        self.plannerEngine = plannerEngine
        self.jobStore = jobStore

        let initialHealth = healthDataManager.fetchTodayHealthData()
        let initialFocus = focusDataManager.fetchTodayFocusData()
        let initialEvents = calendarManager.fetchTodayEvents()

        self.healthData = initialHealth
        self.focusData = initialFocus
        self.calendarEvents = initialEvents
        self.dailyPlan = plannerEngine.generatePlan(
            healthData: initialHealth,
            focusData: initialFocus,
            calendarEvents: initialEvents,
            jobApplications: jobStore.applications
        )
    }

    func refresh() {
        if !isUsingCustomMockData {
            healthData = healthDataManager.fetchTodayHealthData()
            focusData = focusDataManager.fetchTodayFocusData()
        }

        calendarEvents = calendarManager.fetchTodayEvents()
        regeneratePlan()
    }

    func updateMockInputs(healthData: HealthData, focusData: FocusData) {
        isUsingCustomMockData = true
        self.healthData = healthData
        self.focusData = focusData
        regeneratePlan()
    }

    func resetMockInputs() {
        isUsingCustomMockData = false
        healthData = healthDataManager.fetchTodayHealthData()
        focusData = focusDataManager.fetchTodayFocusData()
        calendarEvents = calendarManager.fetchTodayEvents()
        regeneratePlan()
    }

    private func regeneratePlan() {
        dailyPlan = plannerEngine.generatePlan(
            healthData: healthData,
            focusData: focusData,
            calendarEvents: calendarEvents,
            jobApplications: jobStore.applications
        )
    }
}
