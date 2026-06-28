import FamilyControls
import Foundation
import Combine

@MainActor
final class ScreenTimeAuthorizationManager: ObservableObject {
    @Published private(set) var statusText = "Not Requested"
    @Published private(set) var isAuthorized = false
    @Published private(set) var lastErrorMessage: String?

    init() {
        refreshStatus()
    }

    func requestAuthorization() async {
        lastErrorMessage = nil

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            lastErrorMessage = error.localizedDescription
        }

        refreshStatus()
    }

    func refreshStatus() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved, .approvedWithDataAccess:
            statusText = "Authorized"
            isAuthorized = true
        case .denied:
            statusText = "Denied"
            isAuthorized = false
        case .notDetermined:
            statusText = "Not Requested"
            isAuthorized = false
        @unknown default:
            statusText = "Unavailable"
            isAuthorized = false
        }
    }
}
