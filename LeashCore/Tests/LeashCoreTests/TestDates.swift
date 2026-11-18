import Foundation

@testable import LeashCore

func calendar(_ timeZone: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: timeZone)!
    return calendar
}

func day(_ text: String, _ calendar: Calendar) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = text.contains(" ") ? "yyyy-MM-dd HH:mm" : "yyyy-MM-dd"
    return formatter.date(from: text)!
}

func calendarDay(_ text: String) -> CalendarDay {
    let parts = text.split(separator: "-").map { Int($0)! }
    return CalendarDay(year: parts[0], month: parts[1], day: parts[2])
}
