import SwiftUI

struct AppleConnectionRow: View {
    let connection: AppleConnection
    @EnvironmentObject private var permissionManager: ApplePermissionManager
    @Environment(\.openURL) private var openURL
    @State private var isRequesting = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: connection.iconName)
                .font(.title3)
                .foregroundStyle(connectionColor)
                .frame(width: 42, height: 42)
                .background(connectionColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(connection.rawValue)
                    .font(.headline)
                Text(connection.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(status.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(statusColor)
            }

            Spacer()

            actionButton
        }
        .padding(.vertical, 5)
    }

    @ViewBuilder
    private var actionButton: some View {
        if isRequesting {
            ProgressView()
                .frame(width: 70)
        } else {
            switch status {
            case .notRequested:
                Button("Connect") {
                    requestAccess()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            case .denied:
                Button("Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            case .connected:
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            case .unavailable, .requiresSetup:
                EmptyView()
            }
        }
    }

    private var status: ConnectionStatus {
        permissionManager.status(for: connection)
    }

    private var connectionColor: Color {
        switch connection {
        case .health: return .red
        case .calendar: return .blue
        case .notifications: return .orange
        case .focus: return .indigo
        }
    }

    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .denied: return .red
        case .requiresSetup: return .indigo
        case .unavailable: return .secondary
        case .notRequested: return .secondary
        }
    }

    private func requestAccess() {
        isRequesting = true
        Task {
            await permissionManager.requestAccess(for: connection)
            isRequesting = false
        }
    }
}
