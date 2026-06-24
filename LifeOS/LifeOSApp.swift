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
    @StateObject private var jobStore: JobApplicationStore
    @StateObject private var dashboardViewModel: DashboardViewModel

    init() {
        let store = JobApplicationStore()
        _jobStore = StateObject(wrappedValue: store)
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(jobStore: store))
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            RootTabView(dashboardViewModel: dashboardViewModel)
                .environmentObject(jobStore)
        }
        .onAppear {
            jobStore.configure(modelContext: modelContext)
            dashboardViewModel.refresh()
            print("LifeOS root view appeared")
        }
    }
}
