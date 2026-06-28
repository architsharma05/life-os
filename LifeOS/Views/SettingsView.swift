import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject private var permissionManager: ApplePermissionManager
    @AppStorage("lifeos.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lifeos.reminders.focusLeadMinutes") private var focusLeadMinutes = 10
    @AppStorage("lifeos.reminders.quietStartHour") private var quietStartHour = 22
    @AppStorage("lifeos.reminders.quietEndHour") private var quietEndHour = 7
    @AppStorage("lifeos.reminders.reviewHour") private var reviewHour = 20
    @State private var reminderMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Connections") {
                    NavigationLink {
                        ConnectionsView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Services")
                                Text("\(connectedCount) of \(AppleConnection.allCases.count) connected")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "link")
                        }
                    }
                }

                Section("Reminders") {
                    Stepper(
                        "Focus warning: \(focusLeadMinutes) min",
                        value: $focusLeadMinutes,
                        in: 5...30,
                        step: 5
                    )

                    Picker("Evening review", selection: $reviewHour) {
                        ForEach(17...21, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }

                    Picker("Quiet hours start", selection: $quietStartHour) {
                        ForEach(20...23, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }

                    Picker("Quiet hours end", selection: $quietEndHour) {
                        ForEach(5...9, id: \.self) { hour in
                            Text(hourLabel(hour)).tag(hour)
                        }
                    }

                    Button {
                        scheduleReminders()
                    } label: {
                        Label("Schedule smart reminders", systemImage: "bell.badge")
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.cancelReminders()
                            reminderMessage = "LifeOS reminders were removed."
                        }
                    } label: {
                        Label("Cancel LifeOS reminders", systemImage: "bell.slash")
                    }

                    if let reminderMessage {
                        Text(reminderMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

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

                Section("Onboarding") {
                    Button("Show onboarding again") {
                        hasCompletedOnboarding = false
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await permissionManager.refreshStatuses()
            }
        }
    }

    private var connectedCount: Int {
        AppleConnection.allCases.filter {
            permissionManager.status(for: $0) == .connected
        }.count
    }

    private func scheduleReminders() {
        Task {
            do {
                let count = try await viewModel.scheduleReminders(
                    permissionManager: permissionManager,
                    preferences: ReminderPreferences(
                        focusLeadMinutes: focusLeadMinutes,
                        quietHoursStart: quietStartHour,
                        quietHoursEnd: quietEndHour,
                        eveningReviewHour: reviewHour
                    )
                )
                reminderMessage = count == 1
                    ? "1 reminder scheduled."
                    : "\(count) reminders scheduled."
            } catch {
                reminderMessage = error.localizedDescription
            }
        }
    }

    private func hourLabel(_ hour: Int) -> String {
        let normalizedHour = hour % 12 == 0 ? 12 : hour % 12
        return "\(normalizedHour):00 \(hour < 12 ? "AM" : "PM")"
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
