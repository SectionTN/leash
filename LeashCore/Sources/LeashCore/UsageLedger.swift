import Foundation

public struct UsageTotals: Equatable, Codable, Sendable {
    public var bytesIn: Bytes
    public var bytesOut: Bytes
    public var total: Bytes { bytesIn.saturatingAdd(bytesOut) }

    public static let zero = UsageTotals(bytesIn: 0, bytesOut: 0)

    public init(bytesIn: Bytes, bytesOut: Bytes) {
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }

    fileprivate mutating func add(_ other: UsageTotals) {
        bytesIn = bytesIn.saturatingAdd(other.bytesIn)
        bytesOut = bytesOut.saturatingAdd(other.bytesOut)
    }
}

public struct AppUsage: Equatable, Sendable {
    public let app: AppKey
    public let totals: UsageTotals
}

/// Bytes summed per app, per plan and per hour.
public struct UsageLedger: Equatable, Codable, Sendable {
    public static let retentionDays = 400

    private var buckets: [Bucket: UsageTotals] = [:]

    public init() {}

    public mutating func record(
        app: AppKey, planID: UUID, bytesIn: Bytes, bytesOut: Bytes, at date: Date, calendar: Calendar
    ) {
        let hourStart = calendar.dateInterval(of: .hour, for: date)?.start ?? date
        let bucket = Bucket(app: app, planID: planID, hourStart: hourStart)
        buckets[bucket, default: .zero].add(UsageTotals(bytesIn: max(0, bytesIn), bytesOut: max(0, bytesOut)))
    }

    /// Sums the hours that start in `[from, to)`, for one app or all of them.
    public func totals(planID: UUID, app: AppKey? = nil, from: Date, to: Date) -> UsageTotals {
        var sum = UsageTotals.zero
        for (bucket, totals) in buckets where bucket.isIn(planID: planID, from: from, to: to) {
            if app == nil || bucket.app == app { sum.add(totals) }
        }
        return sum
    }

    /// Apps by total in `[from, to)`, biggest first.
    public func ranking(planID: UUID, from: Date, to: Date) -> [AppUsage] {
        var perApp: [AppKey: UsageTotals] = [:]
        for (bucket, totals) in buckets where bucket.isIn(planID: planID, from: from, to: to) {
            perApp[bucket.app, default: .zero].add(totals)
        }
        return perApp.map { AppUsage(app: $0.key, totals: $0.value) }.sorted { lhs, rhs in
            if lhs.totals.total != rhs.totals.total { return lhs.totals.total > rhs.totals.total }
            return String(describing: lhs.app) < String(describing: rhs.app)
        }
    }

    /// Drops the hours that start before `date`.
    public mutating func prune(before date: Date) {
        buckets = buckets.filter { $0.key.hourStart >= date }
    }
}

private struct Bucket: Hashable, Codable, Sendable {
    let app: AppKey
    let planID: UUID
    let hourStart: Date

    func isIn(planID: UUID, from: Date, to: Date) -> Bool {
        self.planID == planID && hourStart >= from && hourStart < to
    }
}
