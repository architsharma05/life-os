import XCTest
@testable import LifeOS

final class DailyPlannerEngineTests: XCTestCase {
    private var engine: DailyPlannerEngine!

    override func setUp() {
        super.setUp()
        engine = DailyPlannerEngine()
    }

    func testEnergyScoreUsesWeightedInputs() {
        let healthData = HealthData(
            sleepHours: 8,
            steps: 10_000,
            workoutCompleted: true,
            restingHeartRate: 62
        )

        XCTAssertEqual(engine.calculateEnergyScore(from: healthData), 100)
    }

    func testLowSleepReducesEnergyScore() {
        let healthData = HealthData(
            sleepHours: 4,
            steps: 2_000,
            workoutCompleted: false,
            restingHeartRate: 82
        )

        XCTAssertLessThan(engine.calculateEnergyScore(from: healthData), 50)
    }

    func testLateNightUsageCreatesHighFocusRisk() {
        let focusData = FocusData(
            screenTimeHours: 2,
            distractingAppUsageMinutes: 10,
            lateNightUsage: true
        )

        XCTAssertEqual(engine.calculateFocusRisk(from: focusData), .high)
    }

    func testModerateDistractingUsageCreatesMediumFocusRisk() {
        let focusData = FocusData(
            screenTimeHours: 3,
            distractingAppUsageMinutes: 65,
            lateNightUsage: false
        )

        XCTAssertEqual(engine.calculateFocusRisk(from: focusData), .medium)
    }

    func testInterviewBecomesTopPriority() {
        let calendar = Calendar.current
        let now = Date()
        let interview = CalendarEvent(
            title: "Capgemini Java Developer interview prep",
            startDate: now,
            endDate: calendar.date(byAdding: .hour, value: 1, to: now) ?? now,
            type: .interview
        )

        let plan = engine.generatePlan(
            healthData: HealthData(sleepHours: 7, steps: 5_000, workoutCompleted: false, restingHeartRate: 68),
            focusData: FocusData(screenTimeHours: 2, distractingAppUsageMinutes: 20, lateNightUsage: false),
            calendarEvents: [interview],
            jobApplications: []
        )

        XCTAssertEqual(plan.topPriorities.first, "Capgemini Java Developer interview prep")
    }

    func testScheduleBlocksIncludeStructuredReminderTimes() {
        let plan = engine.generatePlan(
            healthData: HealthData(sleepHours: 7, steps: 5_000, workoutCompleted: false, restingHeartRate: 68),
            focusData: FocusData(screenTimeHours: 2, distractingAppUsageMinutes: 20, lateNightUsage: false),
            calendarEvents: [],
            jobApplications: []
        )

        XCTAssertFalse(plan.scheduleBlocks.isEmpty)
        XCTAssertTrue(plan.scheduleBlocks.allSatisfy { $0.startDate != nil })
        XCTAssertTrue(plan.scheduleBlocks.allSatisfy { $0.durationMinutes > 0 })
    }

    func testWeeklyHealthSummaryCalculatesAverages() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let summary = WeeklyHealthSummary(
            days: [
                DailyHealthTrend(date: start, sleepHours: 7, steps: 6_000, workoutCount: 1),
                DailyHealthTrend(
                    date: calendar.date(byAdding: .day, value: 1, to: start) ?? start,
                    sleepHours: 8,
                    steps: 8_000,
                    workoutCount: 0
                )
            ]
        )

        XCTAssertEqual(summary.averageSleepHours, 7.5)
        XCTAssertEqual(summary.averageSteps, 7_000)
        XCTAssertEqual(summary.workoutCount, 1)
    }

    func testOvernightQuietHours() {
        let preferences = ReminderPreferences(
            focusLeadMinutes: 10,
            quietHoursStart: 22,
            quietHoursEnd: 7,
            eveningReviewHour: 20
        )
        let calendar = Calendar.current
        let lateNight = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()

        XCTAssertTrue(preferences.isInsideQuietHours(lateNight, calendar: calendar))
        XCTAssertFalse(preferences.isInsideQuietHours(afternoon, calendar: calendar))
    }
}
