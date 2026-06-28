import SwiftUI

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @EnvironmentObject private var permissionManager: ApplePermissionManager
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LifeOS")
                    .font(.headline)
                Spacer()
                if page < 3 {
                    Button("Skip") {
                        isComplete = true
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding()

            TabView(selection: $page) {
                welcomePage.tag(0)
                privacyPage.tag(1)
                connectionsPage.tag(2)
                readyPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 16) {
                HStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(width: index == page ? 24 : 7, height: 7)
                    }
                }

                Button {
                    if page == 3 {
                        isComplete = true
                    } else {
                        withAnimation { page += 1 }
                    }
                } label: {
                    Text(page == 3 ? "Open LifeOS" : "Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var welcomePage: some View {
        OnboardingPage(
            iconName: "sun.max.fill",
            iconColor: .orange,
            title: "Plan around your real day",
            detail: "LifeOS combines energy, focus, calendar, and career signals into one clear daily plan."
        ) {
            VStack(spacing: 12) {
                OnboardingFeature(icon: "heart.fill", title: "Understand your energy", color: .red)
                OnboardingFeature(icon: "target", title: "Protect your focus", color: .indigo)
                OnboardingFeature(icon: "briefcase.fill", title: "Move your career forward", color: .blue)
            }
        }
    }

    private var privacyPage: some View {
        OnboardingPage(
            iconName: "lock.shield.fill",
            iconColor: .green,
            title: "Private by default",
            detail: "Your plan and job-search data stay on this device. You choose every Apple service LifeOS can access."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                PrivacyPoint(title: "Local-first", detail: "SwiftData keeps your CRM on your device.")
                PrivacyPoint(title: "Permission by permission", detail: "LifeOS never asks for access without context.")
                PrivacyPoint(title: "No paid API required", detail: "Core planning remains useful offline.")
            }
        }
    }

    private var connectionsPage: some View {
        ScrollView {
            OnboardingPage(
                iconName: "link.circle.fill",
                iconColor: .blue,
                title: "Connect what helps",
                detail: "Connect now or continue with mock data. You can change these choices anytime in Settings."
            ) {
                VStack(spacing: 8) {
                    ForEach(AppleConnection.allCases) { connection in
                        AppleConnectionRow(connection: connection)
                        if connection != AppleConnection.allCases.last {
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var readyPage: some View {
        OnboardingPage(
            iconName: "checkmark.circle.fill",
            iconColor: .green,
            title: "Your command center is ready",
            detail: "Start with today's plan. LifeOS will stay useful even when connections are unavailable or turned off."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Review your main priority", systemImage: "1.circle.fill")
                Label("Follow the Now / Next plan", systemImage: "2.circle.fill")
                Label("Adjust mock inputs in Settings", systemImage: "3.circle.fill")
            }
            .font(.headline)
        }
    }
}

private struct OnboardingPage<Content: View>: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let detail: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)
            Image(systemName: iconName)
                .font(.system(size: 46))
                .foregroundStyle(iconColor)
                .frame(width: 88, height: 88)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(spacing: 10) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 12)
        }
        .padding(.horizontal)
    }
}

private struct OnboardingFeature: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        Label {
            Text(title)
                .fontWeight(.medium)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 28)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct PrivacyPoint: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
