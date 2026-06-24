import SwiftUI

struct FocusCoachView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    LabeledContent("Focus Risk", value: viewModel.dailyPlan.focusRisk.rawValue)
                    LabeledContent("Screen Time", value: "\(viewModel.focusData.screenTimeHours.formatted(.number.precision(.fractionLength(1)))) hours")
                    LabeledContent("Distracting Apps", value: "\(viewModel.focusData.distractingAppUsageMinutes) minutes")
                    LabeledContent("Late-Night Usage", value: viewModel.focusData.lateNightUsage ? "Yes" : "No")
                }

                Section("Focus Plan") {
                    ForEach(viewModel.dailyPlan.scheduleBlocks) { block in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.title)
                                .font(.headline)
                            Text(block.detail)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Coach Notes") {
                    Text("Start the first focus block with notifications off.")
                    Text("Use one visible priority at a time.")
                    Text("If focus risk is high, choose shorter blocks with clear breaks.")
                }
            }
            .navigationTitle("Focus Coach")
        }
    }
}
