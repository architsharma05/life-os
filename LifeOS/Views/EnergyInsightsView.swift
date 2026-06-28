import SwiftUI
import Charts

struct EnergyInsightsView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Energy Score") {
                    LabeledContent("Score", value: "\(viewModel.dailyPlan.energyScore)/100")
                    LabeledContent("Source", value: viewModel.healthDataSource.rawValue)
                    LabeledContent("Sleep", value: "\(viewModel.healthData.sleepHours.formatted(.number.precision(.fractionLength(1)))) hours")
                    LabeledContent("Steps", value: "\(viewModel.healthData.steps)")
                    LabeledContent("Workout", value: viewModel.healthData.workoutCompleted ? "Completed" : "Not yet")
                    LabeledContent("Resting Heart Rate", value: "\(viewModel.healthData.restingHeartRate) bpm")
                }

                Section("Health Suggestions") {
                    ForEach(viewModel.dailyPlan.recommendations.filter { $0.category == .health }) { recommendation in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recommendation.title)
                                .font(.headline)
                            Text(recommendation.detail)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let summary = viewModel.weeklyHealthSummary {
                    Section("Seven-Day Trends") {
                        if hasWeeklyData(summary) {
                            weeklySummary(summary)
                            stepsChart(summary)
                            sleepChart(summary)
                        } else {
                            ContentUnavailableView(
                                "No Weekly Samples",
                                systemImage: "chart.bar.xaxis",
                                description: Text("HealthKit is connected, but it has not returned steps or sleep samples for this week.")
                            )
                        }
                    }
                }

                Section("How Energy Is Calculated") {
                    Text("Sleep contributes 50%, steps 25%, workout 15%, and resting heart rate 10%. The MVP uses mock data so it runs without HealthKit.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Energy Insights")
        }
    }

    private func weeklySummary(_ summary: WeeklyHealthSummary) -> some View {
        HStack(spacing: 12) {
            TrendMetric(
                title: "Avg Sleep",
                value: summary.averageSleepHours.map {
                    "\($0.formatted(.number.precision(.fractionLength(1))))h"
                } ?? "—"
            )
            TrendMetric(
                title: "Avg Steps",
                value: summary.averageSteps.map { $0.formatted() } ?? "—"
            )
            TrendMetric(
                title: "Workouts",
                value: "\(summary.workoutCount)"
            )
        }
        .padding(.vertical, 4)
    }

    private func stepsChart(_ summary: WeeklyHealthSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps")
                .font(.headline)
            Chart(summary.days) { day in
                if let steps = day.steps {
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", steps)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(3)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(height: 150)
        }
    }

    private func sleepChart(_ summary: WeeklyHealthSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sleep")
                .font(.headline)
            Chart(summary.days) { day in
                if let sleep = day.sleepHours {
                    LineMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Hours", sleep)
                    )
                    .foregroundStyle(.indigo)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Hours", sleep)
                    )
                    .foregroundStyle(.indigo)
                }
            }
            .chartYScale(domain: 0...10)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                }
            }
            .frame(height: 150)
        }
    }

    private func hasWeeklyData(_ summary: WeeklyHealthSummary) -> Bool {
        summary.days.contains { $0.steps != nil || $0.sleepHours != nil || $0.workoutCount > 0 }
    }
}

private struct TrendMetric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
