import SwiftUI
import FamilyControls

struct FocusCoachView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject private var focusSessionManager: FocusSessionManager
    @EnvironmentObject private var screenTimeManager: ScreenTimeAuthorizationManager
    @State private var selectedMinutes = 50
    @State private var showingActivityPicker = false
    @State private var activitySelection = FamilyActivitySelection()

    var body: some View {
        NavigationStack {
            List {
                Section("Focus Session") {
                    VStack(spacing: 14) {
                        Text(focusSessionManager.formattedRemainingTime)
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        ProgressView(value: focusSessionManager.progress)
                            .tint(.indigo)

                        Picker("Duration", selection: $selectedMinutes) {
                            Text("25 min").tag(25)
                            Text("50 min").tag(50)
                            Text("90 min").tag(90)
                        }
                        .pickerStyle(.segmented)
                        .disabled(focusSessionManager.remainingSeconds > 0)

                        sessionControls
                    }
                    .frame(maxWidth: .infinity)

                    LabeledContent(
                        "Completed today",
                        value: "\(focusSessionManager.todayCompletedMinutes) minutes"
                    )
                }

                Section("Today") {
                    LabeledContent("Focus Risk", value: viewModel.dailyPlan.focusRisk.rawValue)
                    LabeledContent("Screen Time", value: "\(viewModel.focusData.screenTimeHours.formatted(.number.precision(.fractionLength(1)))) hours")
                    LabeledContent("Distracting Apps", value: "\(viewModel.focusData.distractingAppUsageMinutes) minutes")
                    LabeledContent("Late-Night Usage", value: viewModel.focusData.lateNightUsage ? "Yes" : "No")
                }

                Section("Screen Time Readiness") {
                    LabeledContent("Family Controls", value: screenTimeManager.statusText)

                    if screenTimeManager.isAuthorized {
                        Button {
                            showingActivityPicker = true
                        } label: {
                            Label("Choose distracting apps", systemImage: "app.badge.checkmark")
                        }

                        if selectedActivityCount > 0 {
                            Text("\(selectedActivityCount) apps, categories, or websites selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            Task {
                                await screenTimeManager.requestAuthorization()
                            }
                        } label: {
                            Label("Request Screen Time access", systemImage: "hourglass")
                        }
                    }

                    if let error = screenTimeManager.lastErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Text("Apple must approve the Family Controls entitlement before LifeOS can monitor or shield selected apps in production.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .familyActivityPicker(
                isPresented: $showingActivityPicker,
                selection: $activitySelection
            )
        }
    }

    @ViewBuilder
    private var sessionControls: some View {
        if focusSessionManager.isRunning {
            HStack {
                Button("Pause") {
                    focusSessionManager.pause()
                }
                .buttonStyle(.borderedProminent)

                Button("End", role: .destructive) {
                    focusSessionManager.endSession()
                }
                .buttonStyle(.bordered)
            }
        } else if focusSessionManager.isPaused {
            HStack {
                Button("Resume") {
                    focusSessionManager.resume()
                }
                .buttonStyle(.borderedProminent)

                Button("End", role: .destructive) {
                    focusSessionManager.endSession()
                }
                .buttonStyle(.bordered)
            }
        } else {
            Button {
                focusSessionManager.start(minutes: selectedMinutes)
            } label: {
                Label("Start Focus Session", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var selectedActivityCount: Int {
        activitySelection.applicationTokens.count
            + activitySelection.categoryTokens.count
            + activitySelection.webDomainTokens.count
    }
}
