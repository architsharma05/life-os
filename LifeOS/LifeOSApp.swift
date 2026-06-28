import SwiftUI
import SwiftData

@main
struct LifeOSApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: JobApplicationRecord.self)
    }
}

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("lifeos.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var jobStore: JobApplicationStore
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var permissionManager: ApplePermissionManager

    init() {
        let store = JobApplicationStore()
        _jobStore = StateObject(wrappedValue: store)
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(jobStore: store))
        _permissionManager = StateObject(wrappedValue: ApplePermissionManager())
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if hasCompletedOnboarding {
                RootTabView(dashboardViewModel: dashboardViewModel)
                    .environmentObject(jobStore)
                    .environmentObject(permissionManager)
            } else {
                OnboardingView(isComplete: $hasCompletedOnboarding)
                    .environmentObject(permissionManager)
            }
        }
        .onAppear {
            jobStore.configure(modelContext: modelContext)
            dashboardViewModel.refresh()
            print("LifeOS root view appeared")
        }
        .task {
            await permissionManager.refreshStatuses()
            await dashboardViewModel.refreshFromConnectedServices(
                permissionManager: permissionManager
            )
        }
    }
}
