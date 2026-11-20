import Foundation

/// A data plan: a size that renews every `periodDays` calendar days from `startDay`.
public struct Plan: Codable, Hashable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let size: Bytes
    public let periodDays: Int
    public let startDay: CalendarDay
    public let networks: Set<NetworkID>

    public init(
        id: UUID = UUID(), name: String, size: Bytes, periodDays: Int, startDay: CalendarDay,
        networks: Set<NetworkID> = []
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.periodDays = max(1, periodDays)
        self.startDay = startDay
        self.networks = networks
    }

    /// Goes through the init, so a saved plan without `networks` or with a zero period still decodes to a valid one.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(UUID.self, forKey: .id),
            name: try container.decode(String.self, forKey: .name),
            size: try container.decode(Bytes.self, forKey: .size),
            periodDays: try container.decode(Int.self, forKey: .periodDays),
            startDay: try container.decode(CalendarDay.self, forKey: .startDay),
            networks: try container.decodeIfPresent(Set<NetworkID>.self, forKey: .networks) ?? []
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, size, periodDays, startDay, networks
    }

    public func covers(_ network: NetworkID) -> Bool {
        networks.contains(network)
    }

    /// The period that holds `date`. Days before the start day belong to the first period.
    public func period(containing date: Date, calendar: Calendar) -> PlanPeriod {
        let days = span(containing: date, calendar: calendar)
        return PlanPeriod(start: days.first.start(in: calendar), end: days.end.start(in: calendar))
    }

    /// Calendar days from `date` to the end of its period, today included.
    public func daysLeft(on date: Date, calendar: Calendar) -> Int {
        let fixed = Self.withoutDaylightSaving(calendar)
        let today = CalendarDay(date, calendar: calendar).start(in: fixed)
        let end = span(containing: date, calendar: calendar).end.start(in: fixed)
        return max(1, fixed.dateComponents([.day], from: today, to: end).day ?? 1)
    }

    /// What is left in the period, split evenly over the days left.
    public func dailyAllowance(usedBeforeToday: Bytes, on date: Date, calendar: Calendar) -> Bytes {
        // Both sides are clamped first, so corrupt values can't overflow the subtraction.
        max(0, max(0, size) - max(0, usedBeforeToday)) / Bytes(daysLeft(on: date, calendar: calendar))
    }

    /// The first day of the period that holds `date`, and the day after its last.
    private func span(containing date: Date, calendar: Calendar) -> (first: CalendarDay, end: CalendarDay) {
        let fixed = Self.withoutDaylightSaving(calendar)
        let anchor = startDay.start(in: fixed)
        let today = CalendarDay(date, calendar: calendar).start(in: fixed)
        let index = max(0, (fixed.dateComponents([.day], from: anchor, to: today).day ?? 0) / periodDays)
        let first = fixed.date(byAdding: .day, value: index * periodDays, to: anchor) ?? anchor
        let end = fixed.date(byAdding: .day, value: periodDays, to: first) ?? first
        return (CalendarDay(first, calendar: fixed), CalendarDay(end, calendar: fixed))
    }

    /// The same calendar in GMT, where every day is 24 hours, so a skipped midnight can't shorten one.
    private static func withoutDaylightSaving(_ calendar: Calendar) -> Calendar {
        var fixed = calendar
        fixed.timeZone = .gmt
        return fixed
    }
}

/// A plan period. `end` is exclusive.
public struct PlanPeriod: Equatable, Sendable {
    public let start: Date
    public let end: Date
}
