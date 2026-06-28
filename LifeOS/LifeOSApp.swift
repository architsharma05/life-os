import SwiftUI
import SwiftData

@main
struct LifeOSApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: JobApplicationRecord.self)
        .backgroundTask(.appRefresh(BackgroundRefreshManager.taskIdentifier)) {
            await BackgroundRefreshManager.shared.performRefresh()
        }
    }
}

private struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("lifeos.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var jobStore: JobApplicationStore
    @StateObject private var checkInStore: DailyCheckInStore
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var permissionManager: ApplePermissionManager
    @StateObject private var focusSessionManager: FocusSessionManager
    @StateObject private var screenTimeManager: ScreenTimeAuthorizationManager

    init() {
        let store = JobApplicationStore()
        let checkInStore = DailyCheckInStore()
        _jobStore = StateObject(wrappedValue: store)
        _checkInStore = StateObject(wrappedValue: checkInStore)
        _dashboardViewModel = StateObject(
            wrappedValue: DashboardViewModel(
                jobStore: store,
                checkInStore: checkInStore
            )
        )
        _permissionManager = StateObject(wrappedValue: ApplePermissionManager())
        _focusSessionManager = StateObject(wrappedValue: FocusSessionManager())
        _screenTimeManager = StateObject(wrappedValue: ScreenTimeAuthorizationManager())
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            if hasCompletedOnboarding {
                RootTabView(dashboardViewModel: dashboardViewModel)
                    .environmentObject(jobStore)
                    .environmentObject(checkInStore)
                    .environmentObject(permissionManager)
                    .environmentObject(focusSessionManager)
                    .environmentObject(screenTimeManager)
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                BackgroundRefreshManager.shared.scheduleNextRefresh()
            }
        }
    }
}
