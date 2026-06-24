import Foundation

enum FocusRisk: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

struct FocusData: Codable, Equatable {
    let screenTimeHours: Double
    let distractingAppUsageMinutes: Int
    let lateNightUsage: Bool
}
