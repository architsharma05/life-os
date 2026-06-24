import SwiftUI

struct EnergyInsightsView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Energy Score") {
                    LabeledContent("Score", value: "\(viewModel.dailyPlan.energyScore)/100")
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

                Section("How Energy Is Calculated") {
                    Text("Sleep contributes 50%, steps 25%, workout 15%, and resting heart rate 10%. The MVP uses mock data so it runs without HealthKit.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Energy Insights")
        }
    }
}
