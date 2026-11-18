import Foundation

/// A day on the calendar, the same in every time zone.
public struct CalendarDay: Codable, Hashable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The first moment of this day in `calendar`.
    public func start(in calendar: Calendar) -> Date {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day))
        return calendar.startOfDay(for: date ?? Date(timeIntervalSince1970: 0))
    }
}
