import Foundation

final class MockCalendarManager {
    func fetchTodayEvents() -> [CalendarEvent] {
        let calendar = Calendar.current
        let now = Date()

        func todayAt(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) ?? now
        }

        return [
            CalendarEvent(
                title: "Capgemini Java Developer interview prep",
                startDate: todayAt(hour: 9),
                endDate: todayAt(hour: 10, minute: 30),
                type: .interview
            ),
            CalendarEvent(
                title: "Java OOP review task",
                startDate: todayAt(hour: 11),
                endDate: todayAt(hour: 12),
                type: .study
            ),
            CalendarEvent(
                title: "Truist application follow-up deadline",
                startDate: todayAt(hour: 16),
                endDate: todayAt(hour: 16, minute: 30),
                type: .deadline
            ),
            CalendarEvent(
                title: "Walk/workout reminder",
                startDate: todayAt(hour: 18),
                endDate: todayAt(hour: 18, minute: 45),
                type: .workout
            )
        ]
    }
}
