import Foundation
import SwiftData

@Model
final class JobApplicationRecord {
    @Attribute(.unique) var id: UUID
    var company: String
    var role: String
    var statusRawValue: String
    var deadline: Date
    var nextAction: String
    var createdAt: Date
    var updatedAt: Date

    init(application: JobApplication) {
        self.id = application.id
        self.company = application.company
        self.role = application.role
        self.statusRawValue = application.status.rawValue
        self.deadline = application.deadline
        self.nextAction = application.nextAction
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var application: JobApplication {
        JobApplication(
            id: id,
            company: company,
            role: role,
            status: JobStatus(rawValue: statusRawValue) ?? .interested,
            deadline: deadline,
            nextAction: nextAction
        )
    }

    func update(from application: JobApplication) {
        company = application.company
        role = application.role
        statusRawValue = application.status.rawValue
        deadline = application.deadline
        nextAction = application.nextAction
        updatedAt = Date()
    }
}
