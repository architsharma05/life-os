import Foundation
import Combine
import SwiftData

final class JobApplicationStore: ObservableObject {
    @Published private(set) var applications: [JobApplication] = []

    private let storageKey = "lifeos.jobApplications"
    private let migrationKey = "lifeos.didMigrateJobsToSwiftData"
    private var modelContext: ModelContext?

    init() {
        applications = Self.seedApplications()
    }

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        migrateUserDefaultsIfNeeded()
        loadFromSwiftData()

        if applications.isEmpty {
            Self.seedApplications().forEach { add($0) }
        }
    }

    func add(_ application: JobApplication) {
        guard let modelContext else {
            applications.appendSorted(application)
            return
        }

        modelContext.insert(JobApplicationRecord(application: application))
        saveContext()
        loadFromSwiftData()
    }

    func update(_ application: JobApplication) {
        guard let modelContext else {
            updateInMemory(application)
            return
        }

        if let record = record(with: application.id) {
            record.update(from: application)
        } else {
            modelContext.insert(JobApplicationRecord(application: application))
        }

        saveContext()
        loadFromSwiftData()
    }

    func delete(at offsets: IndexSet) {
        let idsToDelete = offsets.map { applications[$0].id }

        guard let modelContext else {
            applications.remove(atOffsets: offsets)
            return
        }

        records()
            .filter { idsToDelete.contains($0.id) }
            .forEach { modelContext.delete($0) }

        saveContext()
        loadFromSwiftData()
    }

    func updateStatus(for application: JobApplication, status: JobStatus) {
        var updated = application
        updated.status = status
        update(updated)
    }

    func updateNextAction(for application: JobApplication, nextAction: String) {
        var updated = application
        updated.nextAction = nextAction
        update(updated)
    }

    private func loadFromSwiftData() {
        applications = records()
            .map(\.application)
            .sorted { $0.deadline < $1.deadline }
    }

    private func migrateUserDefaultsIfNeeded() {
        guard
            UserDefaults.standard.bool(forKey: migrationKey) == false,
            let modelContext,
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([JobApplication].self, from: data)
        else { return }

        for application in decoded where record(with: application.id) == nil {
            modelContext.insert(JobApplicationRecord(application: application))
        }

        saveContext()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    private func records() -> [JobApplicationRecord] {
        guard let modelContext else { return [] }
        let descriptor = FetchDescriptor<JobApplicationRecord>(
            sortBy: [SortDescriptor(\.deadline)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func record(with id: UUID) -> JobApplicationRecord? {
        records().first { $0.id == id }
    }

    private func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            print("Failed to save job applications: \(error.localizedDescription)")
        }
    }

    private func updateInMemory(_ application: JobApplication) {
        guard let index = applications.firstIndex(where: { $0.id == application.id }) else { return }
        applications[index] = application
        applications.sort { $0.deadline < $1.deadline }
    }

    static func seedApplications() -> [JobApplication] {
        let calendar = Calendar.current
        let today = Date()

        func daysFromNow(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: today) ?? today
        }

        return [
            JobApplication(
                company: "Capgemini",
                role: "Java Developer",
                status: .interviewing,
                deadline: daysFromNow(1),
                nextAction: "Review Java OOP, collections, and interview stories."
            ),
            JobApplication(
                company: "Truist",
                role: "Java Software Engineer",
                status: .applied,
                deadline: daysFromNow(2),
                nextAction: "Send a short follow-up and revisit role requirements."
            ),
            JobApplication(
                company: "EIMS",
                role: "Tech Sales",
                status: .applied,
                deadline: daysFromNow(4),
                nextAction: "Prepare a concise sales discovery call pitch."
            ),
            JobApplication(
                company: "Garmin",
                role: "Software Engineer",
                status: .interested,
                deadline: daysFromNow(6),
                nextAction: "Tailor resume bullets for embedded and product work."
            )
        ].sorted { $0.deadline < $1.deadline }
    }
}

private extension Array where Element == JobApplication {
    mutating func appendSorted(_ application: JobApplication) {
        append(application)
        sort { $0.deadline < $1.deadline }
    }
}
