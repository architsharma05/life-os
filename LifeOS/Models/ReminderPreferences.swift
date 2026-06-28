import Foundation

struct ReminderPreferences: Codable, Equatable {
    var focusLeadMinutes: Int = 10
    var quietHoursStart: Int = 22
    var quietHoursEnd: Int = 7
    var eveningReviewHour: Int = 20

    func isInsideQuietHours(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)

        if quietHoursStart == quietHoursEnd {
            return false
        }

        if quietHoursStart < quietHoursEnd {
            return hour >= quietHoursStart && hour < quietHoursEnd
        }

        return hour >= quietHoursStart || hour < quietHoursEnd
    }
}
