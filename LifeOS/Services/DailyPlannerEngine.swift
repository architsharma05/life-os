import Foundation

final class DailyPlannerEngine {
    func generatePlan(
        healthData: HealthData,
        focusData: FocusData,
        calendarEvents: [CalendarEvent],
        jobApplications: [JobApplication]
    ) -> DailyPlan {
        let energyScore = calculateEnergyScore(from: healthData)
        let focusRisk = calculateFocusRisk(from: focusData)
        let priorities = buildPriorities(
            calendarEvents: calendarEvents,
            jobApplications: jobApplications
        )
        let recommendations = buildRecommendations(
            healthData: healthData,
            focusData: focusData,
            jobApplications: jobApplications
        )

        return DailyPlan(
            date: Date(),
            energyScore: energyScore,
            focusRisk: focusRisk,
            topPriorities: Array(priorities.prefix(3)),
            scheduleBlocks: buildScheduleBlocks(
                energyScore: energyScore,
                focusRisk: focusRisk,
                priorities: priorities
            ),
            warnings: buildWarnings(healthData: healthData, focusData: focusData),
            recommendations: recommendations
        )
    }

    func calculateEnergyScore(from healthData: HealthData) -> Int {
        // Energy is intentionally simple for the MVP:
        // sleep 50%, steps 25%, workout 15%, resting heart rate placeholder 10%.
        let sleepScore = min(healthData.sleepHours / 8.0, 1.0) * 50.0
        let stepScore = min(Double(healthData.steps) / 10_000.0, 1.0) * 25.0
        let workoutScore = healthData.workoutCompleted ? 15.0 : 0.0
        let heartRateScore = restingHeartRateScore(healthData.restingHeartRate) * 10.0

        return min(100, max(0, Int((sleepScore + stepScore + workoutScore + heartRateScore).rounded())))
    }

    func calculateFocusRisk(from focusData: FocusData) -> FocusRisk {
        if focusData.screenTimeHours >= 7.0 || focusData.lateNightUsage {
            return .high
        }

        if focusData.screenTimeHours >= 4.0 || focusData.distractingAppUsageMinutes >= 60 {
            return .medium
        }

        return .low
    }

    private func restingHeartRateScore(_ restingHeartRate: Int) -> Double {
        switch restingHeartRate {
        case 50...75:
            return 1.0
        case 76...85:
            return 0.7
        default:
            return 0.4
        }
    }

    private func buildPriorities(
        calendarEvents: [CalendarEvent],
        jobApplications: [JobApplication]
    ) -> [String] {
        var priorities: [String] = []

        if let interview = calendarEvents.first(where: { $0.type == .interview }) {
            priorities.append(interview.title)
        }

        let urgentApplications = jobApplications
            .filter { daysUntil($0.deadline) <= 2 && $0.status != .rejected }
            .sorted { $0.deadline < $1.deadline }

        for application in urgentApplications {
            priorities.append("\(application.company): \(application.nextAction)")
        }

        if calendarEvents.contains(where: { $0.title.localizedCaseInsensitiveContains("Java OOP") }) {
            priorities.append("Java OOP review task")
        }

        if priorities.isEmpty {
            priorities.append("Choose one high-value focus block")
        }

        return unique(priorities)
    }

    private func buildScheduleBlocks(
        energyScore: Int,
        focusRisk: FocusRisk,
        priorities: [String]
    ) -> [ScheduleBlock] {
        let firstPriority = priorities.first ?? "Deep work"
        var blocks = [
            ScheduleBlock(
                title: "Morning focus",
                timeRange: "9:00 AM - 10:30 AM",
                detail: "Work on \(firstPriority) before lunch."
            ),
            ScheduleBlock(
                title: "Career admin",
                timeRange: "2:00 PM - 2:30 PM",
                detail: "Update job applications and send one follow-up."
            )
        ]

        if energyScore < 60 || focusRisk == .high {
            blocks[0].detail = "Use a lighter 45-minute block for \(firstPriority), then reset."
            blocks.append(
                ScheduleBlock(
                    title: "Energy reset",
                    timeRange: "12:30 PM - 1:00 PM",
                    detail: "Take a walk, hydrate, and avoid scrolling."
                )
            )
        } else {
            blocks.append(
                ScheduleBlock(
                    title: "Second focus block",
                    timeRange: "11:00 AM - 12:00 PM",
                    detail: "Continue interview prep or Java practice."
                )
            )
        }

        return blocks
    }

    private func buildWarnings(healthData: HealthData, focusData: FocusData) -> [String] {
        var warnings: [String] = []

        if healthData.sleepHours < 6 {
            warnings.append("Sleep was under 6 hours. Keep deep work lighter today.")
        }

        if focusData.lateNightUsage {
            warnings.append("Late-night device use may increase focus risk today.")
        }

        if focusData.distractingAppUsageMinutes >= 60 {
            warnings.append("Distracting app usage is elevated. Consider app limits during focus blocks.")
        }

        return warnings
    }

    private func buildRecommendations(
        healthData: HealthData,
        focusData: FocusData,
        jobApplications: [JobApplication]
    ) -> [Recommendation] {
        var recommendations: [Recommendation] = []

        if healthData.steps < 4_000 {
            recommendations.append(
                Recommendation(
                    category: .health,
                    title: "Add a walk",
                    detail: "Steps are below 4,000. A 20-minute walk can help energy and mood."
                )
            )
        }

        if !healthData.workoutCompleted {
            recommendations.append(
                Recommendation(
                    category: .health,
                    title: "Move today",
                    detail: "No workout is logged. Keep it simple: walk, stretch, or light strength work."
                )
            )
        }

        if focusData.lateNightUsage {
            recommendations.append(
                Recommendation(
                    category: .focus,
                    title: "Protect the first block",
                    detail: "Start with notifications off and place distracting apps behind a limit."
                )
            )
        }

        if let urgent = jobApplications
            .filter({ daysUntil($0.deadline) <= 2 && $0.status != .rejected })
            .sorted(by: { $0.deadline < $1.deadline })
            .first {
            recommendations.append(
                Recommendation(
                    category: .career,
                    title: "Career next action",
                    detail: "\(urgent.company): \(urgent.nextAction)"
                )
            )
        }

        recommendations.append(
            Recommendation(
                category: .device,
                title: "Commute/device reminder",
                detail: "Placeholder: check battery, calendar, commute time, and focus mode before leaving."
            )
        )

        return recommendations
    }

    private func daysUntil(_ date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
