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
}
