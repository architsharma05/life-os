import Foundation

enum RecommendationCategory: String, Codable, CaseIterable, Identifiable {
    case health = "Health"
    case focus = "Focus"
    case career = "Career"
    case device = "Device"

    var id: String { rawValue }
}

struct Recommendation: Identifiable, Codable, Equatable {
    let id: UUID
    var category: RecommendationCategory
    var title: String
    var detail: String

    init(
        id: UUID = UUID(),
        category: RecommendationCategory,
        title: String,
        detail: String
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
    }
}
