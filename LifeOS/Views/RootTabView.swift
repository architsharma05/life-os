import SwiftUI

struct RootTabView: View {
    @ObservedObject var dashboardViewModel: DashboardViewModel

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            FocusCoachView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Focus", systemImage: "target")
                }

            EnergyInsightsView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Energy", systemImage: "heart")
                }

            JobSearchView()
                .tabItem {
                    Label("Jobs", systemImage: "briefcase")
                }

            SettingsView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
