import SwiftUI

struct ConnectionsView: View {
    @EnvironmentObject private var permissionManager: ApplePermissionManager

    var body: some View {
        List {
            Section {
                ForEach(AppleConnection.allCases) { connection in
                    AppleConnectionRow(connection: connection)
                }
            } header: {
                Text("Apple Services")
            } footer: {
                Text("LifeOS asks only after you tap Connect. Mock and manual data remain available when a service is disconnected.")
            }

            if let errorMessage = permissionManager.lastErrorMessage {
                Section("Last Connection Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Screen Time Note") {
                Text("Apple restricts DeviceActivity and Screen Time access through the Family Controls entitlement. Focus data remains mocked until that entitlement and user flow are added.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Connections")
        .task {
            await permissionManager.refreshStatuses()
        }
    }
}
