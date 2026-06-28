import Combine
import Foundation

final class DailyCheckInStore: ObservableObject {
    @Published private(set) var today: DailyCheckIn

    private let storageKey = "lifeos.dailyCheckIn"
    private let userDefaults: UserDefaults
    private let calendar: Calendar

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar

        if let data = userDefaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode(DailyCheckIn.self, from: data),
           calendar.isDateInToday(saved.date) {
            today = saved
        } else {
            today = .empty()
        }
    }

    func saveMorningPlan(
        priorities: [String],
        intention: String,
        energy: Int
    ) {
        today.priorities = priorities
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        today.intention = intention.trimmingCharacters(in: .whitespacesAndNewlines)
        today.morningEnergy = energy
        today.morningCompleted = true
        save()
    }

    func saveEveningReview(
        completedPriorityCount: Int,
        energy: Int,
        reflection: String
    ) {
        today.completedPriorityCount = min(
            max(completedPriorityCount, 0),
            max(today.priorities.count, 3)
        )
        today.eveningEnergy = energy
        today.reflection = reflection.trimmingCharacters(in: .whitespacesAndNewlines)
        today.eveningCompleted = true
        save()
    }

    func resetToday() {
        today = .empty()
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(today) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
