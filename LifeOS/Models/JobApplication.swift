import Foundation

enum JobStatus: String, Codable, CaseIterable, Identifiable {
    case interested = "Interested"
    case applied = "Applied"
    case interviewing = "Interviewing"
    case offer = "Offer"
    case rejected = "Rejected"

    var id: String { rawValue }
}

struct JobApplication: Identifiable, Codable, Equatable {
    let id: UUID
    var company: String
    var role: String
    var status: JobStatus
    var deadline: Date
    var nextAction: String

    init(
        id: UUID = UUID(),
        company: String,
        role: String,
        status: JobStatus,
        deadline: Date,
        nextAction: String
    ) {
        self.id = id
        self.company = company
        self.role = role
        self.status = status
        self.deadline = deadline
        self.nextAction = nextAction
    }
}
