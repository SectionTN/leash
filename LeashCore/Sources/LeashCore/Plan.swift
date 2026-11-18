import Foundation

/// A data plan: a size that renews every `periodDays` calendar days from `startDay`.
public struct Plan: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let size: Bytes
    public let periodDays: Int
    public let startDay: CalendarDay

    public init(id: UUID = UUID(), name: String, size: Bytes, periodDays: Int, startDay: CalendarDay) {
        self.id = id
        self.name = name
        self.size = size
        self.periodDays = max(1, periodDays)
        self.startDay = startDay
    }

    /// Also guards decoded values, which skip the init.
    private var length: Int { max(1, periodDays) }

    /// The period that holds `date`. Days before the start day belong to the first period.
    public func period(containing date: Date, calendar: Calendar) -> PlanPeriod {
        let first = startDay.start(in: calendar)
        let days = calendar.dateComponents([.day], from: first, to: calendar.startOfDay(for: date)).day ?? 0
        let index = max(0, days / length)
        let start = calendar.date(byAdding: .day, value: index * length, to: first) ?? first
        let end = calendar.date(byAdding: .day, value: length, to: start) ?? start
        return PlanPeriod(start: start, end: end)
    }

    /// Calendar days from `date` to the end of its period, today included.
    public func daysLeft(on date: Date, calendar: Calendar) -> Int {
        let end = period(containing: date, calendar: calendar).end
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: end).day ?? 1
        return max(1, days)
    }

    /// What is left in the period, split evenly over the days left.
    public func dailyAllowance(usedBeforeToday: Bytes, on date: Date, calendar: Calendar) -> Bytes {
        max(0, size - usedBeforeToday) / Bytes(daysLeft(on: date, calendar: calendar))
    }
}

/// A plan period. `end` is exclusive.
public struct PlanPeriod: Equatable, Sendable {
    public let start: Date
    public let end: Date
}
