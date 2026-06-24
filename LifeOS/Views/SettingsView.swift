import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Mock Data") {
                    NavigationLink {
                        MockDataEditorView(viewModel: viewModel)
                    } label: {
                        Label("Edit today's mock inputs", systemImage: "slider.horizontal.3")
                    }
                    Button("Reset mock inputs") {
                        viewModel.resetMockInputs()
                    }
                }

                Section("Privacy-First MVP") {
                    Text("LifeOS stores MVP job-search data locally on this device using UserDefaults.")
                    Text("Mock health, focus, and calendar data are generated in the app. No paid APIs, backend, or external AI service is required.")
                    Text("You control what gets connected. Future integrations should ask before accessing HealthKit, EventKit, DeviceActivity, Supabase, or AI APIs.")
                    Text("Sensitive memory should require explicit approval before it is saved.")
                }

                Section("Future Connections") {
                    Label("HealthKit for real health trends", systemImage: "heart")
                    Label("EventKit for calendar events", systemImage: "calendar")
                    Label("DeviceActivity for focus signals", systemImage: "iphone")
                    Label("Optional AI APIs for richer planning", systemImage: "sparkles")
                }

                Section("Developer Notes") {
                    Text("The MVP uses simple MVVM folders: Models, Managers, Services, ViewModels, and Views.")
                    Text("DailyPlannerEngine is rule-based so the logic is explainable and easy to replace later.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct MockDataEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel

    @State private var sleepHours: Double
    @State private var steps: Double
    @State private var workoutCompleted: Bool
    @State private var restingHeartRate: Double
    @State private var screenTimeHours: Double
    @State private var distractingMinutes: Double
    @State private var lateNightUsage: Bool

    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        _sleepHours = State(initialValue: viewModel.healthData.sleepHours)
        _steps = State(initialValue: Double(viewModel.healthData.steps))
        _workoutCompleted = State(initialValue: viewModel.healthData.workoutCompleted)
        _restingHeartRate = State(initialValue: Double(viewModel.healthData.restingHeartRate))
        _screenTimeHours = State(initialValue: viewModel.focusData.screenTimeHours)
        _distractingMinutes = State(initialValue: Double(viewModel.focusData.distractingAppUsageMinutes))
        _lateNightUsage = State(initialValue: viewModel.focusData.lateNightUsage)
    }

    var body: some View {
        Form {
            Section("Health") {
                Stepper("Sleep: \(sleepHours.formatted(.number.precision(.fractionLength(1)))) hours", value: $sleepHours, in: 0...12, step: 0.5)
                Stepper("Steps: \(Int(steps))", value: $steps, in: 0...25_000, step: 500)
                Toggle("Workout completed", isOn: $workoutCompleted)
                Stepper("Resting heart rate: \(Int(restingHeartRate)) bpm", value: $restingHeartRate, in: 45...110, step: 1)
            }

            Section("Focus") {
                Stepper("Screen time: \(screenTimeHours.formatted(.number.precision(.fractionLength(1)))) hours", value: $screenTimeHours, in: 0...14, step: 0.5)
                Stepper("Distracting apps: \(Int(distractingMinutes)) min", value: $distractingMinutes, in: 0...300, step: 5)
                Toggle("Late-night usage", isOn: $lateNightUsage)
            }

            Section("Preview") {
                Text("Saving these inputs immediately recalculates energy score, focus risk, warnings, and recommendations.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Mock Inputs")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    viewModel.updateMockInputs(
                        healthData: HealthData(
                            sleepHours: sleepHours,
                            steps: Int(steps),
                            workoutCompleted: workoutCompleted,
                            restingHeartRate: Int(restingHeartRate)
                        ),
                        focusData: FocusData(
                            screenTimeHours: screenTimeHours,
                            distractingAppUsageMinutes: Int(distractingMinutes),
                            lateNightUsage: lateNightUsage
                        )
                    )
                    dismiss()
                }
            }
        }
    }
}
