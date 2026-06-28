import Combine
import Foundation

final class FocusSessionManager: ObservableObject {
    @Published private(set) var remainingSeconds = 0
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var todayCompletedMinutes = 0

    private var timerCancellable: AnyCancellable?
    private var endDate: Date?
    private var sessionMinutes = 0
    private let userDefaults: UserDefaults
    private let calendar: Calendar
    private let completedMinutesKey = "lifeos.focus.completedMinutes"
    private let completedDateKey = "lifeos.focus.completedDate"

    init(
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        loadTodayProgress()
    }

    func start(minutes: Int) {
        sessionMinutes = minutes
        remainingSeconds = minutes * 60
        isPaused = false
        resume()
    }

    func pause() {
        updateRemainingTime()
        timerCancellable?.cancel()
        timerCancellable = nil
        endDate = nil
        isRunning = false
        isPaused = remainingSeconds > 0
    }

    func resume() {
        guard remainingSeconds > 0 else { return }
        endDate = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        isRunning = true
        isPaused = false

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func endSession() {
        timerCancellable?.cancel()
        timerCancellable = nil
        endDate = nil
        remainingSeconds = 0
        sessionMinutes = 0
        isRunning = false
        isPaused = false
    }

    var progress: Double {
        guard sessionMinutes > 0 else { return 0 }
        return 1 - Double(remainingSeconds) / Double(sessionMinutes * 60)
    }

    var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func tick() {
        updateRemainingTime()
        if remainingSeconds == 0 {
            completeSession()
        }
    }

    private func updateRemainingTime() {
        guard let endDate else { return }
        remainingSeconds = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
    }

    private func completeSession() {
        todayCompletedMinutes += sessionMinutes
        userDefaults.set(todayCompletedMinutes, forKey: completedMinutesKey)
        userDefaults.set(calendar.startOfDay(for: Date()), forKey: completedDateKey)
        endSession()
    }

    private func loadTodayProgress() {
        guard let savedDate = userDefaults.object(forKey: completedDateKey) as? Date,
              calendar.isDateInToday(savedDate)
        else {
            todayCompletedMinutes = 0
            return
        }
        todayCompletedMinutes = userDefaults.integer(forKey: completedMinutesKey)
    }
}
