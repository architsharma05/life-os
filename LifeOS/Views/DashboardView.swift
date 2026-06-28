import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject private var jobStore: JobApplicationStore
    @EnvironmentObject private var checkInStore: DailyCheckInStore
    @EnvironmentObject private var permissionManager: ApplePermissionManager
    @State private var calendarMessage: String?
    @State private var showingMorningPlan = false
    @State private var showingEveningReview = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroCard
                    quickMetrics
                    dataSourcesRow
                    dailyCheckInSection
                    nowNextSection
                    scheduleSection
                    recommendationSection
                    warningSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("LifeOS")
            .toolbar {
                Button {
                    Task {
                        await viewModel.refreshFromConnectedServices(
                            permissionManager: permissionManager
                        )
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh daily plan")
            }
            .onReceive(jobStore.$applications) { _ in
                viewModel.refresh()
            }
            .onReceive(checkInStore.$today) { _ in
                viewModel.refresh()
            }
            .task {
                await viewModel.refreshFromConnectedServices(
                    permissionManager: permissionManager
                )
            }
            .alert("Calendar", isPresented: calendarAlertBinding) {
                Button("OK", role: .cancel) {
                    calendarMessage = nil
                }
            } message: {
                Text(calendarMessage ?? "")
            }
            .sheet(isPresented: $showingMorningPlan) {
                MorningPlanningView()
                    .environmentObject(checkInStore)
            }
            .sheet(isPresented: $showingEveningReview) {
                EveningReviewView()
                    .environmentObject(checkInStore)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.dailyPlan.date, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Today's Command Center")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .lineLimit(2)
                }

                Spacer()

                EnergyRing(score: viewModel.dailyPlan.energyScore)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Main Priority")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(viewModel.dailyPlan.mainPriority)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Label(focusSummary, systemImage: focusIcon)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(focusColor)
                Spacer()
                Text("Local-first")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemGroupedBackground),
                    focusColor.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickMetrics: some View {
        HStack(spacing: 12) {
            MetricCard(
                title: "Sleep",
                value: "\(viewModel.healthData.sleepHours.formatted(.number.precision(.fractionLength(1))))h",
                footnote: energyMessage,
                iconName: "bed.double",
                color: .blue
            )
            MetricCard(
                title: "Focus",
                value: viewModel.dailyPlan.focusRisk.rawValue,
                footnote: "\(viewModel.focusData.screenTimeHours.formatted(.number.precision(.fractionLength(1))))h screen time",
                iconName: focusIcon,
                color: focusColor
            )
        }
    }

    private var dataSourcesRow: some View {
        HStack(spacing: 8) {
            SourcePill(
                iconName: "heart.fill",
                label: viewModel.healthDataSource.rawValue,
                color: viewModel.healthDataSource == .healthKit ? .red : .secondary
            )
            SourcePill(
                iconName: "calendar",
                label: viewModel.calendarDataSource.rawValue,
                color: viewModel.calendarDataSource == .appleCalendar ? .blue : .secondary
            )
            Spacer()
        }
    }

    private var dailyCheckInSection: some View {
        SectionCard(title: "Daily Check-In") {
            if !checkInStore.today.intention.isEmpty {
                Text(checkInStore.today.intention)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                CheckInButton(
                    title: "Plan Morning",
                    iconName: "sunrise.fill",
                    isComplete: checkInStore.today.morningCompleted,
                    color: .orange
                ) {
                    showingMorningPlan = true
                }

                CheckInButton(
                    title: "Review Day",
                    iconName: "moon.stars.fill",
                    isComplete: checkInStore.today.eveningCompleted,
                    color: .indigo
                ) {
                    showingEveningReview = true
                }
            }
        }
    }

    private var nowNextSection: some View {
        SectionCard(title: "Now / Next") {
            VStack(alignment: .leading, spacing: 14) {
                if let firstBlock = viewModel.dailyPlan.scheduleBlocks.first {
                    FocusBlockCard(
                        label: "Now",
                        title: firstBlock.title,
                        detail: firstBlock.detail,
                        iconName: "play.circle.fill",
                        color: .accentColor
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Top 3 Priorities")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(Array(viewModel.dailyPlan.topPriorities.enumerated()), id: \.offset) { index, priority in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                            Text(priority)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var scheduleSection: some View {
        SectionCard(title: "Today's Flow") {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.dailyPlan.scheduleBlocks.enumerated()), id: \.element.id) { index, block in
                        TimelineRow(
                            block: block,
                            isLast: index == viewModel.dailyPlan.scheduleBlocks.count - 1
                        )
                    }
                }

                Button {
                    addFocusBlock()
                } label: {
                    Label("Add suggested focus block", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var recommendationSection: some View {
        SectionCard(title: "Recommendations") {
            ForEach(Array(viewModel.dailyPlan.recommendations.prefix(4))) { recommendation in
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.title)
                            .font(.headline)
                        Text(recommendation.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: iconName(for: recommendation.category))
                        .foregroundStyle(color(for: recommendation.category))
                }
            }
        }
    }

    @ViewBuilder
    private var warningSection: some View {
        if !viewModel.dailyPlan.warnings.isEmpty {
            SectionCard(title: "Warnings") {
                ForEach(viewModel.dailyPlan.warnings, id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var energyMessage: String {
        viewModel.dailyPlan.energyScore >= 70 ? "Good day for deep work" : "Use lighter blocks"
    }

    private var calendarAlertBinding: Binding<Bool> {
        Binding(
            get: { calendarMessage != nil },
            set: { if !$0 { calendarMessage = nil } }
        )
    }

    private var focusSummary: String {
        "Focus risk: \(viewModel.dailyPlan.focusRisk.rawValue)"
    }

    private var focusIcon: String {
        switch viewModel.dailyPlan.focusRisk {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        }
    }

    private var focusColor: Color {
        switch viewModel.dailyPlan.focusRisk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func iconName(for category: RecommendationCategory) -> String {
        switch category {
        case .health: return "figure.walk"
        case .focus: return "moon.zzz"
        case .career: return "briefcase"
        case .device: return "iphone"
        }
    }

    private func color(for category: RecommendationCategory) -> Color {
        switch category {
        case .health: return .green
        case .focus: return .indigo
        case .career: return .blue
        case .device: return .secondary
        }
    }

    private func addFocusBlock() {
        guard permissionManager.status(for: .calendar) == .connected else {
            calendarMessage = "Connect Calendar in Settings before adding a focus block."
            return
        }

        Task {
            do {
                let scheduledStart = try await viewModel.addSuggestedFocusBlockToCalendar()
                calendarMessage = "A 90-minute focus block was added for \(scheduledStart.formatted(date: .abbreviated, time: .shortened))."
            } catch {
                calendarMessage = error.localizedDescription
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let footnote: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            Text(footnote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct EnergyRing: View {
    let score: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("energy")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 78, height: 78)
    }

    private var ringColor: Color {
        if score >= 75 { return .green }
        if score >= 55 { return .orange }
        return .red
    }
}

private struct SourcePill: View {
    let iconName: String
    let label: String
    let color: Color

    var body: some View {
        Label(label, systemImage: iconName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }
}

private struct CheckInButton: View {
    let title: String
    let iconName: String
    let isComplete: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: iconName)
                        .foregroundStyle(color)
                    Spacer()
                    if isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

private struct FocusBlockCard: View {
    let label: String
    let title: String
    let detail: String
    let iconName: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct TimelineRow: View {
    let block: ScheduleBlock
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 2, height: 58)
                }
            }
            .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                Text(block.timeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(block.title)
                    .font(.headline)
                Text(block.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
